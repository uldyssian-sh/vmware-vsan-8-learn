# Prerequisites for VMware vSAN 8

## Hardware Requirements

### Server Requirements
- **CPU**: x86-64 architecture with VT-x/AMD-V support
- **Memory**: Minimum 32GB RAM per host (64GB+ recommended)
- **Network**: Minimum 1GbE (10GbE or higher recommended)
- **Storage Controllers**: vSAN HCL certified controllers

### Storage Requirements

#### Cache Tier (Required)
- **Type**: SSD or NVMe
- **Size**: Minimum 600GB per disk group
- **Ratio**: 1:10 cache to capacity ratio recommended
- **Endurance**: High endurance drives recommended

#### Capacity Tier
- **All-Flash**: SSD or NVMe drives
- **Hybrid**: SATA/SAS HDDs (7.2K or 10K RPM)
- **Size**: Varies based on requirements
- **Quantity**: 1-7 capacity drives per disk group

### Network Requirements

#### vSAN Network
- **Bandwidth**: Minimum 1GbE per host
- **Recommended**: 10GbE or higher
- **Latency**: <1ms between hosts
- **Dedicated**: Separate network for vSAN traffic

#### Network Configuration
- **VLAN**: Dedicated VLAN for vSAN
- **MTU**: Jumbo frames (9000 bytes) recommended
- **Multicast**: Required for vSAN clustering

## Software Requirements

### VMware vSphere
- **Version**: vSphere 8.0 or later
- **vCenter Server**: Required for vSAN management
- **ESXi Hosts**: All hosts must be same version

### Licensing
- **vSAN License**: Per CPU licensing model
- **Editions**: Standard, Advanced, Enterprise, Enterprise Plus
- **Features**: Different features per edition

## Cluster Requirements

### Minimum Configuration
- **Hosts**: 3 hosts minimum for standard cluster
- **Disk Groups**: 1 disk group per host minimum
- **Witness**: Required for 2-node and stretched clusters

### Recommended Configuration
- **Hosts**: 4-8 hosts for optimal performance
- **Disk Groups**: 2-5 disk groups per host
- **Redundancy**: Multiple paths and controllers

## Compatibility

### Hardware Compatibility List (HCL)
- All components must be on VMware HCL
- Regular HCL updates required
- Driver compatibility verification

### Version Compatibility
- vSphere and vSAN versions must match
- vCenter Server compatibility
- Third-party integration compatibility

## Planning Considerations

### Capacity Planning
- **Raw vs Usable**: Account for overhead and protection
- **Growth**: Plan for 18-24 months capacity
- **Performance**: IOPS and throughput requirements

### Network Planning
- **Bandwidth**: Calculate required bandwidth
- **Redundancy**: Multiple network paths
- **Segmentation**: Separate vSAN traffic

### Security Planning
- **Encryption**: Data-at-rest and in-transit
- **Access Control**: Role-based access
- **Compliance**: Regulatory requirements

## Pre-Installation Checklist

### Hardware Verification
- [ ] All hardware on VMware HCL
- [ ] Sufficient CPU and memory
- [ ] Compatible storage controllers
- [ ] Network connectivity verified

### Software Preparation
- [ ] vSphere licenses available
- [ ] vCenter Server deployed
- [ ] ESXi hosts installed and configured
- [ ] Network configuration complete

### Documentation
- [ ] Network diagram created
- [ ] IP address plan documented
- [ ] Storage requirements calculated
- [ ] Backup and recovery plan

## Common Prerequisites Issues

### Hardware Issues
- **Non-HCL Components**: Can cause instability
- **Insufficient Cache**: Poor performance
- **Network Bottlenecks**: Slow operations

### Software Issues
- **Version Mismatches**: Compatibility problems
- **License Issues**: Feature limitations
- **Configuration Errors**: Deployment failures

## Next Steps

After verifying all prerequisites:
1. Follow [Installation Tutorial](../tutorials/01-installation.md)
2. Review [Network Configuration](./network-configuration.md)
3. Complete [Environment Setup Lab](../labs/environment-setup.md)

## Additional Resources

- [VMware Compatibility Guide](https://www.vmware.com/resources/compatibility/search.php)
- [vSAN Hardware Requirements](https://docs.vmware.com/en/VMware-vSAN/8.0/vsan-planning/GUID-4D436B9C-5F46-4718-9B1E-5BF7F3B982A9.html)
- [vSAN Sizing Calculator](https://core.vmware.com/resource/vmware-vsan-sizing-guide)# Documentation updated Sun Nov  9 14:43:37 CET 2025
