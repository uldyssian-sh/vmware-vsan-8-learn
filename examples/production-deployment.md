# Production vSAN Deployment Example

This example demonstrates a complete production vSAN deployment for a mid-size enterprise.

## Deployment Overview

### Business Requirements
- **Workloads**: 200 VMs (mixed database, web, and application servers)
- **Performance**: 50,000 IOPS, <2ms latency
- **Availability**: 99.9% uptime, site-level protection
- **Capacity**: 50TB usable storage with 30% growth buffer
- **Security**: Encryption at rest, compliance requirements

### Infrastructure Design

#### Hardware Configuration
```json
{
  "cluster": {
    "name": "PROD-vSAN-Cluster",
    "sites": 2,
    "hostsPerSite": 4,
    "totalHosts": 8
  },
  "hostSpecs": {
    "cpu": "2x Intel Xeon Gold 6248R (48 cores total)",
    "memory": "512GB DDR4",
    "network": "4x 25GbE adapters",
    "storage": {
      "cacheDevices": "2x 1.6TB NVMe SSD",
      "capacityDevices": "6x 7.68TB SSD"
    }
  }
}
```

## Phase 1: Infrastructure Preparation

### Network Configuration

```powershell
# Configure vSAN network on all hosts
$vsanHosts = @(
    @{Name="esxi-prod-01.company.com"; VsanIP="10.10.100.11"},
    @{Name="esxi-prod-02.company.com"; VsanIP="10.10.100.12"},
    @{Name="esxi-prod-03.company.com"; VsanIP="10.10.100.13"},
    @{Name="esxi-prod-04.company.com"; VsanIP="10.10.100.14"},
    @{Name="esxi-prod-05.company.com"; VsanIP="10.10.100.15"},
    @{Name="esxi-prod-06.company.com"; VsanIP="10.10.100.16"},
    @{Name="esxi-prod-07.company.com"; VsanIP="10.10.100.17"},
    @{Name="esxi-prod-08.company.com"; VsanIP="10.10.100.18"}
)

foreach ($hostInfo in $vsanHosts) {
    $vmhost = Get-VMHost $hostInfo.Name

    # Create vSAN VMkernel port
    New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup "vSAN-Production" -IP $hostInfo.VsanIP -SubnetMask "255.255.255.0" -Mtu 9000 -VsanTrafficEnabled:$true

    Write-Host "Configured vSAN network for $($hostInfo.Name)"
}
```

### Storage Preparation

```powershell
# Verify storage devices on all hosts
function Test-StorageReadiness {
    param([array]$HostNames)

    foreach ($hostName in $HostNames) {
        $vmhost = Get-VMHost $hostName
        $storageDevices = Get-VMHostDisk -VMHost $vmhost

        $ssdDevices = $storageDevices | Where-Object {$_.ScsiLun.IsSsd -eq $true}
        $hddDevices = $storageDevices | Where-Object {$_.ScsiLun.IsSsd -eq $false}

        Write-Host "Host: $hostName"
        Write-Host "  SSD Devices: $($ssdDevices.Count)"
        Write-Host "  HDD Devices: $($hddDevices.Count)"

        # Verify minimum requirements
        if ($ssdDevices.Count -lt 2) {
            Write-Warning "Host $hostName has insufficient SSD devices for production"
        }
    }
}

$hostNames = $vsanHosts | ForEach-Object {$_.Name}
Test-StorageReadiness -HostNames $hostNames
```

## Phase 2: vSAN Cluster Deployment

### Cluster Creation

```powershell
# Create production vSAN cluster
$datacenter = Get-Datacenter "Production-DC"
$cluster = New-Cluster -Name "PROD-vSAN-Cluster" -Location $datacenter

# Configure vSAN with production settings
$vsanSpec = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpec
$vsanSpec.Enabled = $true
$vsanSpec.DefaultConfig = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpecDefaultConfig
$vsanSpec.DefaultConfig.AutoClaimStorage = $false  # Manual disk group creation
$vsanSpec.DefaultConfig.CompressionEnabled = $true
$vsanSpec.DefaultConfig.DedupEnabled = $true
$vsanSpec.DefaultConfig.EncryptionEnabled = $true

Set-VsanClusterConfiguration -Cluster $cluster -VsanClusterConfigSpec $vsanSpec
```

### Disk Group Configuration

