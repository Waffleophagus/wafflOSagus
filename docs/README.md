# wafflOSagus Documentation

This directory contains comprehensive documentation for deploying and managing wafflOSagus on various platforms.

## Guides

### Primary Documentation

- **[unraid-ucore-deployment.md](unraid-ucore-deployment.md)**
  - Complete guide for deploying wafflOSagus uCore VM on Unraid
  - Covers GitHub URL and local ignition methods
  - Comprehensive troubleshooting section
  - Maintenance and update procedures

### Alternative Methods

- **[local-ignition-alternative.md](local-ignition-alternative.md)**
  - Detailed guide for switching from GitHub URL to local ignition file
  - Quick reference for switching back and forth
  - Hybrid approach for maximum reliability

### Quick Reference

- **[quick-reference.md](quick-reference.md)**
  - TL;DR command summary
  - Common tasks at a glance
  - VM settings reference
  - Cheat sheet for troubleshooting

## Deployment Overview

wafflOSagus is built using BlueBuild and can be deployed to:

1. **Unraid VM** (headless server)
   - Uses Fedora CoreOS/ucore base
   - Configured via Ignition
   - Rebases to custom wafflOSagus image on first boot

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

### 5-Minute Setup

1. **Create VM** in Unraid WebGUI with:
   - 4 CPU, 6GB RAM, 60GB disk
   - Q35 machine type, OVMF BIOS
   - VNC graphics, VirtIO network

2. **Edit VM XML** - Add kernel args for GitHub ignition:
   ```xml
   <kernel_args>ignition.config.url=https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign</kernel_args>
   ```

3. **Boot VM** - Watch VNC console for:
   - Ignition fetch and apply
   - Rebase to wafflOSagus image
   - Auto-reboot

4. **Verify** - SSH as `clawdbot`:
   ```bash
   ssh clawdbot@<vm-ip>
   rpm-ostree status
   ```

5. **Cleanup** - Remove ignition config from VM XML

**Full details**: See [unraid-ucore-deployment.md](unraid-ucore-deployment.md)

## Image Registry

Custom images are available at:
```
ghcr.io/waffleophagus/wafflosagus-ucore:latest
ghcr.io/waffleophagus/wafflosagus-bazzite:latest
ghcr.io/waffleophagus/wafflosagus-DX:latest
```

## Key Concepts

### Atomic/Immutable Systems
- System files cannot be modified at runtime
- Updates via rpm-ostree with rollback capability
- Signed images with SecureBoot support

### Ignition Configuration
- Runs only on first boot
- Provides initial configuration (users, services, rebase)
- Can be fetched from URL or provided locally

### rpm-ostree
- Package management for atomic systems
- Supports layered packages
- Atomic updates with rollback capability

## Community & Support

- **BlueBuild**: https://blue-build.org/
- **Universal Blue**: https://universal-blue.org/
- **Fedora Atomic**: https://fedoraproject.org/atomic-desktops
- **Unraid Forums**: https://forums.unraid.net/

## Contributing

This repository is personal. For BlueBuild templates and examples:
- [blue-build/template](https://github.com/blue-build/template)
- [ublue-os/image-template](https://github.com/ublue-os/image-template)

## License

This project follows the same license as BlueBuild templates.
