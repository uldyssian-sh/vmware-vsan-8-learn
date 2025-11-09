# vSAN 8 Installation Tutorial

This tutorial walks you through the complete installation and initial configuration of VMware vSAN 8.

## Prerequisites

Before starting, ensure you have:
- [ ] 3+ ESXi hosts with compatible hardware
- [ ] vCenter Server deployed and configured
- [ ] All hosts added to vCenter inventory
- [ ] Network configuration completed
- [ ] Storage devices available and recognized

## Step 1: Verify Hardware Compatibility

### Check Hardware Compatibility List (HCL)
```powershell
# Connect to vCenter
Connect-VIServer -Server <VCENTER_SERVER> -User <USERNAME> -Password <PASSWORD>

# Check vSAN compatibility
Get-VsanClusterConfiguration -Cluster <CLUSTER_NAME>
```

### Verify Storage Devices
1. Navigate to **Host** > **Configure** > **Storage Devices**
2. Verify all intended vSAN devices are visible
3. Check device health status

## Step 2: Configure vSAN Network

### Create vSAN VMkernel Port
```powershell
# Create vSAN VMkernel port on each host
$vmhosts = Get-Cluster <CLUSTER_NAME> | Get-VMHost
foreach ($vmhost in $vmhosts) {
    New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup "vSAN-PG" -VirtualSwitch "vSwitch0" -IP <VSAN_IP> -SubnetMask <SUBNET_MASK> -VsanTrafficEnabled:$true
}
```

### Manual Configuration Steps
1. **vCenter** > **Hosts and Clusters**
2. Select host > **Configure** > **VMkernel adapters**
3. **Add Networking** > **VMkernel Network Adapter**
4. Configure:
   - **Network**: Select vSAN port group
   - **IP Settings**: Static IP in vSAN subnet
   - **Services**: Enable **vSAN**

## Step 3: Enable vSAN on Cluster

### Using vSphere Client
1. Navigate to **Cluster** > **Configure** > **vSAN**
2. Click **Turn On vSAN**
3. Select **Configure vSAN**
4. Choose configuration options:
   - **Deduplication and Compression**: Enable for space efficiency
   - **Encryption**: Enable if required
   - **vSAN HCI Mesh**: Configure if using multiple clusters

### Using PowerCLI
```powershell
# Enable vSAN on cluster
$cluster = Get-Cluster <CLUSTER_NAME>
$spec = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpec
$spec.Enabled = $true
$spec.DefaultConfig = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpecDefaultConfig
$spec.DefaultConfig.AutoClaimStorage = $true

Set-VsanClusterConfiguration -Cluster $cluster -VsanClusterConfigSpec $spec
```

## Step 4: Configure Disk Groups

### Automatic Disk Claiming
If **Auto-claim storage** was enabled, vSAN will automatically:
- Identify suitable cache and capacity devices
- Create disk groups
- Format devices for vSAN use

### Manual Disk Group Creation
```powershell
# Get available disks
$vmhost = Get-VMHost <HOST_NAME>
$availableDisks = Get-VsanDisk -VMHost $vmhost | Where-Object {$_.VsanDiskGroupUuid -eq $null}

# Create disk group
$cacheDisks = $availableDisks | Where-Object {$_.IsSsd -eq $true -and $_.CapacityGB -lt 1000}
$capacityDisks = $availableDisks | Where-Object {$_.IsSsd -eq $false -or $_.CapacityGB -gt 1000}

New-VsanDiskGroup -VMHost $vmhost -SsdCanonicalName $cacheDisks[0].CanonicalName -HddCanonicalName $capacityDisks[0].CanonicalName
```

### Manual Configuration via UI
1. **Host** > **Configure** > **vSAN** > **Disk Management**
2. **Create Disk Group**
3. Select:
   - **Cache tier**: SSD device
   - **Capacity tier**: One or more storage devices
4. **Create**

## Step 5: Verify Installation

### Check Cluster Health
```powershell
# Check vSAN health
Get-VsanClusterHealth -Cluster <CLUSTER_NAME>

# Check disk group status
Get-VsanDiskGroup -Cluster <CLUSTER_NAME>

# Verify datastore creation
Get-Datastore | Where-Object {$_.Type -eq "vsan"}
```

### Health Check via UI
1. **Cluster** > **Monitor** > **vSAN** > **Health**
2. Review all health categories
3. Address any warnings or errors

## Step 6: Create VM Storage Policies

### Default Policy
vSAN creates a default policy with:
- **Failures to tolerate**: 1
- **RAID type**: RAID-1 (Mirroring)

### Custom Policy Creation
```powershell
# Create custom storage policy
$policySpec = New-Object VMware.VimAutomation.Storage.Types.V1.VmStoragePolicySpec
$policySpec.Name = "vSAN-Performance"
$policySpec.Description = "High performance vSAN policy"

# Add vSAN rules
$rule = New-Object VMware.VimAutomation.Storage.Types.V1.VmStoragePolicyRule
$rule.RuleSet = @(
    @{
        "VSAN.hostFailuresToTolerate" = "1"
        "VSAN.stripeWidth" = "2"
        "VSAN.forceProvisioning" = "false"
    }
)

New-VmStoragePolicy -Spec $policySpec
```

## Step 7: Test Installation

### Create Test VM
1. Create new virtual machine
2. Select vSAN datastore
3. Apply custom storage policy
4. Power on and verify functionality

### Performance Test
```powershell
# Basic I/O test using PowerCLI
$vm = Get-VM <TEST_VM_NAME>
$vmGuest = $vm.ExtensionData.Guest

# Monitor vSAN performance
Get-VsanStat -Entity $vm -StartTime (Get-Date).AddHours(-1) -EndTime (Get-Date)
```

## Common Installation Issues

### Network Issues
- **Symptom**: Hosts cannot join vSAN cluster
- **Solution**: Verify vSAN network connectivity and multicast

### Storage Issues
- **Symptom**: Disks not claimed automatically
- **Solution**: Check HCL compatibility and disk health

### Performance Issues
- **Symptom**: Slow VM performance
- **Solution**: Verify cache tier configuration and network bandwidth

## Post-Installation Tasks

### Configure Monitoring
1. Set up vSAN health monitoring
2. Configure alerts and notifications
3. Establish baseline performance metrics

### Security Configuration
1. Enable encryption if required
2. Configure access controls
3. Set up audit logging

### Backup Configuration
1. Configure vSAN datastore backups
2. Test restore procedures
3. Document recovery processes

## Next Steps

1. Complete [Basic Configuration Lab](../labs/01-basic-setup.md)
2. Review [Storage Policies Tutorial](./02-storage-policies.md)
3. Set up [Monitoring and Maintenance](./03-monitoring.md)

## Troubleshooting Resources

- [vSAN Health Service](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-monitoring/GUID-F5B3B9F5-8B5C-4B5C-8B5C-8B5C8B5C8B5C.html)
- [vSAN Performance Troubleshooting](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-troubleshooting/)
- [VMware KB Articles](https://kb.vmware.com/)# Documentation updated Sun Nov  9 14:43:37 CET 2025
