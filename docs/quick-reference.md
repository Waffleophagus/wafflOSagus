# wafflOSagus uCore Unraid VM - Quick Reference

## TL;DR Command Summary

### Unraid Host (Ignition Setup)
```bash
# Download ignition file
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux label (REQUIRED)
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify file and SELinux context
ls -Z /mnt/user/domains/ucore-vm.ign
```

### Unraid Host (VM Management)
```bash
# VM management
virsh start wafflosagus-ucore           # Start VM
virsh shutdown wafflosagus-ucore        # Stop VM gracefully
virsh destroy wafflosagus-ucore         # Force stop
virsh edit wafflosagus-ucore            # Edit XML
virsh list --all                      # List all VMs
```

### Inside VM (clawdbot@vm)
```bash
# System management
rpm-ostree status                   # Check deployment
rpm-ostree upgrade                   # Update system
sudo systemctl reboot                  # Reboot
sudo journalctl -u <service>          # Check service logs

# Verify wafflOSagus image
cat /etc/os-release                   # Should show wafflOSagus
```

## Local File Method (Primary)

### VM XML Addition

Add at end of XML, before `</domain>`:
```xml
<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:arg value='-fw_cfg'/>
  <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
</qemu:commandline>
```

### Ignition File Setup
```bash
# Download from GitHub
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux label
chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify
ls -Z /mnt/user/domains/ucore-vm.ign
```

### Pros/Cons
- ✅ No network dependency during boot
- ✅ Works with UEFI/OVMF bootloader
- ✅ High reliability
- ✅ Well documented (Fedora CoreOS standard)
- ⚠️  Must update file on Unraid host
- ⚠️  SELinux context required

## Alternative: GitHub URL (Not Recommended)

### Why Not Recommended
- UEFI/OVMF bootloader doesn't pass kernel_args from libvirt XML
- `ignition.config.url` kernel parameter doesn't work with UEFI boot
- Requires complex bootloader configuration or hybrid approach
- See `docs/unraid-ucore-deployment.md` for hybrid alternative

## VM Settings

| Setting | Value |
|---------|-------|
| Name | wafflosagus-ucore |
| CPU | 4 cores |
| RAM | 6 GB |
| Disk | 60 GB QCOW2 |
| Machine | Q35 |
| BIOS | OVMF (UEFI) |
| Graphics | VNC |
| Network | br0 (VirtIO) |

## Ignition Configuration

### Current Setup
- User: `clawdbot`
- SSH Key: `waffleophagus@gmail.com`
- Rebase Target: `ghcr.io/waffleophagus/wafflosagus-ucore:latest`
- Auto-Reboot: Yes

### What Ignition Does
1. Creates user `clawdbot` with SSH key
2. Enables systemd service: `rebase-to-wafflosagus.service`
3. On first boot, rebases to wafflOSagus image
4. Auto-reboots into new image
5. Ignition runs ONLY on first boot

## Boot Sequence

### First Boot (With Ignition)
1. VM boots from base qcow2
2. Ignition loads from fw_cfg
3. User `clawdbot` created
4. Rebase service starts
5. `rpm-ostree rebase` runs
6. System auto-reboots
7. Boot into wafflOSagus image

### Normal Boot (Post-Deployment)
1. VM boots from wafflOSagus image
2. Ignition skipped (first-boot only)
3. System ready for SSH access

## Troubleshooting Quick Fixes

### Ignition Not Applying
- Check file exists: `ls -la /mnt/user/domains/ucore-vm.ign`
- Check SELinux context: `ls -Z /mnt/user/domains/ucore-vm.ign`
- Fix SELinux: `chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign`
- Check fw_cfg in XML: `grep -A3 "qemu:commandline" /etc/libvirt/qemu/wafflosagus-ucore.xml`
- Verify XML placement: Must be before `</domain>`

### Rebase Fails
- Check network connectivity
- Verify container registry URL
- Check logs: `journalctl -u rebase-to-wafflosagus.service`
- Try manual rebase from console
- Verify SELinux context on ignition file

### SSH Not Working
- Verify user exists: `id clawdbot`
- Check SSH key in `~/.ssh/authorized_keys`
- Check sshd service: `systemctl status sshd`
- Verify network: `ip addr show`

### SELinux Errors
**Error**: "Permission denied" accessing ignition file

**Fix**:
```bash
# Check SELinux context
ls -Z /mnt/user/domains/ucore-vm.ign

# Fix context
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# If that fails, try disabling SELinux temporarily (not recommended):
setenforce 0
# Then re-enable after boot:
setenforce 1
```

### Network Issues
- Check bridge: `brctl show`
- Verify VM network model: VirtIO
- Check firewall rules if applicable
- Try pinging from VM: `ping 8.8.8.8`

## Common Commands Cheat Sheet

### Unraid Host
```bash
# Check VM status
virsh list

# View console
virsh console wafflosagus-ucore

# Edit XML
virsh edit wafflosagus-ucore

# Restart VM
virsh reboot wafflosagus-ucore

# Delete VM (careful!)
virsh undefine wafflosagus-ucore
```

### Inside VM
```bash
# Check OS version
cat /etc/os-release

# Check disk space
df -h

# Check running processes
top

# Check system logs
sudo journalctl -xe

# Check network
ip addr show
ip route show
```

## File Locations

```
/mnt/user/domains/
├── wafflosagus-ucore/
│   ├── vdisk1.img
│   └── wafflosagus-ucore_VARS.fd
├── fedora-coreos-base.qcow2
└── ucore-vm.ign
```

## URLs

- **Full Documentation**: `/docs/unraid-ucore-deployment.md`
- **Deployment Checklist**: `/docs/deployment-checklist.md`
- **GitHub Repo**: https://github.com/waffleophagus/wafflOSagus
- **Container Registry**: ghcr.io/waffleophagus/wafflosagus-ucore

## Key Points to Remember

1. **Ignition only runs on first boot** - won't reapply after
2. **fw_cfg is required** - UEFI doesn't support kernel_args from libvirt XML
3. **SELinux context is critical** - must be `svirt_home_t`
4. **Auto-reboot is part of design** - system will restart automatically
5. **Rebase is one-time operation** - updates use `rpm-ostree upgrade`
6. **SSH is primary access method** - VNC for troubleshooting only
7. **wafflOSagus image is immutable** - layered via rpm-ostree
8. **Local file is more reliable** than GitHub URL approach

## Post-Deploy Checklist

- [ ] Verify VM boots successfully
- [ ] SSH as clawdbot works
- [ ] `rpm-ostree status` shows wafflOSagus image
- [ ] Network connectivity works (ping external host)
- [ ] Remove qemu:commandline from XML (cleanup)
- [ ] Test system update: `rpm-ostree upgrade`
- [ ] Create snapshot for rollback safety
- [ ] Document any custom configurations

## Updating Ignition

To update ignition configuration:

```bash
# Download new version
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux label
chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify
ls -Z /mnt/user/domains/ucore-vm.ign
```

Note: Ignition only runs on first boot, so this only affects new VM deployments.

## Support Resources

- [Fedora CoreOS Docs](https://docs.fedoraproject.org/en-US/fedora-coreos/)
- [BlueBuild Docs](https://blue-build.org/)
- [Unraid Forums](https://forums.unraid.net/)
- [Ignition Spec](https://coreos.github.io/ignition/)
