# Frequently Asked Questions (FAQ)

## General Questions

### What is VMware vSAN?
vSAN is a software-defined storage solution that aggregates local storage devices across a vSphere cluster to create a shared datastore.

### What's new in vSAN 8?
- Express Storage Architecture (ESA)
- vSAN Max for enhanced performance
- Improved compression and deduplication
- Enhanced file services
- Better cloud integration

### What are the minimum requirements?
- 3 ESXi hosts minimum
- 1 SSD for cache per host
- 1GbE network (10GbE recommended)
- vCenter Server

## Licensing Questions

### What vSAN editions are available?
- **Standard**: Basic vSAN functionality
- **Advanced**: Adds encryption, stretched clusters
- **Enterprise**: Adds deduplication, compression
- **Enterprise Plus**: All features included

### Can I use vSAN with existing storage?
vSAN requires local storage devices. Existing shared storage cannot be used directly.

## Technical Questions

### How many hosts can I have in a vSAN cluster?
- Standard cluster: 3-64 hosts
- Stretched cluster: 2-30 hosts per site
- 2-node cluster: 2 hosts + witness

### What storage devices are supported?
Only devices on the VMware Hardware Compatibility List (HCL) are supported.

### Can I mix SSD and HDD?
Yes, in hybrid configurations. All-flash is recommended for best performance.

## Configuration Questions

### How do I size my vSAN cluster?
Use the VMware vSAN Sizing Calculator and consider:
- Raw vs usable capacity
- Performance requirements
- Growth projections

### What storage policies should I use?
Depends on workload requirements:
- **FTT=1**: Standard protection
- **FTT=2**: Higher availability
- **RAID-5/6**: Space efficient for larger clusters

### How do I configure networking?
- Dedicated vSAN network recommended
- Jumbo frames (9000 MTU)
- Multiple adapters for redundancy

## Performance Questions

### How can I improve vSAN performance?
- Use all-flash configuration
- Optimize network (10GbE+, jumbo frames)
- Proper storage policy configuration
- Balance workloads across hosts

### What affects vSAN performance?
- Storage device performance
- Network bandwidth and latency
- Storage policy settings
- Cluster configuration

## Troubleshooting Questions

### How do I check vSAN health?
Use vSAN Health Service in vCenter or PowerCLI:
```powershell
Get-VsanClusterHealth -Cluster "ClusterName"
```

### What if a host fails?
vSAN automatically rebuilds affected objects based on storage policy settings.

### How do I resolve capacity issues?
- Add more hosts or storage
- Optimize storage policies
- Enable deduplication/compression
- Clean up unnecessary data

## Maintenance Questions

### How do I update vSAN?
Follow VMware's recommended update sequence:
1. vCenter Server
2. ESXi hosts (maintenance mode)
3. vSAN disk format upgrade if needed

### Can I add storage to existing cluster?
Yes, you can add:
- New hosts with storage
- Additional disk groups to existing hosts
- Individual disks to existing disk groups

### How do I backup vSAN?
- Use VM-level backup solutions
- Export vSAN configuration
- Document cluster settings

## Migration Questions

### Can I migrate from traditional storage to vSAN?
Yes, using Storage vMotion to move VMs to vSAN datastore.

### How do I migrate between vSAN clusters?
Use vMotion and Storage vMotion for live migration.

## Support Questions

### Where can I get help?
- VMware Support (with valid license)
- VMware Community Forums
- VMware Documentation
- This repository's issue tracker

### What logs should I collect for support?
- vSAN Health Service logs
- ESXi host logs
- vCenter Server logs
- Support bundle from affected hosts# Updated 20251109_123835
# Updated Sun Nov  9 12:49:24 CET 2025
# Updated Sun Nov  9 12:52:39 CET 2025
# Updated Sun Nov  9 12:56:07 CET 2025
