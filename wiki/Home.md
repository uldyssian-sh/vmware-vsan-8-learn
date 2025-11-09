# VMware vSAN 8 Learning Wiki

Welcome to the comprehensive VMware vSAN 8 learning wiki! This resource provides detailed information, best practices, and troubleshooting guides for vSAN 8.

## 📚 Wiki Contents

### Getting Started
- [vSAN 8 Overview](./vSAN-8-Overview.md)
- [Architecture Deep Dive](./Architecture-Deep-Dive.md)
- [Prerequisites and Planning](./Prerequisites-and-Planning.md)
- [Installation Guide](./Installation-Guide.md)

### Configuration
- [Storage Policies](./Storage-Policies.md)
- [Network Configuration](./Network-Configuration.md)
- [Security and Encryption](./Security-and-Encryption.md)
- [Stretched Clusters](./Stretched-Clusters.md)

### Operations
- [Monitoring and Health](./Monitoring-and-Health.md)
- [Performance Optimization](./Performance-Optimization.md)
- [Maintenance and Updates](./Maintenance-and-Updates.md)
- [Backup and Recovery](./Backup-and-Recovery.md)

### Troubleshooting
- [Common Issues](./Common-Issues.md)
- [Performance Troubleshooting](./Performance-Troubleshooting.md)
- [Network Troubleshooting](./Network-Troubleshooting.md)
- [Storage Troubleshooting](./Storage-Troubleshooting.md)

### Advanced Topics
- [Automation with PowerCLI](./Automation-with-PowerCLI.md)
- [Integration with vRealize](./Integration-with-vRealize.md)
- [Hybrid Cloud Integration](./Hybrid-Cloud-Integration.md)
- [Capacity Planning](./Capacity-Planning.md)

### Reference
- [Command Reference](./Command-Reference.md)
- [API Reference](./API-Reference.md)
- [Best Practices](./Best-Practices.md)
- [FAQ](./FAQ.md)

## 🎯 Learning Paths

### Beginner Path
1. Start with [vSAN 8 Overview](./vSAN-8-Overview.md)
2. Review [Prerequisites and Planning](./Prerequisites-and-Planning.md)
3. Follow [Installation Guide](./Installation-Guide.md)
4. Learn about [Storage Policies](./Storage-Policies.md)
5. Practice with [Basic Labs](../labs/01-basic-setup.md)

### Intermediate Path
1. Deep dive into [Architecture](./Architecture-Deep-Dive.md)
2. Master [Network Configuration](./Network-Configuration.md)
3. Explore [Performance Optimization](./Performance-Optimization.md)
4. Learn [Monitoring and Health](./Monitoring-and-Health.md)
5. Practice [Advanced Labs](../labs/)

### Advanced Path
1. Study [Stretched Clusters](./Stretched-Clusters.md)
2. Master [Automation with PowerCLI](./Automation-with-PowerCLI.md)
3. Explore [Hybrid Cloud Integration](./Hybrid-Cloud-Integration.md)
4. Learn [Capacity Planning](./Capacity-Planning.md)
5. Complete [Expert Labs](../labs/)

## 🔧 Quick Reference

### Essential Commands
```powershell
# Connect to vCenter
Connect-VIServer -Server <VCENTER_SERVER>

# Check vSAN health
Get-VsanClusterHealth -Cluster <CLUSTER_NAME>

# Monitor capacity
Get-VsanSpaceUsage -Cluster <CLUSTER_NAME>

# Check storage policies
Get-VmStoragePolicy
```

### Key Concepts
- **Disk Groups**: Cache + Capacity tiers
- **Storage Policies**: Define VM storage requirements
- **Witness Host**: Required for stretched/2-node clusters
- **Deduplication**: Space-saving technology
- **Compression**: Additional space savings

### Important URLs
- [VMware vSAN Documentation](https://docs.vmware.com/en/VMware-vSAN/)
- [vSAN Community](https://communities.vmware.com/t5/VMware-vSAN/ct-p/2002)
- [vSAN Sizing Guide](https://core.vmware.com/resource/vmware-vsan-sizing-guide)

## 🤝 Contributing to Wiki

We welcome contributions to improve this wiki:

1. **Content Updates**: Submit PRs for corrections or improvements
2. **New Articles**: Add new topics or expand existing ones
3. **Examples**: Share real-world configurations and use cases
4. **Translations**: Help translate content to other languages

### Wiki Guidelines
- Use clear, concise language
- Include practical examples
- Reference official VMware documentation
- Test all procedures before documenting
- Keep content current with latest vSAN versions

## 📞 Support and Community

- **Issues**: Report problems via [GitHub Issues](https://github.com/uldyssian-sh/vmware-vsan-8-learn/issues)
- **Discussions**: Join conversations in [GitHub Discussions](https://github.com/uldyssian-sh/vmware-vsan-8-learn/discussions)
- **Community**: Connect with other vSAN users in VMware communities

## 📈 Recent Updates

- **2024-01**: Added vSAN 8 new features documentation
- **2024-01**: Updated installation procedures
- **2024-01**: Enhanced troubleshooting guides
- **2024-01**: Added PowerCLI automation examples

---

**Note**: This wiki is maintained by the community. Always verify information with official VMware documentation for production deployments.# Updated 20251109_123835
# Updated Sun Nov  9 12:49:24 CET 2025
