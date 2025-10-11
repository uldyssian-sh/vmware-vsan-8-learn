# VMware vSAN 8 Learning Resources

<div align="center">
  
  [![vSAN 8](https://img.shields.io/badge/VMware-vSAN_8.0-00A1C9.svg?style=for-the-badge&logo=vmware)](https://www.vmware.com/products/vsan.html)
  [![Learning](https://img.shields.io/badge/Learning-Resources-blue.svg?style=for-the-badge)](https://www.vmware.com/education-services)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
  
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
python main.py

# Access lab guides
open labs/01-basic-setup.md
```

## 📖 Study Materials

| Topic | Lab Guide | Difficulty | Duration |
|-------|-----------|------------|----------|
| vSAN Basics | [Lab 1](labs/01-basic-setup.md) | 🟢 Beginner | 2 hours |
| Performance Testing | [Lab 2](labs/02-performance-testing.md) | 🟡 Intermediate | 3 hours |

## 🏆 Certification Path

### VCP-DCV (vSphere Data Center Virtualization)
- **Prerequisites**: vSphere experience
- **Training**: vSphere: Install, Configure, Manage
- **Exam**: 2V0-21.23

### VCAP-DCV Design
- **Prerequisites**: VCP-DCV certification
- **Training**: vSphere: Design Workshop
- **Exam**: 3V0-21.23

## 📖 Documentation

- [Overview](docs/01-overview.md)
- [Prerequisites](docs/prerequisites.md)
- [FAQ](docs/faq.md)
- [Examples](examples/)
- [Labs](labs/)

## 📊 vSAN Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    vSAN 8 Architecture                     │
├─────────────────────────────────────────────────────────────┤
│  ESXi Host 1    │  ESXi Host 2    │  ESXi Host 3          │
│  ┌───────────┐  │  ┌───────────┐  │  ┌───────────┐        │
│  │ vSAN Node │  │  │ vSAN Node │  │  │ vSAN Node │        │
│  │ Cache SSD │  │  │ Cache SSD │  │  │ Cache SSD │        │
│  │Capacity HD│  │  │Capacity HD│  │  │Capacity HD│        │
│  └───────────┘  │  └───────────┘  │  └───────────┘        │
└─────────────────────────────────────────────────────────────┘
```

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

## Support

- **Issues**: [GitHub Issues](https://github.com/uldyssian-sh/vmware-vsan-8-learn/issues)
- **Security**: [Security Policy](SECURITY.md)
- **Contributing**: [Contributing Guidelines](CONTRIBUTING.md)

---

**⭐ Star this repository if you find it helpful!**
