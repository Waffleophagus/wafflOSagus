# Deploying wafflOSagus uCore VM on Unraid

## Overview

This guide walks through deploying wafflOSagus uCore as a headless VM on Unraid using local ignition configuration passed via QEMU's fw_cfg mechanism.

## Workflow Summary

1. Boot base CoreOS/ucore qcow2 image
2. Ignition configuration loaded from local file via fw_cfg
3. Ignition sets up user (clawdbot) and rebases to custom image
4. System auto-reboots into wafflOSagus
5. SSH access available post-boot

## Prerequisites

### Unraid Requirements
- Unraid 7.x (for inline XML editing and QEMU command-line passthrough)
- KVM virtualization enabled
- Sufficient storage for VM disk (60GB recommended minimum)
- Access to Unraid CLI (terminal) for file setup

### Files Needed
- Base qcow2 image (Fedora CoreOS or uCore minimal)
- Ignition configuration file from your GitHub repository
- SSH public key (already configured in ignition)

## Step-by-Step Deployment

### Phase 1: Download Ignition Configuration

Download ignition file to Unraid's domains directory:

```bash
# Download from GitHub
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux label (required for libvirt security)
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify file and SELinux context
ls -Z /mnt/user/domains/ucore-vm.ign
```

**Ignition file contents:**
- User: `clawdbot` with SSH key
- Systemd service to rebase to `ghcr.io/waffleophagus/wafflosagus-ucore:latest`
- Auto-reboot after rebase completes

### Phase 2: Prepare VM Image

1. Place your base qcow2 image in Unraid domains directory:
   ```
   /mnt/user/domains/fedora-coreos-base.qcow2
   ```

2. Note: This is base image you downloaded, not custom wafflOSagus image (that comes from registry)

### Phase 3: Create VM in Unraid WebGUI

1. Navigate to **Virtual Machines** → **Add VM**
2. Select **Custom** template
3. Configure basic settings:
   - **Name**: `wafflosagus-ucore`
   - **Description**: `wafflOSagus uCore headless VM`
   - **CPU Cores**: `4`
   - **Initial Memory**: `6144` (6 GB)
   - **Machine Type**: `Q35` (recommended for modern Linux)
   - **BIOS Type**: `OVMF` (UEFI required for modern CoreOS)

4. **OS Settings**:
   - **Operating System**: Linux
   - **OS Variant**: Fedora

5. **Primary vDisk Configuration**:
   - **Location**: `/mnt/user/domains/wafflosagus-ucore/vdisk1.img`
   - **Size**: `60 GB` (or your preferred size)
   - **Backing Store**: Point to your base qcow2 image
   - **Bus**: VirtIO
   - **Format**: QCOW2 (supports snapshots)

6. **Graphics**:
   - **Graphics Card**: VNC
   - **Video RAM**: 32 MB (minimal for headless)
   - **Console**: Serial (for boot messages via VNC)

7. **Network**:
   - **Network Bridge**: br0 (default)
   - **Network Model**: VirtIO
   - **MAC Address**: Auto-generated (or set specific if needed)