```powershell
# Create optimized disk groups
function New-ProductionDiskGroups {
    param([string]$ClusterName)

    $cluster = Get-Cluster $ClusterName
    $hosts = Get-VMHost -Location $cluster

    foreach ($vmhost in $hosts) {
        $availableDisks = Get-VsanDisk -VMHost $vmhost | Where-Object {$_.VsanDiskGroupUuid -eq $null}

        # Separate cache and capacity devices
        $cacheDisks = $availableDisks | Where-Object {$_.IsSsd -eq $true -and $_.CapacityGB -lt 2000}
        $capacityDisks = $availableDisks | Where-Object {$_.CapacityGB -gt 2000}

        # Create multiple disk groups for better performance
        $diskGroupsToCreate = [math]::Min($cacheDisks.Count, 2)  # Max 2 disk groups per host

        for ($i = 0; $i -lt $diskGroupsToCreate; $i++) {
            $cacheDevice = $cacheDisks[$i]
            $capacityDevicesForGroup = $capacityDisks | Select-Object -Skip ($i * 3) -First 3

            if ($capacityDevicesForGroup.Count -gt 0) {
                New-VsanDiskGroup -VMHost $vmhost -SsdCanonicalName $cacheDevice.CanonicalName -HddCanonicalName $capacityDevicesForGroup.CanonicalName
                Write-Host "Created disk group on $($vmhost.Name) with cache $($cacheDevice.CanonicalName)"
            }
        }
    }
}

New-ProductionDiskGroups -ClusterName "PROD-vSAN-Cluster"
```

## Phase 3: Storage Policy Configuration

### Production Storage Policies

```powershell
# Create tiered storage policies for production
$productionPolicies = @{
    "PROD-Tier1-Critical" = @{
        "VSAN.hostFailuresToTolerate" = "2"
        "VSAN.replicaPreference" = "RAID-1 (Mirroring)"
        "VSAN.stripeWidth" = "4"
        "VSAN.proportionalCapacity" = "100"
        "VSAN.cacheReservation" = "50"
        "VSAN.encryptionEnabled" = "true"
    }
    "PROD-Tier2-Standard" = @{
        "VSAN.hostFailuresToTolerate" = "1"
        "VSAN.replicaPreference" = "RAID-1 (Mirroring)"
        "VSAN.stripeWidth" = "2"
        "VSAN.proportionalCapacity" = "25"
        "VSAN.cacheReservation" = "25"
        "VSAN.encryptionEnabled" = "true"
    }
    "PROD-Tier3-Capacity" = @{
        "VSAN.hostFailuresToTolerate" = "1"
        "VSAN.replicaPreference" = "RAID-5 (Erasure Coding)"
        "VSAN.stripeWidth" = "1"
        "VSAN.proportionalCapacity" = "0"
        "VSAN.cacheReservation" = "10"
        "VSAN.encryptionEnabled" = "true"
    }
}

foreach ($policyName in $productionPolicies.Keys) {
    $rules = $productionPolicies[$policyName]
    New-VmStoragePolicy -Name $policyName -Description "Production policy for $policyName workloads" -AnyOfRuleSets $rules
    Write-Host "Created storage policy: $policyName"
}
```

## Phase 4: Security Configuration

### Encryption Setup

```powershell
# Configure vSAN encryption with KMS
$kmsCluster = @{
    Name = "Production-KMS"
    Address = "kms.company.com"
    Port = 5696
    Username = "<KMS_USERNAME>"
    Password = "<KMS_PASSWORD>"
}

# Note: Replace with actual KMS configuration
Write-Host "Configure KMS integration through vSphere Client:"
Write-Host "1. Menu > Configure > Security > Key Management Servers"
Write-Host "2. Add KMS cluster: $($kmsCluster.Name)"
Write-Host "3. Configure connection to $($kmsCluster.Address):$($kmsCluster.Port)"
```

### Access Control

```powershell
# Configure role-based access control
$vsanRoles = @{
    "vSAN-Administrator" = @("VsanCluster.Config", "Datastore.Config", "Datastore.Browse")
    "vSAN-ReadOnly" = @("System.Anonymous", "System.View")
    "vSAN-Operator" = @("VirtualMachine.Provisioning.DiskRandomAccess", "Datastore.AllocateSpace")
}

foreach ($roleName in $vsanRoles.Keys) {
    $privileges = $vsanRoles[$roleName]
    New-VIRole -Name $roleName -Privilege (Get-VIPrivilege -Id $privileges)
    Write-Host "Created role: $roleName"
}
```

## Phase 5: VM Deployment and Migration

### Automated VM Deployment

