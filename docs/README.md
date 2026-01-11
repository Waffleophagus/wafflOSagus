# wafflOSagus Documentation

This directory contains comprehensive documentation for deploying and managing wafflOSagus on various platforms.

## Guides

### Primary Documentation

- **[Unraid uCore VM Deployment](unraid-ucore-deployment.md)** ⭐ Primary guide
  - Complete guide for deploying wafflOSagus uCore VM on Unraid
  - Uses local ignition file + fw_cfg (recommended, reliable method)
  - Comprehensive troubleshooting section
  - Maintenance and update procedures

### Technical Explanations

- **[GitHub vs Local Ignition](github-vs-local-ignition.md)**
  - Explains technical differences between methods
  - Why local file is recommended for Unraid UEFI setups
  - Migration guide from GitHub URL to local file
  - SELinux context requirements

### Quick Reference

- **[Quick Reference](quick-reference.md)**
  - TL;DR command summary
  - Common tasks at a glance
  - VM settings reference
  - Cheat sheet for troubleshooting

### Step-by-Step

- **[Deployment Checklist](deployment-checklist.md)**
  - Detailed verification steps
  - Troubleshooting flowcharts
  - Success indicators
  - Post-deploy checklist

## Deployment Overview

wafflOSagus is built using BlueBuild and can be deployed to:

1. **Unraid VM** (headless server) ⭐ Recommended method
   - Uses Fedora CoreOS/ucore base
   - Configured via local ignition file + fw_cfg
   - Rebases to custom wafflOSagus image on first boot
   - Reliable, well-documented approach

2. **Bare Metal**
   - Atomic desktop images
   - Direct install from ISO

3. **Other Hypervisors**
   - KVM/QEMU
   - Proxmox
   - VMware

## Image Variants

| Variant | Base Image | Use Case |
|---------|-----------|----------|
| `wafflosagus-ucore` | ucore-minimal | Headless VM, server |
| `wafflosagus-bazzite` | bazzite-gnome | Gaming desktop |
| `wafflosagus-DX` | bazzite-dx-gnome | Desktop workstation |

## Quick Start (Unraid VM)

### Prerequisites
- Unraid 7.x
- Base qcow2 image (Fedora CoreOS or uCore)
- Ignition configuration in GitHub repository
- Access to Unraid CLI (terminal)

### 5-Minute Setup

1. **Download ignition** to Unraid:
   ```bash
   wget -O /mnt/user/domains/ucore-vm.ign \
     https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
   chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

2. **Create VM** in Unraid WebGUI with:
   - 4 CPU, 6GB RAM, 60GB disk
   - Q35 machine type, OVMF BIOS
   - VNC graphics, VirtIO network

3. **Edit VM XML** - Add fw_cfg configuration:
   ```xml
   <qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
     <qemu:arg value='-fw_cfg'/>
     <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
   </qemu:commandline>
   ```

4. **Boot VM** - Watch VNC console for ignition and rebase
5. **SSH** as `clawdbot` after reboot
6. **Cleanup** - Remove fw_cfg from VM XML (ignition runs once)

**Full details**: See [unraid-ucore-deployment.md](unraid-ucore-deployment.md)

## Key Concepts

### Atomic/Immutable Systems
- System files cannot be modified at runtime
- Updates via rpm-ostree with rollback capability
- Signed images with SecureBoot support

### Ignition Configuration
- Runs only on first boot
- Provides initial configuration (users, services, rebase)
- Can be provided via fw_cfg (QEMU firmware config) or URLs
- fw_cfg is recommended for UEFI/OVMF setups

### rpm-ostree
- Package management for atomic systems
- Supports layered packages
- Atomic updates with rollback capability

## Why Local File + fw_cfg?

For Unraid VMs using UEFI/OVMF bootloader:

| Method | Works with UEFI? | Complexity | Reliability |
|--------|------------------|------------|-------------|
| **Local File + fw_cfg** | ✅ Yes | Low | High ⭐ Recommended |
| GitHub URL (kernel_args) | ❌ No | High | Low |
| GitHub URL (grub) | ✅ Yes | Very High | Medium |
| PXE/DHCP | ✅ Yes | Very High | Low |

**Technical Reason:** UEFI bootloader doesn't pass kernel_args from libvirt XML. fw_cfg is a direct QEMU feature that bypasses bootloader limitations.

See [github-vs-local-ignition.md](github-vs-local-ignition.md) for detailed explanation.

## Community & Support

- **BlueBuild**: https://blue-build.org/
- **Universal Blue**: https://universal-blue.org/
- **Fedora Atomic**: https://fedoraproject.org/atomic-desktops
- **Unraid Forums**: https://forums.unraid.net/

## Contributing

This repository is personal. For BlueBuild templates and examples:
- [blue-build/template](https://github.com/blue-build/template)
- [ublue-os/image-template](https://github.com/ublue-os/image-template)

## Image Registry

Custom images are available at:
```
ghcr.io/waffleophagus/wafflosagus-ucore:latest
ghcr.io/waffleophagus/wafflosagus-bazzite:latest
ghcr.io/waffleophagus/wafflosagus-DX:latest
```

## License

This project follows same license as BlueBuild templates.
