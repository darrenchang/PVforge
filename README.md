# PXVIRT (Formerly Proxmox-Port)

A fork of Proxmox VE for ARM and LoongArch architectures
AGPL-3.0 Licensed | Community-Driven Project

## NOTE!

The project has received some donations, but these donations (please refer to the donation list in SUPPORT.md) are not sufficient to cover our expenses on warehouse servers, compilation servers, and other related costs. Therefore, we will stop the distribution of pveport's deb files and ISO images to free up more space for PXVIRT.

The original Proxmox-Port repository will be cancelled.
If you want to get updates, please visit docs.pxvirt.lierfang.com to get the latest documentation information!

[English docs](https://docs.pxvirt.lierfang.com/en/README.html) | [中文文档](https://docs.pxvirt.lierfang.com/zh/README.html)

## Community

- Discord: [https://discord.gg/cYZEpUx5QJ](https://discord.gg/cYZEpUx5QJ)

- QQ 群组: 102166071/904754537/940488655/750937440

## 📖 Overview

PXVIRT is an open-source virtualization platform derived from Proxmox VE, specifically adapted to support ARM and LoongArch architectures. This project originally began as "Proxmox-Port" and has now evolved into a fully independent fork under the new name PXVIRT.

## 🚀 Why PXVIRT?

###  Historical Context

Original Mission: The project started as "Proxmox-Port" to port Proxmox VE to non-x86 architectures.
Rebranding: Due to trademark restrictions ("Proxmox" is a registered trademark of Proxmox Server Solutions GmbH), we renamed the project to PXVIRT to comply with legal requirements while preserving its core purpose.


### Technical Value

- 🖥️ Multi-Arch Support: Brings Proxmox VE's powerful virtualization tools to ARM64 and LoongArch platforms. We also provide x86 versions of the software to achieve compatibility among three different architectures within the same cluster.

- 🔄 Upstream Sync: Maintains compatibility with Proxmox VE upstream features while adding architecture-specific optimizations.

- 📜 License Compliance: Fully open-source under AGPLv3, respecting upstream licensing terms.

- 🔄 Migration Notice: Proxmox-Port → PXVIRT


Proxmox-Port is now deprecated and will no longer receive updates.
All future development will focus on PXVIRT. Users are strongly advised to:

Migrate to PXVIRT for continued support
Benefit from upstream feature synchronization
Receive ARM/LoongArch-specific improvements

###  🛠️ Features

Full virtualization stack for ARM/LoongArch servers
Web-based management interface
Container and KVM virtualization support
Storage management integration
Network configuration tools
Note: Features are inherited from Proxmox VE and extended for target architectures.

### Roadmap

- Easy DPDK
- Datacenter Manager 
- Integrate more hardware tools, such as IPMI, StorCLI, etc., and provide access interfaces.
- Integrate more system management tools, such as automatic diagnosis, SAN management, SR-IOV management, VIP, etc.

## ⚙️ Installation & Documentation

For installation instructions and documentation, please refer to:

[PXVIRT Documentation](https://docs.pxvirt.lierfang.com)

## ⚖️ Legal Disclaimer

- PXVIRT is not affiliated with Proxmox Server Solutions GmbH
- Proxmox® is a registered trademark of Proxmox Server Solutions GmbH
- Original Proxmox VE code is licensed under AGPLv3
- PXVIRT exists to expand virtualization accessibility, not replace Proxmox VE. Consider supporting both projects where appropriate.

## 💰 Support & Donation

For commercial support services and donation information, please see:

📄 **[Support & Commercial Services](./SUPPORT.md)**