```powershell
# Deploy production VMs with appropriate policies
$productionVMs = @(
    @{Name="DB-PROD-01"; Policy="PROD-Tier1-Critical"; CPU=8; RAM=32; Disk=500},
    @{Name="DB-PROD-02"; Policy="PROD-Tier1-Critical"; CPU=8; RAM=32; Disk=500},
    @{Name="APP-PROD-01"; Policy="PROD-Tier2-Standard"; CPU=4; RAM=16; Disk=200},
    @{Name="APP-PROD-02"; Policy="PROD-Tier2-Standard"; CPU=4; RAM=16; Disk=200},
    @{Name="WEB-PROD-01"; Policy="PROD-Tier3-Capacity"; CPU=2; RAM=8; Disk=100},
    @{Name="WEB-PROD-02"; Policy="PROD-Tier3-Capacity"; CPU=2; RAM=8; Disk=100}
)

$vsanDatastore = Get-Datastore | Where-Object {$_.Type -eq "vsan"}

foreach ($vmConfig in $productionVMs) {
    $storagePolicy = Get-VmStoragePolicy -Name $vmConfig.Policy

    $vmSpec = @{
        Name = $vmConfig.Name
        Datastore = $vsanDatastore
        NumCpu = $vmConfig.CPU
        MemoryGB = $vmConfig.RAM
        DiskGB = $vmConfig.Disk
        StoragePolicy = $storagePolicy
        GuestId = "ubuntu64Guest"
    }

    New-VM @vmSpec
    Write-Host "Deployed VM: $($vmConfig.Name) with policy $($vmConfig.Policy)"
}
```

### Migration from Legacy Storage

```powershell
# Migrate existing VMs to vSAN
function Move-VMsToVsan {
    param([string]$SourceDatastore, [string]$TargetPolicy)

    $sourceDS = Get-Datastore $SourceDatastore
    $targetDS = Get-Datastore | Where-Object {$_.Type -eq "vsan"}
    $policy = Get-VmStoragePolicy $TargetPolicy

    $vmsToMigrate = Get-VM -Datastore $sourceDS | Where-Object {$_.PowerState -eq "PoweredOn"}

    foreach ($vm in $vmsToMigrate) {
        Write-Host "Migrating $($vm.Name) to vSAN..."

        # Storage vMotion to vSAN with new policy
        Move-VM -VM $vm -Datastore $targetDS -StoragePolicy $policy -RunAsync

        # Wait for migration to complete
        do {
            Start-Sleep 30
            $task = Get-Task | Where-Object {$_.Description -like "*$($vm.Name)*" -and $_.State -eq "Running"}
        } while ($task)

        Write-Host "Migration completed for $($vm.Name)"
    }
}

# Example migration
# Move-VMsToVsan -SourceDatastore "Legacy-SAN-01" -TargetPolicy "PROD-Tier2-Standard"
```

## Phase 6: Monitoring and Maintenance

### Production Monitoring Setup

```powershell
# Configure comprehensive monitoring
$monitoringConfig = @{
    HealthCheckInterval = 60  # minutes
    PerformanceInterval = 5   # minutes
    CapacityThreshold = 80    # percent
    AlertEmail = "vsanadmin@company.com"
}

# Create monitoring script
$monitoringScript = @"
# Production vSAN Monitoring Script
param([hashtable]`$Config)

