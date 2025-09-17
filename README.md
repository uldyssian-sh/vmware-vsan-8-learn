# VMware vSAN 8 Learning Resources

<div align="center">
  <img src="https://blogs.vmware.com/virtualblocks/files/2019/09/vSAN-Logo.png" alt="vSAN 8" width="350"/>
  
  [![vSAN 8](https://img.shields.io/badge/vSAN-8.0-00A1C9.svg)](https://www.vmware.com/products/vsan.html)
  [![Learning](https://img.shields.io/badge/Learning-Resources-blue.svg)](https://www.vmware.com/education-services)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

## 📚 Overview

Comprehensive learning materials for VMware vSAN 8, including hands-on labs, certification preparation, and best practices for hyper-converged infrastructure.

## 🎓 Learning Modules

### Foundation Concepts
- **vSAN Architecture**: Distributed storage fundamentals
- **Storage Policies**: VM storage requirements definition
- **Disk Groups**: Cache and capacity tier management
- **Fault Domains**: Availability and resilience

### Advanced Features
- **Stretched Clusters**: Multi-site deployments
- **2-Node Clusters**: Remote office solutions
- **Encryption**: Data-at-rest and in-transit security
- **Deduplication & Compression**: Space efficiency

### Operations & Management
- **Health Monitoring**: Proactive issue detection
- **Performance Optimization**: Tuning and troubleshooting
- **Capacity Planning**: Growth and scaling strategies
- **Maintenance Operations**: Updates and lifecycle management

## 🧪 Hands-on Labs

```bash
# Clone lab environment
git clone https://github.com/uldyssian-sh/vmware-vsan-8-learn.git
cd vmware-vsan-8-learn/labs

# Start nested lab environment
./setup-vsan-lab.sh --nodes 4 --version 8.0

# Access lab guide
open lab-guides/vsan-fundamentals.html
```

## 📖 Study Materials

| Topic | Lab Guide | Difficulty | Duration |
|-------|-----------|------------|----------|
| vSAN Basics | [Lab 1](labs/01-basics/) | 🟢 Beginner | 2 hours |
| Storage Policies | [Lab 2](labs/02-policies/) | 🟡 Intermediate | 3 hours |
| Stretched Clusters | [Lab 3](labs/03-stretched/) | 🔴 Advanced | 4 hours |
| Troubleshooting | [Lab 4](labs/04-troubleshooting/) | 🔴 Advanced | 3 hours |

## 🏆 Certification Path

### VCP-DCV (vSphere Data Center Virtualization)
- **Prerequisites**: vSphere experience
- **Training**: vSphere: Install, Configure, Manage
- **Exam**: 2V0-21.23

### VCAP-DCV Design
- **Prerequisites**: VCP-DCV certification
- **Training**: vSphere: Design Workshop
- **Exam**: 3V0-21.23

## 📊 vSAN Architecture Diagram

![vSAN Architecture](https://via.placeholder.com/800x500/00A1C9/FFFFFF?text=vSAN+8+Architecture+Diagram)

## 🔧 Lab Environment Requirements

### Minimum Hardware
- **CPU**: 4 cores per nested ESXi host
- **Memory**: 8GB per nested ESXi host
- **Storage**: 100GB per nested ESXi host
- **Network**: Gigabit Ethernet

### Software Requirements
- **VMware Workstation/Fusion**: For nested virtualization
- **vSphere 8.0**: ESXi and vCenter licenses
- **vSAN 8.0**: Evaluation or licensed version

## 📚 Documentation

- [Lab Setup Guide](https://github.com/uldyssian-sh/vmware-vsan-8-learn/wiki/Lab-Setup)
- [Study Plan](https://github.com/uldyssian-sh/vmware-vsan-8-learn/wiki/Study-Plan)
- [Certification Guide](https://github.com/uldyssian-sh/vmware-vsan-8-learn/wiki/Certification)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.
