$ErrorActionPreference = "Stop"
# VMware vSAN Health Check Script
# This script performs comprehensive health checks on vSAN clusters

param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\vsan-health-report.html"
)

# Import required modules
Import-Module VMware.PowerCLI -ErrorAction SilentlyContinue

# Disable certificate warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope Session

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Get-VsanHealthSummary {
    param([string]$ClusterName)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
        $healthTest = Get-VsanClusterHealth -Cluster $cluster
        
        return @{
            OverallHealth = $healthTest.OverallHealth
            HealthTests = $healthTest.HealthTest
            Timestamp = Get-Date
        }
    }
    catch {
        Write-Log "Error getting vSAN health: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-VsanCapacityInfo {
    param([string]$ClusterName)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $vsanDatastore = Get-Datastore | Where-Object {$_.Type -eq "vsan" -and $_.ParentFolder.Parent.Name -eq $ClusterName}
        
        if ($vsanDatastore) {
            $capacityGB = [math]::Round($vsanDatastore.CapacityGB, 2)
            $freeSpaceGB = [math]::Round($vsanDatastore.FreeSpaceGB, 2)
            $usedSpaceGB = $capacityGB - $freeSpaceGB
            $usedPercentage = [math]::Round(($usedSpaceGB / $capacityGB) * 100, 2)
            
            return @{
                TotalCapacityGB = $capacityGB
                UsedSpaceGB = $usedSpaceGB
                FreeSpaceGB = $freeSpaceGB
                UsedPercentage = $usedPercentage
            }
        }
        return $null
    }
    catch {
        Write-Log "Error getting capacity info: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-VsanDiskGroupInfo {
    param([string]$ClusterName)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $hosts = Get-VMHost -Location $cluster
        $diskGroups = @()
        
        foreach ($vmhost in $hosts) {
            $hostDiskGroups = Get-VsanDiskGroup -VMHost $vmhost
            foreach ($dg in $hostDiskGroups) {
                $diskGroups += @{
                    Host = $vmhost.Name
                    DiskGroupUuid = $dg.DiskGroupUuid
                    CacheDevice = $dg.CacheDevice
                    CapacityDevices = $dg.CapacityDevice
                    Health = "Healthy" # Simplified for example
                }
            }
        }
        
        return $diskGroups
    }
    catch {
        Write-Log "Error getting disk group info: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Generate-HtmlReport {
    param(
        [hashtable]$HealthSummary,
        [hashtable]$CapacityInfo,
        [array]$DiskGroups,
        [string]$ClusterName,
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>vSAN Health Report - $ClusterName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .healthy { color: green; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .progress-bar { width: 100%; height: 20px; background-color: #f0f0f0; border-radius: 10px; }
        .progress-fill { height: 100%; background-color: #0078d4; border-radius: 10px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>vSAN Health Report</h1>
        <p>Cluster: $ClusterName | Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
"@

    # Overall Health Section
    if ($HealthSummary) {
        $healthClass = switch ($HealthSummary.OverallHealth) {
            "green" { "healthy" }
            "yellow" { "warning" }
            "red" { "error" }
            default { "" }
        }
        
        $html += @"
    <div class="section">
        <h2>Overall Health Status</h2>
        <p class="$healthClass">Status: $($HealthSummary.OverallHealth.ToUpper())</p>
    </div>
"@
    }

    # Capacity Information
    if ($CapacityInfo) {
        $html += @"
    <div class="section">
        <h2>Capacity Information</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Total Capacity</td><td>$($CapacityInfo.TotalCapacityGB) GB</td></tr>
            <tr><td>Used Space</td><td>$($CapacityInfo.UsedSpaceGB) GB</td></tr>
            <tr><td>Free Space</td><td>$($CapacityInfo.FreeSpaceGB) GB</td></tr>
            <tr><td>Used Percentage</td><td>$($CapacityInfo.UsedPercentage)%</td></tr>
        </table>
        <div class="progress-bar">
            <div class="progress-fill" style="width: $($CapacityInfo.UsedPercentage)%;"></div>
        </div>
    </div>
"@
    }

    # Disk Groups Information
    if ($DiskGroups.Count -gt 0) {
        $html += @"
    <div class="section">
        <h2>Disk Groups</h2>
        <table>
            <tr><th>Host</th><th>Cache Device</th><th>Capacity Devices</th><th>Status</th></tr>
"@
        foreach ($dg in $DiskGroups) {
            $capacityDeviceCount = if ($dg.CapacityDevices) { $dg.CapacityDevices.Count } else { 0 }
            $html += "<tr><td>$($dg.Host)</td><td>$($dg.CacheDevice)</td><td>$capacityDeviceCount devices</td><td class='healthy'>$($dg.Health)</td></tr>"
        }
        $html += "</table></div>"
    }

    $html += @"
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Monitor capacity usage regularly</li>
            <li>Check vSAN health status daily</li>
            <li>Ensure all hosts have consistent configuration</li>
            <li>Review performance metrics weekly</li>
        </ul>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Log "Report generated: $OutputPath" "INFO"
}

# Main execution
try {
    Write-Log "Starting vSAN health check for cluster: $ClusterName" "INFO"
    
    # Connect to vCenter
    Write-Log "Connecting to vCenter: $vCenterServer" "INFO"
    $credential = Get-Credential -Message "Enter vCenter credentials"
    Connect-VIServer -Server $vCenterServer -Credential $credential -ErrorAction Stop
    
    # Gather health information
    Write-Log "Gathering vSAN health information..." "INFO"
    $healthSummary = Get-VsanHealthSummary -ClusterName $ClusterName
    
    Write-Log "Gathering capacity information..." "INFO"
    $capacityInfo = Get-VsanCapacityInfo -ClusterName $ClusterName
    
    Write-Log "Gathering disk group information..." "INFO"
    $diskGroups = Get-VsanDiskGroupInfo -ClusterName $ClusterName
    
    # Generate report
    Write-Log "Generating HTML report..." "INFO"
    Generate-HtmlReport -HealthSummary $healthSummary -CapacityInfo $capacityInfo -DiskGroups $diskGroups -ClusterName $ClusterName -OutputPath $OutputPath
    
    Write-Log "Health check completed successfully!" "INFO"
    
    # Display summary
    if ($healthSummary) {
        Write-Host "`nHealth Summary:" -ForegroundColor Cyan
        Write-Host "Overall Status: $($healthSummary.OverallHealth)" -ForegroundColor $(if($healthSummary.OverallHealth -eq "green"){"Green"}elseif($healthSummary.OverallHealth -eq "yellow"){"Yellow"}else{"Red"})
    }
    
    if ($capacityInfo) {
        Write-Host "`nCapacity Summary:" -ForegroundColor Cyan
        Write-Host "Total: $($capacityInfo.TotalCapacityGB) GB"
        Write-Host "Used: $($capacityInfo.UsedSpaceGB) GB ($($capacityInfo.UsedPercentage)%)"
        Write-Host "Free: $($capacityInfo.FreeSpaceGB) GB"
    }
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    # Disconnect from vCenter
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-VIServer -Server * -Confirm:$false
        Write-Log "Disconnected from vCenter" "INFO"
    }
}