`$cluster = Get-Cluster "PROD-vSAN-Cluster"

# Health monitoring
`$health = Get-VsanClusterHealth -Cluster `$cluster
if (`$health.OverallHealth -ne "green") {
    Send-MailMessage -To `$Config.AlertEmail -Subject "vSAN Health Alert" -Body "Cluster health: `$(`$health.OverallHealth)"
}

# Capacity monitoring
`$capacity = Get-VsanSpaceUsage -Cluster `$cluster
`$usedPercent = (`$capacity.TotalCapacityB - `$capacity.FreeCapacityB) / `$capacity.TotalCapacityB * 100
if (`$usedPercent -gt `$Config.CapacityThreshold) {
    Send-MailMessage -To `$Config.AlertEmail -Subject "vSAN Capacity Alert" -Body "Capacity usage: `$([math]::Round(`$usedPercent, 2))%"
}

# Performance monitoring
`$perfStats = Get-Stat -Entity `$cluster -Stat @(
    "vsan.dom.compmgr.readLatency.avg",
    "vsan.dom.compmgr.writeLatency.avg"
) -MaxSamples 1

foreach (`$stat in `$perfStats) {
    if (`$stat.Value -gt 10) {  # 10ms threshold
        Send-MailMessage -To `$Config.AlertEmail -Subject "vSAN Performance Alert" -Body "`$(`$stat.MetricId): `$(`$stat.Value)ms"
    }
}
"@

$monitoringScript | Out-File "PROD-vSAN-Monitor.ps1"
```

### Backup and DR Configuration

```powershell
# Configure backup procedures
$backupConfig = @{
    ConfigBackupPath = "\\backup-server\vsan-configs\"
    BackupSchedule = "Daily"
    RetentionDays = 30
}

# Create configuration backup script
function Backup-VsanConfiguration {
    param([string]$ClusterName, [string]$BackupPath)

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFolder = Join-Path $BackupPath "vsan-backup-$timestamp"
    New-Item -ItemType Directory -Path $backupFolder -Force

    # Export cluster configuration
    $cluster = Get-Cluster $ClusterName
    $vsanConfig = Get-VsanClusterConfiguration -Cluster $cluster
    $vsanConfig | Export-Clixml -Path "$backupFolder\cluster-config.xml"

    # Export storage policies
    $policies = Get-VmStoragePolicy | Where-Object {$_.Name -like "PROD-*"}
    $policies | Export-Clixml -Path "$backupFolder\storage-policies.xml"

    # Export VM configurations
    $vms = Get-VM -Location $cluster
    $vmConfigs = foreach ($vm in $vms) {
        @{
            Name = $vm.Name
            StoragePolicy = (Get-VmStoragePolicy -VM $vm).Name
            NumCpu = $vm.NumCpu
            MemoryGB = $vm.MemoryGB
        }
    }
    $vmConfigs | Export-Clixml -Path "$backupFolder\vm-configs.xml"

    Write-Host "Configuration backup completed: $backupFolder"
}

# Schedule daily backup
# Backup-VsanConfiguration -ClusterName "PROD-vSAN-Cluster" -BackupPath $backupConfig.ConfigBackupPath
```

## Phase 7: Performance Validation

### Production Performance Testing

```powershell
# Validate production performance targets
function Test-ProductionPerformance {
    param([string]$ClusterName)

    $cluster = Get-Cluster $ClusterName
    $testResults = @{}

    # Test IOPS
    $iopsStats = Get-Stat -Entity $cluster -Stat @(
        "vsan.dom.compmgr.readIops.avg",
        "vsan.dom.compmgr.writeIops.avg"
    ) -MaxSamples 10

    $totalIOPS = ($iopsStats | Measure-Object Value -Sum).Sum
    $testResults.IOPS = $totalIOPS

    # Test Latency
    $latencyStats = Get-Stat -Entity $cluster -Stat "vsan.dom.compmgr.readLatency.avg" -MaxSamples 10
    $avgLatency = ($latencyStats | Measure-Object Value -Average).Average
    $testResults.LatencyMs = $avgLatency

    # Validate against requirements
    $requirements = @{
        MinIOPS = 50000
        MaxLatencyMs = 2
    }

    Write-Host "Performance Test Results:"
    Write-Host "  Total IOPS: $($testResults.IOPS) (Required: $($requirements.MinIOPS))"
    Write-Host "  Average Latency: $($testResults.LatencyMs)ms (Required: <$($requirements.MaxLatencyMs)ms)"

    $passed = $testResults.IOPS -ge $requirements.MinIOPS -and $testResults.LatencyMs -le $requirements.MaxLatencyMs
    Write-Host "  Performance Test: $(if($passed){'PASSED'}else{'FAILED'})" -ForegroundColor $(if($passed){'Green'}else{'Red'})

    return $testResults
}

# Run performance validation
$perfResults = Test-ProductionPerformance -ClusterName "PROD-vSAN-Cluster"
```

## Deployment Checklist

### Pre-Production Validation
- [ ] All hardware on VMware HCL
- [ ] Network configuration tested
- [ ] Storage policies validated
- [ ] Security configuration complete
- [ ] Backup procedures tested
- [ ] Performance requirements met
- [ ] Monitoring configured
- [ ] Documentation complete

### Go-Live Checklist
- [ ] Final health check passed
- [ ] All VMs migrated successfully
- [ ] Performance validated
- [ ] Monitoring alerts configured
- [ ] Support contacts established
- [ ] Rollback procedures documented

## Maintenance Procedures

### Regular Maintenance Tasks

1. **Daily**
   - Health status review
   - Capacity monitoring
   - Performance check

2. **Weekly**
   - Configuration backup
   - Policy compliance review
   - Performance trend analysis

3. **Monthly**
   - Firmware updates review
   - Capacity planning update
   - Security patch assessment

4. **Quarterly**
   - Full performance assessment
   - Disaster recovery test
   - Hardware refresh planning

