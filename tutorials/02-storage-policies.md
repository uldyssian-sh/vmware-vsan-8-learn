# Tutorial 2: Advanced Storage Policies

Learn how to create and manage advanced vSAN storage policies for different workload requirements.

## Overview

Storage policies define how vSAN stores and protects your virtual machine data. This tutorial covers advanced policy creation and management.

## Prerequisites

- Completed [Installation Tutorial](./01-installation.md)
- vSAN cluster with 4+ hosts (for RAID-5/6 examples)
- Basic understanding of vSAN concepts

## Storage Policy Components

### Availability Rules
- **Failures to Tolerate (FTT)**: Number of host/device failures to survive
- **Failure Tolerance Method**: RAID-1, RAID-5, or RAID-6

### Performance Rules
- **Number of disk stripes per object**: Distributes I/O across devices
- **IOPS limit**: Throttles VM performance if needed
- **Object space reservation**: Guarantees space allocation

### Advanced Rules
- **Flash read cache reservation**: Reserves cache for reads
- **Disable object checksum**: Reduces CPU overhead
- **Force provisioning**: Allows policy violations

## Creating Storage Policies

### High Performance Policy

```powershell
# Create performance-optimized policy
$performanceRules = @{
    "VSAN.hostFailuresToTolerate" = "1"
    "VSAN.stripeWidth" = "4"
    "VSAN.proportionalCapacity" = "50"
    "VSAN.cacheReservation" = "25"
}

New-VmStoragePolicy -Name "vSAN-HighPerformance" -Description "High performance for critical workloads" -AnyOfRuleSets $performanceRules
```

### Space Efficient Policy

```powershell
# Create space-efficient policy with RAID-5
$efficiencyRules = @{
    "VSAN.hostFailuresToTolerate" = "1"
    "VSAN.replicaPreference" = "RAID-5 (Erasure Coding)"
    "VSAN.stripeWidth" = "1"
    "VSAN.proportionalCapacity" = "0"
}

New-VmStoragePolicy -Name "vSAN-SpaceEfficient" -Description "RAID-5 for capacity optimization" -AnyOfRuleSets $efficiencyRules
```

### Mission Critical Policy

```powershell
# Create high availability policy
$criticalRules = @{
    "VSAN.hostFailuresToTolerate" = "2"
    "VSAN.replicaPreference" = "RAID-1 (Mirroring)"
    "VSAN.stripeWidth" = "2"
    "VSAN.proportionalCapacity" = "100"
    "VSAN.cacheReservation" = "50"
}

New-VmStoragePolicy -Name "vSAN-MissionCritical" -Description "Maximum protection and performance" -AnyOfRuleSets $criticalRules
```

## Policy Management via vSphere Client

### Creating Policies

1. **Menu** > **Policies and Profiles** > **VM Storage Policies**
2. **Create VM Storage Policy**
3. **Name and Description**: Enter policy details
4. **Policy structure**: Choose "Enable rules for vSAN storage"
5. **Configure rules**:

#### Availability Settings
- **Failures to tolerate**: 1-3 (based on cluster size)
- **Failure tolerance method**:
  - RAID-1: Better performance, more space usage
  - RAID-5: Space efficient, requires 4+ hosts
  - RAID-6: Maximum protection, requires 6+ hosts

#### Performance Settings
- **Number of disk stripes**: 1-12 (higher = better performance)
- **Object space reservation**: 0-100% (guaranteed space)
- **Flash read cache reservation**: 0-100% (dedicated cache)

### Policy Validation

1. **Review compatibility**: Check cluster compatibility
2. **Preview resource usage**: See space and performance impact
3. **Create policy**: Finalize and save

## Applying Storage Policies

### During VM Creation

1. **New Virtual Machine** wizard
2. **Select storage**: Choose vSAN datastore
3. **VM Storage Policy**: Select appropriate policy
4. **Review and finish**

### To Existing VMs

```powershell
# Apply policy to existing VM
$vm = Get-VM -Name "ProductionVM"
$policy = Get-VmStoragePolicy -Name "vSAN-HighPerformance"
Set-VM -VM $vm -StoragePolicy $policy
```

### Bulk Policy Application

```powershell
# Apply policy to multiple VMs
$vms = Get-VM -Location "Production" | Where-Object {$_.PowerState -eq "PoweredOn"}
$policy = Get-VmStoragePolicy -Name "vSAN-MissionCritical"

foreach ($vm in $vms) {
    Set-VM -VM $vm -StoragePolicy $policy -Confirm:$false
    Write-Host "Applied policy to $($vm.Name)"
}
```

## Monitoring Policy Compliance

### Check Compliance Status

```powershell
# Check all VMs compliance
Get-VM | Get-VmStoragePolicyCompliance | Format-Table VM, StoragePolicy, ComplianceStatus

# Check specific VM
Get-VM "CriticalApp" | Get-VmStoragePolicyCompliance
```

