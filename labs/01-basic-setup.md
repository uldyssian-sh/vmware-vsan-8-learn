# Lab 1: Basic vSAN Setup

## Objective
Set up a basic 3-node vSAN cluster and create your first virtual machine with custom storage policies.

## Prerequisites
- 3 ESXi hosts (physical or nested)
- vCenter Server deployed
- Each host has at least 1 SSD and 1 HDD/SSD
- Network connectivity between hosts

## Lab Environment
- **Cluster Name**: vSAN-Lab-Cluster
- **vSAN Network**: 192.168.100.0/24
- **Hosts**:
  - esxi-01.lab.local (192.168.100.11)
  - esxi-02.lab.local (192.168.100.12)
  - esxi-03.lab.local (192.168.100.13)

## Exercise 1: Prepare the Environment

### Step 1: Verify Host Configuration
1. Connect to vCenter Server
2. Navigate to **Hosts and Clusters**
3. Verify all 3 hosts are present and connected
4. Check each host has sufficient resources:
   - CPU: 4+ cores
   - Memory: 32GB+
   - Storage: 2+ drives per host

### Step 2: Create vSAN Network
1. On each host, navigate to **Configure** > **Networking** > **Virtual switches**
2. Create or verify vSAN port group exists
3. Configure VMkernel adapter for vSAN:
   - **Network**: vSAN port group
   - **IP**: Static IP in vSAN subnet
   - **Services**: Enable vSAN traffic

### Verification Commands
```powershell
# Connect to vCenter
Connect-VIServer -Server <VCENTER_SERVER>

# Check host connectivity
Get-VMHost | Select Name, ConnectionState, PowerState

# Verify vSAN network adapters
Get-VMHost | Get-VMHostNetworkAdapter | Where-Object {$_.VsanTrafficEnabled -eq $true}
```

## Exercise 2: Enable vSAN

### Step 1: Create vSAN Cluster
1. Right-click datacenter > **New Cluster**
2. Name: `vSAN-Lab-Cluster`
3. Enable **vSAN**
4. Configure options:
   - ✅ Turn On vSAN
   - ✅ Deduplication and compression
   - ❌ Encryption (for this lab)

### Step 2: Add Hosts to Cluster
1. Drag and drop hosts into the cluster
2. Or use **Add Hosts** wizard
3. Verify all hosts join successfully

### PowerCLI Alternative
```powershell
# Create cluster with vSAN enabled
New-Cluster -Name "vSAN-Lab-Cluster" -Location (Get-Datacenter)

# Enable vSAN on cluster
$cluster = Get-Cluster "vSAN-Lab-Cluster"
$spec = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpec
$spec.Enabled = $true
$spec.DefaultConfig = New-Object VMware.VimAutomation.Vsan.Types.V1.VsanClusterConfigSpecDefaultConfig
$spec.DefaultConfig.AutoClaimStorage = $true

Set-VsanClusterConfiguration -Cluster $cluster -VsanClusterConfigSpec $spec
```

## Exercise 3: Configure Storage

### Step 1: Verify Available Disks
1. Select a host > **Configure** > **Storage** > **Storage Devices**
2. Identify available disks for vSAN
3. Note SSD and HDD devices

### Step 2: Create Disk Groups
If auto-claim didn't work:
1. Navigate to **Configure** > **vSAN** > **Disk Management**
2. **Create Disk Group**
3. Select:
   - **Cache tier**: SSD device
   - **Capacity tier**: HDD or additional SSD
4. Repeat for each host

### Verification
```powershell
# Check vSAN datastore
Get-Datastore | Where-Object {$_.Type -eq "vsan"}

# Verify disk groups
Get-VsanDiskGroup -Cluster "vSAN-Lab-Cluster"

# Check cluster health
Get-VsanClusterHealth -Cluster "vSAN-Lab-Cluster"
```

## Exercise 4: Create Storage Policies

### Step 1: Create Performance Policy
1. **Menu** > **Policies and Profiles** > **VM Storage Policies**
2. **Create VM Storage Policy**
3. Name: `vSAN-Performance`
4. Configure rules:
   - **Successs to tolerate**: 1
   - **Number of disk stripes per object**: 2
   - **Flash read cache reservation**: 25%

### Step 2: Create Capacity Policy
1. Create another policy: `vSAN-Capacity`
2. Configure rules:
   - **Successs to tolerate**: 1
   - **Number of disk stripes per object**: 1
   - **Object space reservation**: 0%

