# vSAN Capacity Planning and Forecasting Script
param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [int]$ForecastMonths = 12,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\vsan-capacity-report.html"
)

Import-Module VMware.PowerCLI -ErrorAction SilentlyContinue
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-VsanCapacityData {
    param([string]$ClusterName)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $vsanDatastore = Get-Datastore | Where-Object {$_.Type -eq "vsan" -and $_.ParentFolder.Parent.Name -eq $ClusterName}
        
        if (!$vsanDatastore) {
            throw "No vSAN datastore found for cluster $ClusterName"
        }
        
        # Get current capacity information
        $capacityData = @{
            ClusterName = $ClusterName
            Timestamp = Get-Date
            TotalCapacityTB = [math]::Round($vsanDatastore.CapacityGB / 1024, 2)
            UsedCapacityTB = [math]::Round(($vsanDatastore.CapacityGB - $vsanDatastore.FreeSpaceGB) / 1024, 2)
            FreeCapacityTB = [math]::Round($vsanDatastore.FreeSpaceGB / 1024, 2)
            UsedPercentage = [math]::Round((($vsanDatastore.CapacityGB - $vsanDatastore.FreeSpaceGB) / $vsanDatastore.CapacityGB) * 100, 2)
        }
        
        # Get vSAN space usage details
        $vsanSpaceUsage = Get-VsanSpaceUsage -Cluster $cluster
        if ($vsanSpaceUsage) {
            $capacityData.DedupeRatio = [math]::Round($vsanSpaceUsage.DedupeRatio, 2)
            $capacityData.CompressionRatio = [math]::Round($vsanSpaceUsage.CompressionRatio, 2)
            $capacityData.TotalSavingsRatio = [math]::Round($vsanSpaceUsage.DedupeRatio * $vsanSpaceUsage.CompressionRatio, 2)
        }
        
        # Get VM count and average sizes
        $vms = Get-VM -Location $cluster | Where-Object {$_.PowerState -eq "PoweredOn"}
        $capacityData.VMCount = $vms.Count
        $capacityData.AverageVMSizeGB = if ($vms.Count -gt 0) { 
            [math]::Round(($vms | Measure-Object -Property UsedSpaceGB -Sum).Sum / $vms.Count, 2) 
        } else { 0 }
        
        # Get host information
        $hosts = Get-VMHost -Location $cluster
        $capacityData.HostCount = $hosts.Count
        
        return $capacityData
    }
    catch {
        Write-Log "Error getting capacity data: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-HistoricalGrowthRate {
    param([string]$ClusterName, [int]$DaysBack = 90)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $vsanDatastore = Get-Datastore | Where-Object {$_.Type -eq "vsan" -and $_.ParentFolder.Parent.Name -eq $ClusterName}
        
        # Get historical capacity statistics
        $startDate = (Get-Date).AddDays(-$DaysBack)
        $capacityStats = Get-Stat -Entity $vsanDatastore -Stat "datastore.capacity.usage.average" -Start $startDate -IntervalMins 1440
        
        if ($capacityStats.Count -lt 2) {
            Write-Log "Insufficient historical data for growth calculation" "WARNING"
            return 0
        }
        
        # Calculate growth rate
        $oldestStat = $capacityStats | Sort-Object Timestamp | Select-Object -First 1
        $newestStat = $capacityStats | Sort-Object Timestamp | Select-Object -Last 1
        
        $daysDiff = ($newestStat.Timestamp - $oldestStat.Timestamp).Days
        $capacityDiff = $newestStat.Value - $oldestStat.Value
        
        if ($daysDiff -gt 0 -and $oldestStat.Value -gt 0) {
            $dailyGrowthRate = $capacityDiff / $oldestStat.Value / $daysDiff
            $monthlyGrowthRate = $dailyGrowthRate * 30
            return [math]::Round($monthlyGrowthRate * 100, 2)  # Return as percentage
        }
        
        return 0
    }
    catch {
        Write-Log "Error calculating growth rate: $($_.Exception.Message)" "WARNING"
        return 0
    }
}

function New-CapacityForecast {
    param(
        [hashtable]$CurrentData,
        [double]$GrowthRatePercent,
        [int]$ForecastMonths
    )
    
    $forecast = @()
    $currentCapacity = $CurrentData.UsedCapacityTB
    
    for ($month = 1; $month -le $ForecastMonths; $month++) {
        $projectedCapacity = $currentCapacity * [math]::Pow((1 + $GrowthRatePercent / 100), $month)
        $projectedPercentage = ($projectedCapacity / $CurrentData.TotalCapacityTB) * 100
        
        $forecast += @{
            Month = $month
            Date = (Get-Date).AddMonths($month).ToString("yyyy-MM")
            ProjectedUsedTB = [math]::Round($projectedCapacity, 2)
            ProjectedUsedPercentage = [math]::Round($projectedPercentage, 2)
            CapacityStatus = if ($projectedPercentage -gt 90) { "Critical" } 
                            elseif ($projectedPercentage -gt 80) { "Warning" } 
                            else { "OK" }
        }
    }
    
    return $forecast
}

