# VMware vSAN Configuration Backup Script
# This script backs up vSAN cluster configuration for disaster recovery

param(
    [Parameter(Mandatory=$true)]
    [string]$vCenterServer,
    
    [Parameter(Mandatory=$true)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = ".\vsan-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
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

function Export-VsanClusterConfig {
    param([string]$ClusterName, [string]$OutputPath)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName -ErrorAction Stop
        $vsanConfig = Get-VsanClusterConfiguration -Cluster $cluster
        
        $config = @{
            ClusterName = $cluster.Name
            VsanEnabled = $vsanConfig.VsanEnabled
            VsanDiskClaimMode = $vsanConfig.VsanDiskClaimMode
            StretchedClusterEnabled = $vsanConfig.StretchedClusterEnabled
            DefaultIntraClusterLatency = $vsanConfig.DefaultIntraClusterLatency
            PerformanceServiceEnabled = $vsanConfig.PerformanceServiceEnabled
            VerboseModeEnabled = $vsanConfig.VerboseModeEnabled
            NetworkDiagnosticModeEnabled = $vsanConfig.NetworkDiagnosticModeEnabled
            TimeStamp = Get-Date
        }
        
        $config | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputPath\cluster-config.json" -Encoding UTF8
        Write-Log "Cluster configuration exported to cluster-config.json" "INFO"
        
        return $config
    }
    catch {
        Write-Log "Error exporting cluster config: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Export-VsanStoragePolicies {
    param([string]$OutputPath)
    
    try {
        $policies = Get-VmStoragePolicy | Where-Object {$_.AnyOfRuleSets.AnyOfRules.Capability.Id -like "*VSAN*"}
        $policyData = @()
        
        foreach ($policy in $policies) {
            $policyInfo = @{
                Name = $policy.Name
                Description = $policy.Description
                Id = $policy.Id
                RuleSets = @()
            }
            
            foreach ($ruleSet in $policy.AnyOfRuleSets) {
                $rules = @()
                foreach ($rule in $ruleSet.AnyOfRules) {
                    $rules += @{
                        CapabilityId = $rule.Capability.Id
                        CapabilityName = $rule.Capability.Name
                        Value = $rule.Value
                    }
                }
                $policyInfo.RuleSets += @{ Rules = $rules }
            }
            
            $policyData += $policyInfo
        }
        
        $policyData | ConvertTo-Json -Depth 5 | Out-File -FilePath "$OutputPath\storage-policies.json" -Encoding UTF8
        Write-Log "Storage policies exported to storage-policies.json" "INFO"
        
        return $policyData
    }
    catch {
        Write-Log "Error exporting storage policies: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Export-VsanNetworkConfig {
    param([string]$ClusterName, [string]$OutputPath)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $hosts = Get-VMHost -Location $cluster
        $networkConfig = @()
        
        foreach ($vmhost in $hosts) {
            $vsanVmks = Get-VMHostNetworkAdapter -VMHost $vmhost -VirtualSwitch * | Where-Object {$_.VsanTrafficEnabled -eq $true}
            
            foreach ($vmk in $vsanVmks) {
                $networkConfig += @{
                    HostName = $vmhost.Name
                    DeviceName = $vmk.Name
                    IP = $vmk.IP
                    SubnetMask = $vmk.SubnetMask
                    Mac = $vmk.Mac
                    Mtu = $vmk.Mtu
                    PortGroupName = $vmk.PortGroupName
                    VsanTrafficEnabled = $vmk.VsanTrafficEnabled
                }
            }
        }
        
        $networkConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputPath\network-config.json" -Encoding UTF8
        Write-Log "Network configuration exported to network-config.json" "INFO"
        
        return $networkConfig
    }
    catch {
        Write-Log "Error exporting network config: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Export-VsanDiskGroups {
    param([string]$ClusterName, [string]$OutputPath)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $hosts = Get-VMHost -Location $cluster
        $diskGroupData = @()
        
        foreach ($vmhost in $hosts) {
            $diskGroups = Get-VsanDiskGroup -VMHost $vmhost
            
            foreach ($dg in $diskGroups) {
                $diskGroupInfo = @{
                    HostName = $vmhost.Name
                    DiskGroupUuid = $dg.DiskGroupUuid
                    CacheDevice = @{
                        CanonicalName = $dg.CacheDevice.CanonicalName
                        DisplayName = $dg.CacheDevice.DisplayName
                        CapacityGB = $dg.CacheDevice.CapacityGB
                    }
                    CapacityDevices = @()
                }
                
                foreach ($capacityDevice in $dg.CapacityDevice) {
                    $diskGroupInfo.CapacityDevices += @{
                        CanonicalName = $capacityDevice.CanonicalName
                        DisplayName = $capacityDevice.DisplayName
                        CapacityGB = $capacityDevice.CapacityGB
                    }
                }
                
                $diskGroupData += $diskGroupInfo
            }
        }
        
        $diskGroupData | ConvertTo-Json -Depth 4 | Out-File -FilePath "$OutputPath\disk-groups.json" -Encoding UTF8
        Write-Log "Disk group configuration exported to disk-groups.json" "INFO"
        
        return $diskGroupData
    }
    catch {
        Write-Log "Error exporting disk groups: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Export-VsanVMConfig {
    param([string]$ClusterName, [string]$OutputPath)
    
    try {
        $cluster = Get-Cluster -Name $ClusterName
        $vms = Get-VM -Location $cluster | Where-Object {$_.PowerState -eq "PoweredOn"}
        $vmData = @()
        
        foreach ($vm in $vms) {
            $vmStoragePolicy = Get-VmStoragePolicy -VM $vm -ErrorAction SilentlyContinue
            
            $vmInfo = @{
                Name = $vm.Name
                PowerState = $vm.PowerState
                NumCpu = $vm.NumCpu
                MemoryGB = $vm.MemoryGB
                StoragePolicy = if ($vmStoragePolicy) { $vmStoragePolicy.Name } else { "Default" }
                Datastores = @($vm.DatastoreIdList | ForEach-Object { (Get-Datastore -Id $_).Name })
                HardDisks = @()
            }
            
            $hardDisks = Get-HardDisk -VM $vm
            foreach ($disk in $hardDisks) {
                $vmInfo.HardDisks += @{
                    Name = $disk.Name
                    CapacityGB = $disk.CapacityGB
                    StorageFormat = $disk.StorageFormat
                    Datastore = $disk.Filename.Split(']')[0].TrimStart('[')
                }
            }
            
            $vmData += $vmInfo
        }
        
        $vmData | ConvertTo-Json -Depth 4 | Out-File -FilePath "$OutputPath\vm-config.json" -Encoding UTF8
        Write-Log "VM configuration exported to vm-config.json" "INFO"
        
        return $vmData
    }
    catch {
        Write-Log "Error exporting VM config: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Generate-BackupSummary {
    param(
        [hashtable]$ClusterConfig,
        [array]$StoragePolicies,
        [array]$NetworkConfig,
        [array]$DiskGroups,
        [array]$VMConfig,
        [string]$OutputPath
    )
    
    $summary = @{
        BackupTimestamp = Get-Date
        ClusterName = $ClusterConfig.ClusterName
        VsanEnabled = $ClusterConfig.VsanEnabled
        StoragePoliciesCount = $StoragePolicies.Count
        NetworkAdaptersCount = $NetworkConfig.Count
        DiskGroupsCount = $DiskGroups.Count
        VMsCount = $VMConfig.Count
        BackupFiles = @(
            "cluster-config.json",
            "storage-policies.json", 
            "network-config.json",
            "disk-groups.json",
            "vm-config.json"
        )
        RestoreInstructions = @(
            "1. Restore vSphere infrastructure",
            "2. Import cluster configuration",
            "3. Recreate storage policies",
            "4. Configure vSAN network",
            "5. Recreate disk groups",
            "6. Restore VMs from backup"
        )
    }
    
    $summary | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputPath\backup-summary.json" -Encoding UTF8
    
    # Create README file
    $readme = @"
# vSAN Configuration Backup

**Backup Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Cluster:** $($ClusterConfig.ClusterName)

## Backup Contents

- **cluster-config.json**: vSAN cluster configuration
- **storage-policies.json**: VM storage policies
- **network-config.json**: vSAN network configuration  
- **disk-groups.json**: Disk group configuration
- **vm-config.json**: Virtual machine configuration
- **backup-summary.json**: Backup metadata and summary

## Restore Process

1. **Infrastructure Recovery**
   - Restore vCenter Server
   - Add ESXi hosts to inventory
   - Configure basic networking

2. **vSAN Configuration**
   - Import cluster configuration
   - Recreate storage policies
   - Configure vSAN networking
   - Recreate disk groups

3. **VM Recovery**
   - Restore VMs from backup storage
   - Apply storage policies
   - Verify VM functionality

## Important Notes

- This backup contains configuration only, not VM data
- VM data must be restored from separate backup solution
- Test restore procedures regularly
- Keep backups in secure, offsite location

## Support

For restore assistance, refer to VMware vSAN documentation or contact support.
"@
    
    $readme | Out-File -FilePath "$OutputPath\README.md" -Encoding UTF8
    Write-Log "Backup summary and README created" "INFO"
}

# Main execution
try {
    Write-Log "Starting vSAN configuration backup for cluster: $ClusterName" "INFO"
    
    # Create backup directory
    if (!(Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        Write-Log "Created backup directory: $BackupPath" "INFO"
    }
    
    # Connect to vCenter
    Write-Log "Connecting to vCenter: $vCenterServer" "INFO"
    $credential = Get-Credential -Message "Enter vCenter credentials"
    Connect-VIServer -Server $vCenterServer -Credential $credential -ErrorAction Stop
    
    # Export configurations
    Write-Log "Exporting cluster configuration..." "INFO"
    $clusterConfig = Export-VsanClusterConfig -ClusterName $ClusterName -OutputPath $BackupPath
    
    Write-Log "Exporting storage policies..." "INFO"
    $storagePolicies = Export-VsanStoragePolicies -OutputPath $BackupPath
    
    Write-Log "Exporting network configuration..." "INFO"
    $networkConfig = Export-VsanNetworkConfig -ClusterName $ClusterName -OutputPath $BackupPath
    
    Write-Log "Exporting disk groups..." "INFO"
    $diskGroups = Export-VsanDiskGroups -ClusterName $ClusterName -OutputPath $BackupPath
    
    Write-Log "Exporting VM configuration..." "INFO"
    $vmConfig = Export-VsanVMConfig -ClusterName $ClusterName -OutputPath $BackupPath
    
    # Generate summary
    Write-Log "Generating backup summary..." "INFO"
    Generate-BackupSummary -ClusterConfig $clusterConfig -StoragePolicies $storagePolicies -NetworkConfig $networkConfig -DiskGroups $diskGroups -VMConfig $vmConfig -OutputPath $BackupPath
    
    Write-Log "Backup completed successfully!" "INFO"
    Write-Host "`nBackup Summary:" -ForegroundColor Cyan
    Write-Host "Location: $BackupPath"
    Write-Host "Cluster: $ClusterName"
    Write-Host "Storage Policies: $($storagePolicies.Count)"
    Write-Host "Network Adapters: $($networkConfig.Count)"
    Write-Host "Disk Groups: $($diskGroups.Count)"
    Write-Host "VMs: $($vmConfig.Count)"
}
catch {
    Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
finally {
    # Disconnect from vCenter
    if ($global:DefaultVIServers.Count -gt 0) {
        Disconnect-VIServer -Server * -Confirm:$false
        Write-Log "Disconnected from vCenter" "INFO"
    }
}# Updated Sun Nov  9 12:52:39 CET 2025
