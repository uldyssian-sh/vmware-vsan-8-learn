# VMware vSAN 8 Overview

## What is VMware vSAN?

VMware vSAN (Virtual Storage Area Network) is a software-defined storage solution that is fully integrated with VMware vSphere. It pools together local storage devices across a vSphere cluster to create a single, shared datastore.

## Key Features of vSAN 8

### 🚀 New in vSAN 8
- **vSAN Max**: Enhanced performance and scalability
- **Express Storage Architecture (ESA)**: Next-generation storage architecture
- **Improved Compression and Deduplication**: Better storage efficiency
- **Enhanced File Services**: Native file services integration
- **Cloud Integration**: Seamless hybrid cloud capabilities

### 🏗️ Core Architecture Components

#### Disk Groups
- **Cache Tier**: High-performance SSDs for caching
- **Capacity Tier**: SSDs or HDDs for persistent storage
- **All-Flash Configuration**: Best performance with all SSDs
- **Hybrid Configuration**: Cost-effective with SSD cache + HDD capacity

#### Storage Policies
- **VM Storage Policies (VMSP)**: Define storage requirements
- **Successs to Tolerate (FTT)**: Resilience configuration
- **RAID Configurations**: RAID-1, RAID-5, RAID-6 options
- **Stripe Width**: Performance optimization

### 🔧 Deployment Models

#### Standard Cluster
- Minimum 3 hosts
- Shared storage across cluster
- Automatic load balancing

#### Stretched Cluster
- Geographic distribution
- Automatic failover
- Witness host for quorum

#### 2-Node Cluster
- Small deployments
- External witness appliance
- Cost-effective solution

## Benefits

### 💰 Cost Efficiency
- Eliminates need for external SAN
- Uses local server storage
- Reduces hardware complexity

### 📈 Performance
- Local storage performance
- Intelligent caching
- Parallel I/O operations

### 🛡️ Reliability
- Built-in redundancy
- Self-healing capabilities
- Proactive monitoring

### 🔄 Scalability
- Scale-out architecture
- Add capacity by adding nodes
- Non-disruptive scaling

## Use Cases

### Primary Storage
- Virtual machine storage
- Database workloads
- VDI deployments

### Edge Computing
- Remote office deployments
- Branch office storage
- Edge data centers

### Hybrid Cloud
- Cloud migration
- Disaster recovery
- Backup and archival

## Prerequisites

### Hardware Requirements
- vSphere-compatible servers
- Minimum 3 hosts for standard cluster
- SSD for cache tier (recommended)
- Network connectivity (1GbE minimum, 10GbE recommended)

### Software Requirements
- VMware vSphere 8.0 or later
- vCenter Server
- vSAN license

### Network Requirements
- Dedicated vSAN network (recommended)
- Jumbo frames support
- Low latency connectivity

## Next Steps

1. Review [Prerequisites](./prerequisites.md)
2. Follow [Installation Tutorial](../tutorials/01-installation.md)
3. Complete [Basic Lab](../labs/01-basic-setup.md)

## Additional Resources

- [VMware vSAN Documentation](https://docs.vmware.com/en/VMware-vSAN/)
- [vSAN Sizing Guide](https://core.vmware.com/resource/vmware-vsan-sizing-guide)