function Get-ExpansionRecommendations {
    param(
        [hashtable]$CurrentData,
        [array]$Forecast
    )
    
    $recommendations = @()
    
    # Find when capacity will reach 80% and 90%
    $warningMonth = ($Forecast | Where-Object {$_.ProjectedUsedPercentage -gt 80} | Select-Object -First 1)?.Month
    $criticalMonth = ($Forecast | Where-Object {$_.ProjectedUsedPercentage -gt 90} | Select-Object -First 1)?.Month
    
    if ($warningMonth) {
        $recommendations += @{
            Priority = "Medium"
            Timeline = "Month $warningMonth"
            Action = "Plan capacity expansion"
            Details = "Capacity will reach 80% utilization"
        }
    }
    
    if ($criticalMonth) {
        $recommendations += @{
            Priority = "High"
            Timeline = "Month $criticalMonth"
            Action = "Execute capacity expansion"
            Details = "Capacity will reach 90% utilization"
        }
    }
    
    # Calculate expansion options
    $currentHosts = $CurrentData.HostCount
    $avgCapacityPerHost = $CurrentData.TotalCapacityTB / $currentHosts
    
    $expansionOptions = @(
        @{
            Option = "Add 1 Host"
            AdditionalCapacityTB = [math]::Round($avgCapacityPerHost, 2)
            NewTotalCapacityTB = [math]::Round($CurrentData.TotalCapacityTB + $avgCapacityPerHost, 2)
            ExtendedMonths = [math]::Floor(($avgCapacityPerHost / $CurrentData.UsedCapacityTB) * 12)
        },
        @{
            Option = "Add 2 Hosts"
            AdditionalCapacityTB = [math]::Round($avgCapacityPerHost * 2, 2)
            NewTotalCapacityTB = [math]::Round($CurrentData.TotalCapacityTB + ($avgCapacityPerHost * 2), 2)
            ExtendedMonths = [math]::Floor(($avgCapacityPerHost * 2 / $CurrentData.UsedCapacityTB) * 12)
        }
    )
    
    return @{
        Recommendations = $recommendations
        ExpansionOptions = $expansionOptions
    }
}

