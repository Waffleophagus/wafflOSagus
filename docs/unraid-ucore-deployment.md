# Deploying wafflOSagus uCore VM on Unraid

## Overview

This guide walks through deploying wafflOSagus uCore as a headless VM on Unraid using GitHub-hosted ignition configuration.

## Workflow Summary

1. Boot base CoreOS/ucore qcow2 image
2. Ignition configuration fetched from GitHub during first boot
3. Ignition sets up user (clawdbot) and rebases to custom image
4. System auto-reboots into wafflOSagus
5. SSH access available post-boot

## Prerequisites

### Unraid Requirements
- Unraid 7.x (for inline XML editing and QEMU command-line passthrough)
- KVM virtualization enabled
- Sufficient storage for VM disk (60GB recommended minimum)
- Network connectivity during first boot (for GitHub ignition fetch)

### Files Needed
- Base qcow2 image (Fedora CoreOS or uCore minimal)
- Ignition configuration file in your GitHub repository
- SSH public key (already configured in ignition)

## Step-by-Step Deployment

### Phase 1: Prepare Ignition Configuration

Your ignition file should be stored at:
```
https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
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

2. Note: This is the base image you downloaded, not the custom wafflOSagus image (that comes from registry)

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

### Phase 4: Edit VM XML for GitHub Ignition

This is the critical step to fetch ignition from GitHub:

1. Stop the VM if it's running
2. Click on the VM → **Edit XML** (available in Unraid 7.x)
3. Locate the `<os>` section (near top of XML)
4. Add the kernel parameter to fetch ignition from GitHub:

```xml
<os>
  <type arch='x86_64' machine='pc-q35-rhel8.6.0'>hvm</type>
  <loader readonly='yes' type='pflash'>/usr/share/edk2-x86_64/OVMF_CODE.fd</loader>
  <nvram>/etc/libvirt/qemu/nvram/wafflosagus-ucore_VARS.fd</nvram>
  <boot enable='yes' order='1'/>
  <bootmenu enable='no'/>
  <kernel_args>ignition.config.url=https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign</kernel_args>
</os>
```

**Important**: The kernel_args line is what tells CoreOS to fetch ignition from GitHub.

5. Save the XML

### Phase 5: Boot and Monitor First Boot

1. Start the VM
2. Open VNC console to monitor boot process
3. Watch for:
   - Network initialization
   - Ignition message: "Fetching config from https://..."
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

4. Clean up kernel_args (optional but recommended):
   - Stop VM
   - Edit XML
   - Remove `ignition.config.url` from `<kernel_args>`
   - Ignition only runs on first boot, so this prevents unnecessary fetch attempts

5. Verify SSH access works reliably
6. You can now disable VNC if desired (headless operation confirmed)

## Alternative: Local Ignition File

If GitHub fetch fails or you prefer local configuration:

### When to Use Local Ignition
- Network is unreliable during first boot
- GitHub access is blocked or rate-limited
- Air-gapped environment
- Troubleshooting deployment issues

### Step 1: Prepare Local Ignition File

1. Create `/mnt/user/domains/ucore-vm.ign` with your ignition contents
2. Set SELinux label:
   ```bash
   chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

### Step 2: Edit VM XML for Local Ignition

Instead of kernel_args, add to end of XML (before `</domain>`):

```xml
<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:arg value='-fw_cfg'/>
  <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
</qemu:commandline>
```

### Step 3: Continue from Phase 5

Boot and monitor as described above. Everything else is identical.

## Troubleshooting

### Issue: Ignition fails to fetch from GitHub

**Symptoms:**
- Boot hangs or times out during ignition fetch
- "Failed to fetch config from URL" error
- Network connectivity issues during first boot

**Solutions:**
1. **Switch to local ignition** (see Alternative section above)
2. Check GitHub URL is correct and accessible from host
3. Verify GitHub repository is public
4. Check Unraid network bridge is functioning
5. Try alternative URL (e.g., GitHub Pages instead of raw.githubusercontent.com)

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
3. Verify service is enabled: `systemctl is-enabled rebase-to-wafflosagus.service`
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

### Issue: VNC Console Not Working

**Symptoms:**
- Can't connect to VNC
- Black screen in VNC
- VNC connection refused

**Solutions:**
1. Check VM is running
2. Verify VNC is enabled in VM settings
3. Try different VNC port
4. Check Unraid firewall settings
5. Ensure no GPU passthrough is interfering with VNC

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
└── ucore-vm.ign               # Local ignition file (if used)
```

## Quick Reference Commands

### From Unraid Host
```bash
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

## References

- [Fedora CoreOS Ignition Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/getting-started/)
- [BlueBuild Documentation](https://blue-build.org/)
- [Unraid VM Documentation](https://docs.unraid.net/unraid-os/using-unraid-to/create-virtual-machines/vm-setup/)
- [rpm-ostree Documentation](https://coreos.github.io/rpm-ostree/)

## Changelog

- 2025-01-10: Initial documentation created
  - GitHub URL-based ignition configuration
  - Comprehensive troubleshooting section
  - Alternative local ignition method documented