### Resolve Non-Compliance

```powershell
# Find non-compliant VMs
$nonCompliant = Get-VM | Get-VmStoragePolicyCompliance | Where-Object {$_.ComplianceStatus -ne "Compliant"}

foreach ($vm in $nonCompliant) {
    Write-Host "VM $($vm.VM) is $($vm.ComplianceStatus)"
    # Trigger compliance check
    Set-VM -VM $vm.VM -StoragePolicy $vm.StoragePolicy -Confirm:$false
}
```

## Advanced Policy Scenarios

### Stretched Cluster Policies

```powershell
# Policy for stretched cluster with site affinity
$stretchedRules = @{
    "VSAN.hostFailuresToTolerate" = "1"
    "VSAN.locality" = "preferredSite"
    "VSAN.stripeWidth" = "1"
}

New-VmStoragePolicy -Name "vSAN-Stretched" -AnyOfRuleSets $stretchedRules
```

### Encryption Policy

```powershell
# Policy with encryption enabled
$encryptionRules = @{
    "VSAN.hostFailuresToTolerate" = "1"
    "VSAN.encryptionEnabled" = "true"
    "VSAN.stripeWidth" = "1"
}

New-VmStoragePolicy -Name "vSAN-Encrypted" -AnyOfRuleSets $encryptionRules
```

### Development Environment Policy

```powershell
# Minimal protection for dev/test
$devRules = @{
    "VSAN.hostFailuresToTolerate" = "0"
    "VSAN.stripeWidth" = "1"
    "VSAN.proportionalCapacity" = "0"
    "VSAN.forceProvisioning" = "true"
}

New-VmStoragePolicy -Name "vSAN-Development" -AnyOfRuleSets $devRules
```

## Policy Best Practices

### Performance Optimization
- Use higher stripe width for I/O intensive workloads
- Reserve cache for critical applications
- Consider object space reservation for guaranteed performance

### Capacity Optimization
- Use RAID-5/6 for large, less critical datasets
- Minimize object space reservation
- Enable deduplication and compression

### Availability Requirements
- FTT=1 for standard protection
- FTT=2 for mission-critical workloads
- Consider stretched clusters for site-level protection

## Troubleshooting Storage Policies

### Common Issues

#### Policy Not Available
- **Cause**: Insufficient cluster resources
- **Solution**: Add hosts or modify policy requirements

#### Poor Performance
- **Cause**: Inadequate stripe width or cache reservation
- **Solution**: Increase stripes or cache allocation

#### Space Issues
- **Cause**: High object space reservation
- **Solution**: Reduce reservation or add capacity

### Diagnostic Commands

```powershell
# Check policy resource requirements
Get-VmStoragePolicy | Get-VmStoragePolicyRequirement

# Verify cluster capabilities
Get-VsanClusterConfiguration | Select-Object -ExpandProperty Capability

# Monitor policy impact
Get-VsanSpaceUsage -IncludeVmConsumption
```

## Lab Exercise

### Create Tiered Storage Policies

1. **Tier 1 - Mission Critical**
   - FTT=2, RAID-1, Stripe=4, Cache=50%

2. **Tier 2 - Production**
   - FTT=1, RAID-1, Stripe=2, Cache=25%

3. **Tier 3 - General**
   - FTT=1, RAID-5, Stripe=1, Cache=10%

4. **Tier 4 - Development**
   - FTT=0, Stripe=1, No reservations

### Test and Validate

```powershell
# Create test VMs with different policies
$policies = @("Tier1-Critical", "Tier2-Production", "Tier3-General", "Tier4-Development")

foreach ($policy in $policies) {
    $vmName = "Test-$policy"
    New-VM -Name $vmName -Datastore "vsanDatastore" -StoragePolicy (Get-VmStoragePolicy $policy)
    Write-Host "Created $vmName with $policy policy"
}

# Monitor compliance
Get-VM Test-* | Get-VmStoragePolicyCompliance
```

## Next Steps

1. Complete [Performance Optimization Tutorial](./03-performance-optimization.md)
2. Learn about [Monitoring and Maintenance](./04-monitoring-maintenance.md)
3. Explore [Stretched Clusters](./05-stretched-clusters.md)

## Additional Resources

- [vSAN Storage Policy Guide](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-administration/GUID-08911FD3-2462-4C1C-AE81-0D4DBC8F7990.html)
- [Storage Policy Best Practices](https://core.vmware.com/resource/vmware-vsan-storage-policy-best-practices)# Updated Sun Nov  9 12:49:24 CET 2025
# Updated Sun Nov  9 12:52:39 CET 2025
# Updated Sun Nov  9 12:56:07 CET 2025