### PowerCLI Alternative
```powershell
# Create performance policy
$performanceRules = @{
    "VSAN.hostSuccesssToTolerate" = "1"
    "VSAN.stripeWidth" = "2"
    "VSAN.proportionalCapacity" = "25"
}

New-VmStoragePolicy -Name "vSAN-Performance" -AnyOfRuleSets $performanceRules

# Create capacity policy
$capacityRules = @{
    "VSAN.hostSuccesssToTolerate" = "1"
    "VSAN.stripeWidth" = "1"
    "VSAN.proportionalCapacity" = "0"
}

New-VmStoragePolicy -Name "vSAN-Capacity" -AnyOfRuleSets $capacityRules
```

## Exercise 5: Deploy Test Virtual Machine

### Step 1: Create VM
1. **Right-click cluster** > **New Virtual Machine**
2. Select **Create a new virtual machine**
3. Configure:
   - **Name**: vSAN-Test-VM
   - **Datastore**: vsanDatastore
   - **VM Storage Policy**: vSAN-Performance
   - **Guest OS**: Linux (Ubuntu 64-bit)
   - **Hardware**: 2 vCPU, 4GB RAM, 20GB disk

### Step 2: Install Operating System
1. Mount Ubuntu ISO
2. Power on VM
3. Complete basic OS installation
4. Install VMware Tools

### Step 3: Verify Storage Policy
1. Select VM > **Configure** > **Policies**
2. Verify policy compliance
3. Check storage usage in vSAN datastore

## Exercise 6: Monitor and Validate

### Step 1: Check vSAN Health
1. **Cluster** > **Monitor** > **vSAN** > **Health**
2. Review all health categories
3. Address any warnings or Successs

### Step 2: Monitor Performance
1. **Monitor** > **vSAN** > **Performance**
2. Review IOPS, throughput, and latency
3. Generate some I/O load on test VM

### Step 3: Capacity Monitoring
1. **Monitor** > **vSAN** > **Capacity**
2. Check used vs available space
3. Review deduplication and compression ratios

### PowerCLI Monitoring
```powershell
# Check overall health
Get-VsanClusterHealth -Cluster "vSAN-Lab-Cluster"

# Monitor capacity
Get-VsanSpaceUsage -Cluster "vSAN-Lab-Cluster"

# Check VM compliance
Get-VM "vSAN-Test-VM" | Get-VmStoragePolicyCompliance
```

## Lab Validation Checklist

- [ ] vSAN cluster created with 3 hosts
- [ ] vSAN datastore visible and healthy
- [ ] All hosts have disk groups configured
- [ ] Custom storage policies created
- [ ] Test VM deployed with custom policy
- [ ] VM is policy compliant
- [ ] vSAN health shows green status
- [ ] Performance monitoring working

## Troubleshooting Common Issues

### Issue: Hosts won't join vSAN cluster
**Symptoms**: Hosts remain in maintenance mode or show Successs
**Solutions**:
- Verify vSAN network connectivity
- Check multicast configuration
- Ensure time synchronization
- Verify storage device compatibility

### Issue: Disk groups not created automatically
**Symptoms**: No disk groups visible after enabling vSAN
**Solutions**:
- Manually create disk groups
- Check device compatibility with HCL
- Verify devices are not in use by other systems
- Check device health status

### Issue: VM deployment fails
**Symptoms**: Cannot deploy VM to vSAN datastore
**Solutions**:
- Check storage policy compatibility
- Verify sufficient capacity
- Ensure cluster has enough hosts for policy requirements
- Check vSAN health status

## Next Steps

After completing this lab:
1. Try [Storage Policies Lab](./02-storage-policies.md)
2. Explore [Performance Optimization Lab](./03-performance-tuning.md)
3. Learn about [Stretched Clusters](./04-stretched-cluster.md)

## Cleanup (Optional)

To clean up the lab environment:
```powershell
# Remove test VM
Remove-VM -VM "vSAN-Test-VM" -DeletePermanently -Confirm:$false

# Remove storage policies
Remove-VmStoragePolicy -StoragePolicy "vSAN-Performance" -Confirm:$false
Remove-VmStoragePolicy -StoragePolicy "vSAN-Capacity" -Confirm:$false

# Disable vSAN (if needed)
# Note: This will destroy all data!
# Set-VsanClusterConfiguration -Cluster "vSAN-Lab-Cluster" -VsanClusterConfigSpec @{Enabled=$false}
```

## Additional Resources

- [vSAN Planning and Deployment Guide](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-planning/)
- [vSAN Troubleshooting Guide](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-troubleshooting/)