8. **Create VM** (but don't start yet)

### Phase 4: Edit VM XML for Ignition

Configure libvirt to pass ignition file via QEMU's fw_cfg mechanism:

1. Stop VM if it's running
2. Click on VM → **Edit XML** (available in Unraid 7.x)
3. Scroll to bottom of XML, locate `</domain>` closing tag
4. Add qemu:commandline section **just before** `</domain>`:

```xml
<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:arg value='-fw_cfg'/>
  <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
</qemu:commandline>
```

**Important**: This must be placed AFTER the `<devices>` section, before `</domain>`.

5. Save XML

### Phase 5: Boot and Monitor First Boot

1. Start VM
2. Open VNC console to monitor boot process
3. Watch for:
   - Ignition message: "Applying config from fw_cfg"
   - "Ignition: applied config successfully"
   - Rebase command executing
   - "Rebooting now..." message

4. **After reboot**, system should be running wafflOSagus image

### Phase 6: Post-Boot Configuration

1. Connect via SSH:
   ```bash
   ssh clawdbot@<vm-ip-address>
   ```

2. Verify wafflOSagus is running:
   ```bash
   rpm-ostree status
   ```
   Should show image: `ghcr.io/waffleophagus/wafflosagus-ucore:latest`

3. Verify system services:
   ```bash
   systemctl status tailscaled
   # Check other services as needed
   ```

4. Clean up qemu:commandline (optional but recommended):
   - Stop VM
   - Edit XML
   - Remove entire `<qemu:commandline>` section
   - Save XML
   - Ignition only runs on first boot, so this prevents unnecessary config passes

5. Verify SSH access works reliably
6. You can now disable VNC if desired (headless operation confirmed)

## Alternative Methods

### GitHub URL Approach (Not Recommended)

**Why not recommended:**
- UEFI/OVMF bootloader doesn't pass kernel_args from libvirt XML
- `ignition.config.url` kernel parameter doesn't work with UEFI boot
- Requires complex bootloader configuration or hybrid approach

**If you really want to use GitHub:**
1. Use hybrid approach: local ignition that fetches from GitHub
2. See `docs/local-ignition-alternative.md` for details
3. Requires editing local ignition file on Unraid anyway

**Recommendation**: Stick with local file + fw_cfg method documented above.

## Troubleshooting

### Issue: Ignition fails to load

**Symptoms:**
- No ignition message in VNC console
- User not created after boot
- Rebase doesn't run

**Solutions:**
1. Check ignition file exists:
   ```bash
   ls -la /mnt/user/domains/ucore-vm.ign
   ```

2. Verify SELinux context:
   ```bash
   ls -Z /mnt/user/domains/ucore-vm.ign
   # Should show: svirt_home_t
   ```

3. Fix SELinux context if wrong:
   ```bash
   chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

4. Verify qemu:commandline in XML:
   ```bash
   grep -A3 "qemu:commandline" /etc/libvirt/qemu/wafflosagus-ucore.xml
   ```

### Issue: Rebase Fails

**Symptoms:**
- Rebase command errors
- "Image not found" errors
- Authentication issues with container registry

**Solutions:**
1. Verify image URL is correct: `ghcr.io/waffleophagus/wafflosagus-ucore:latest`
2. Check if image is public or if authentication is needed
3. Ensure network connectivity persists through rebase
4. Check `/var/log/messages` for detailed error logs
5. Try manual rebase: `sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus-ucore:latest`

### Issue: System Doesn't Auto-Reboot

**Symptoms:**
- Rebase completes but system doesn't reboot
- System stays in intermediate state

**Solutions:**
1. Check systemd service logs:
   ```bash
   journalctl -u rebase-to-wafflosagus.service
   ```

2. Manually reboot if service failed: `sudo systemctl reboot`

3. Verify service is enabled:
   ```bash
   systemctl is-enabled rebase-to-wafflosagus.service
   ```

4. Check if conditional `ConditionPathExists=/etc/ignition-machine-config` is met

### Issue: SSH Access Not Working After Rebase

**Symptoms:**
- Can't SSH as clawdbot
- SSH connection refused
- Authentication failed

**Solutions:**
1. Verify user exists: `id clawdbot`
2. Check SSH key in `~/.ssh/authorized_keys`
3. Check sshd service: `systemctl status sshd`
4. Verify network is up: `ip addr show`
5. Try direct console access via VNC to debug
6. Check firewall rules if applicable

### Issue: SELinux Errors

**Symptoms:**
- "Permission denied" accessing ignition file
- AVC denials in logs

**Solutions:**
1. Check SELinux context:
   ```bash
   ls -Z /mnt/user/domains/ucore-vm.ign
   ```

2. Fix context:
   ```bash
   chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

3. If that fails, try disabling SELinux temporarily (not recommended):
   ```bash
   setenforce 0
   # Then re-enable after boot:
   setenforce 1
   ```

## Maintenance

### Updating wafflOSagus Image

Since wafflOSagus is built with BlueBuild and updated via rpm-ostree:

1. Check for updates:
   ```bash
   rpm-ostree status
   ```

2. Update system:
   ```bash
   sudo rpm-ostree upgrade
   ```

3. Reboot after update:
   ```bash
   sudo systemctl reboot
   ```

### Updating Ignition Configuration

**Note:** Ignition only runs on first boot. To reapply ignition:

1. Not recommended for production systems
2. If needed, create new VM from scratch
3. Or use cloud-init/ignition for persistent configuration

### Snapshots and Rollbacks

Unraid 7.x supports VM snapshots:

1. Create snapshot before major changes:
   - VM → Snapshots → Create Snapshot
   - Name descriptively (e.g., "Before update", "Clean install")

2. Revert to snapshot:
   - VM → Snapshots → Select snapshot → Revert
   - Any changes after snapshot are lost

3. Commit snapshot to disk:
   - VM → Snapshots → Select snapshot → Block Commit
   - Makes snapshot state permanent

## VM Specifications Reference

| Setting | Value | Notes |
|---------|-------|-------|
| Name | wafflosagus-ucore | VM identifier |
| CPU | 4 cores | Adjustable based on needs |
| Memory | 6 GB | Minimum for comfortable operation |
| Disk | 60 GB QCOW2 | Can be expanded later |
| Machine Type | Q35 | Modern, recommended |
| BIOS | OVMF (UEFI) | Required for CoreOS |
| Graphics | VNC | Headless, console only |
| Network | br0 | Bridge to host network |
| Image | ghcr.io/waffleophagus/wafflosagus-ucore:latest | Rebased to during first boot |

## File Paths Reference

```
/mnt/user/domains/
├── wafflosagus-ucore/
│   ├── vdisk1.img              # Primary VM disk
│   └── wafflosagus-ucore_VARS.fd  # UEFI NVRAM
├── fedora-coreos-base.qcow2     # Base image (backing store)
└── ucore-vm.ign               # Ignition configuration
```

## Quick Reference Commands

### From Unraid Host
```bash
# Download ignition file
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux context
chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify file
ls -Z /mnt/user/domains/ucore-vm.ign

# List running VMs
virsh list

# Start VM
virsh start wafflosagus-ucore

# Stop VM
virsh shutdown wafflosagus-ucore

# Force stop
virsh destroy wafflosagus-ucore

# Edit VM XML
virsh edit wafflosagus-ucore

# View VM console
virsh console wafflosagus-ucore
```

### From Inside VM (clawdbot user)
```bash
# Check current deployment
rpm-ostree status

# Update system
sudo rpm-ostree upgrade

# Check service status
systemctl status <service-name>

# View journal logs
journalctl -u <service-name>

# Reboot
sudo systemctl reboot
```

## Updating Ignition File

To update the ignition configuration:

1. Make changes to `ucore-vm.ign` in your repository
2. On Unraid, download new version:
   ```bash
   wget -O /mnt/user/domains/ucore-vm.ign \
     https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

   chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

3. Create new VM (ignition only runs on first boot)
   Or use the updated ignition for fresh deployments

## References

- [Fedora CoreOS Ignition Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/)
- [BlueBuild Documentation](https://blue-build.org/)
- [Unraid VM Documentation](https://docs.unraid.net/unraid-os/using-unraid-to/create-virtual-machines/vm-setup/)
- [rpm-ostree Documentation](https://coreos.github.io/rpm-ostree/)
- [QEMU fw_cfg Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-qemu/)

## Changelog

- 2025-01-10: Initial documentation created
  - fw_cfg + local file method (primary, recommended)
  - GitHub URL method documented as alternative (not recommended)
  - Comprehensive troubleshooting section
  - SELinux context handling documented
