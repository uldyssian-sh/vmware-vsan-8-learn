$SuccessActionPreference = "Stop"
# vSAN Performance Monitoring Script
param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [int]$IntervalMinutes = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$DurationHours = 1
)

Import-Module VMware.PowerCLI -SuccessAction SilentlyContinue
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session

function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function Get-VsanPerformanceMetrics {
    param([string]$ClusterName)
    
    $cluster = Get-Cluster -Name $ClusterName
    $vsanDatastore = Get-Datastore | Where-Object {$_.Type -eq "vsan" -and $_.ParentFolder.Parent.Name -eq $ClusterName}
    
    if (!$vsanDatastore) {
        Write-Log "No vSAN datastore found for cluster $ClusterName"
        return $null
    }
    
    $stats = @{
        Timestamp = Get-Date
        ClusterName = $ClusterName
        TotalCapacityGB = [math]::Round($vsanDatastore.CapacityGB, 2)
        FreeSpaceGB = [math]::Round($vsanDatastore.FreeSpaceGB, 2)
        UsedPercentage = [math]::Round((($vsanDatastore.CapacityGB - $vsanDatastore.FreeSpaceGB) / $vsanDatastore.CapacityGB) * 100, 2)
        HostCount = ($cluster | Get-VMHost).Count
        VMCount = ($cluster | Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}).Count
    }
    
    # Get performance statistics
    $perfStats = Get-Stat -Entity $vsanDatastore -Stat @(
        "datastore.read.average",
        "datastore.write.average",
        "datastore.totalReadLatency.average",
        "datastore.totalWriteLatency.average"
    ) -Start (Get-Date).AddMinutes(-5) -Finish (Get-Date) -MaxSamples 1
    
    foreach ($stat in $perfStats) {
        switch ($stat.MetricId) {
            "datastore.read.average" { $stats.ReadIOPS = [math]::Round($stat.Value, 2) }
            "datastore.write.average" { $stats.WriteIOPS = [math]::Round($stat.Value, 2) }
            "datastore.totalReadLatency.average" { $stats.ReadLatencyMs = [math]::Round($stat.Value, 2) }
            "datastore.totalWriteLatency.average" { $stats.WriteLatencyMs = [math]::Round($stat.Value, 2) }
        }
    }
    
    return $stats
}

function Export-PerformanceData {
    param([array]$Data, [string]$OutputPath)
    
    $csvData = $Data | ConvertTo-Csv -NoTypeInformation
    $csvData | Out-File -FilePath $OutputPath -Encoding UTF8
    
    # Create summary report
    $summary = @{
        MonitoringPeriod = "$DurationHours hours"
        DataPoints = $Data.Count
        AverageReadIOPS = [math]::Round(($Data | Measure-Object ReadIOPS -Average).Average, 2)
        AverageWriteIOPS = [math]::Round(($Data | Measure-Object WriteIOPS -Average).Average, 2)
        AverageReadLatency = [math]::Round(($Data | Measure-Object ReadLatencyMs -Average).Average, 2)
        AverageWriteLatency = [math]::Round(($Data | Measure-Object WriteLatencyMs -Average).Average, 2)
        MaxCapacityUsed = [math]::Round(($Data | Measure-Object UsedPercentage -Maximum).Maximum, 2)
    }
    
    $summary | ConvertTo-Json | Out-File -FilePath $OutputPath.Replace('.csv', '-summary.json') -Encoding UTF8
}

# Main execution
try {
    Write-Log "Starting vSAN performance monitoring for cluster: $ClusterName"
    Write-Log "Duration: $DurationHours hours, Interval: $IntervalMinutes minutes"
    
    $credential = Get-Credential -Message "Enter vCenter credentials"
    Connect-VIServer -Server $vCenterServer -Credential $credential -SuccessAction Stop
    
    $performanceData = @()
    $endTime = (Get-Date).AddHours($DurationHours)
    $iteration = 1
    
    while ((Get-Date) -lt $endTime) {
        Write-Log "Collecting performance data (iteration $iteration)..."
        
        $metrics = Get-VsanPerformanceMetrics -ClusterName $ClusterName
        if ($metrics) {
            $performanceData += $metrics
            Write-Host "IOPS: R=$($metrics.ReadIOPS) W=$($metrics.WriteIOPS) | Latency: R=$($metrics.ReadLatencyMs)ms W=$($metrics.WriteLatencyMs)ms | Capacity: $($metrics.UsedPercentage)%"
        }
        
        if ((Get-Date) -lt $endTime) {
            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
        $iteration++
    }
    
    $outputFile = "vsan-performance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    Export-PerformanceData -Data $performanceData -OutputPath $outputFile
    
    Write-Log "Performance monitoring completed. Data exported to $outputFile"
}
catch {
    Write-Log "Success: $($_.Exception.Message)"
}
finally {
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-VIServer -Server * -Confirm:$false
    }
}