function Generate-CapacityReport {
    param(
        [hashtable]$CapacityData,
        [double]$GrowthRate,
        [array]$Forecast,
        [hashtable]$Recommendations,
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>vSAN Capacity Planning Report - $($CapacityData.ClusterName)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background-color: #f8f9fa; border-radius: 5px; min-width: 150px; }
        .warning { background-color: #fff3cd; border-color: #ffeaa7; }
        .critical { background-color: #f8d7da; border-color: #f5c6cb; }
        .ok { background-color: #d4edda; border-color: #c3e6cb; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .chart { width: 100%; height: 300px; background-color: #f8f9fa; border: 1px solid #ddd; margin: 10px 0; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="header">
        <h1>vSAN Capacity Planning Report</h1>
        <p>Cluster: $($CapacityData.ClusterName) | Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="section">
        <h2>Current Capacity Status</h2>
        <div class="metric">
            <strong>Total Capacity</strong><br>
            $($CapacityData.TotalCapacityTB) TB
        </div>
        <div class="metric">
            <strong>Used Capacity</strong><br>
            $($CapacityData.UsedCapacityTB) TB ($($CapacityData.UsedPercentage)%)
        </div>
        <div class="metric">
            <strong>Free Capacity</strong><br>
            $($CapacityData.FreeCapacityTB) TB
        </div>
        <div class="metric">
            <strong>VM Count</strong><br>
            $($CapacityData.VMCount) VMs
        </div>
        <div class="metric">
            <strong>Host Count</strong><br>
            $($CapacityData.HostCount) Hosts
        </div>
        <div class="metric">
            <strong>Growth Rate</strong><br>
            $GrowthRate% per month
        </div>
    </div>

    <div class="section">
        <h2>Capacity Forecast ($ForecastMonths Months)</h2>
        <table>
            <tr><th>Month</th><th>Date</th><th>Projected Used (TB)</th><th>Projected Used (%)</th><th>Status</th></tr>
"@

    foreach ($item in $Forecast) {
        $statusClass = switch ($item.CapacityStatus) {
            "Critical" { "critical" }
            "Warning" { "warning" }
            default { "ok" }
        }
        $html += "<tr class='$statusClass'><td>$($item.Month)</td><td>$($item.Date)</td><td>$($item.ProjectedUsedTB)</td><td>$($item.ProjectedUsedPercentage)%</td><td>$($item.CapacityStatus)</td></tr>"
    }

    $html += @"
        </table>
        <canvas id="forecastChart" class="chart"></canvas>
    </div>

    <div class="section">
        <h2>Recommendations</h2>
"@

    if ($Recommendations.Recommendations.Count -gt 0) {
        $html += "<table><tr><th>Priority</th><th>Timeline</th><th>Action</th><th>Details</th></tr>"
        foreach ($rec in $Recommendations.Recommendations) {
            $html += "<tr><td>$($rec.Priority)</td><td>$($rec.Timeline)</td><td>$($rec.Action)</td><td>$($rec.Details)</td></tr>"
        }
        $html += "</table>"
    } else {
        $html += "<p>No immediate capacity concerns identified.</p>"
    }

    $html += @"
    </div>

    <div class="section">
        <h2>Expansion Options</h2>
        <table>
            <tr><th>Option</th><th>Additional Capacity (TB)</th><th>New Total (TB)</th><th>Extended Timeline (Months)</th></tr>
"@

    foreach ($option in $Recommendations.ExpansionOptions) {
        $html += "<tr><td>$($option.Option)</td><td>$($option.AdditionalCapacityTB)</td><td>$($option.NewTotalCapacityTB)</td><td>$($option.ExtendedMonths)</td></tr>"
    }

    $html += @"
        </table>
    </div>

    <script>
        // Create forecast chart
        const ctx = document.getElementById('forecastChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$($Forecast | ForEach-Object {"'$($_.Date)'"} | Join-String -Separator ",")],
                datasets: [{
                    label: 'Projected Capacity Usage (%)',
                    data: [$($Forecast | ForEach-Object {$_.ProjectedUsedPercentage} | Join-String -Separator ",")],
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        title: {
                            display: true,
                            text: 'Capacity Usage (%)'
                        }
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Capacity Usage Forecast'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "Capacity report generated: $OutputPath" "INFO"
}

# Main execution
try {
    Write-Log "Starting vSAN capacity planning for cluster: $ClusterName" "INFO"
    
    # Connect to vCenter
    $credential = Get-Credential -Message "Enter vCenter credentials"
    Connect-VIServer -Server $vCenterServer -Credential $credential -ErrorAction Stop
    
    # Gather current capacity data
    Write-Log "Gathering current capacity data..." "INFO"
    $capacityData = Get-VsanCapacityData -ClusterName $ClusterName
    
    if (!$capacityData) {
        throw "Failed to retrieve capacity data"
    }
    
    # Calculate growth rate
    Write-Log "Calculating historical growth rate..." "INFO"
    $growthRate = Get-HistoricalGrowthRate -ClusterName $ClusterName
    
    # Generate forecast
    Write-Log "Generating capacity forecast..." "INFO"
    $forecast = New-CapacityForecast -CurrentData $capacityData -GrowthRatePercent $growthRate -ForecastMonths $ForecastMonths
    
    # Get recommendations
    Write-Log "Analyzing expansion requirements..." "INFO"
    $recommendations = Get-ExpansionRecommendations -CurrentData $capacityData -Forecast $forecast
    
    # Generate report
    Write-Log "Generating capacity planning report..." "INFO"
    Generate-CapacityReport -CapacityData $capacityData -GrowthRate $growthRate -Forecast $forecast -Recommendations $recommendations -OutputPath $OutputPath
    
    # Display summary
    Write-Host "`nCapacity Planning Summary:" -ForegroundColor Cyan
    Write-Host "Current Usage: $($capacityData.UsedCapacityTB) TB ($($capacityData.UsedPercentage)%)"
    Write-Host "Growth Rate: $growthRate% per month"
    
    $warningMonth = ($forecast | Where-Object {$_.ProjectedUsedPercentage -gt 80} | Select-Object -First 1)?.Month
    if ($warningMonth) {
        Write-Host "Capacity Warning: Month $warningMonth" -ForegroundColor Yellow
    }
    
    Write-Log "Capacity planning completed successfully!" "INFO"
}
catch {
    Write-Log "Capacity planning failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-VIServer -Server * -Confirm:$false
    }
}# Updated Sun Nov  9 12:52:39 CET 2025
# Updated Sun Nov  9 12:56:07 CET 2025
