# wafflOSagus uCore Unraid VM - Quick Reference

## TL;DR Command Summary

### From Unraid Host
```bash
# VM management
virsh start wafflosagus-ucore           # Start VM
virsh shutdown wafflosagus-ucore        # Stop VM gracefully
virsh destroy wafflosagus-ucore         # Force stop
virsh edit wafflosagus-ucore            # Edit XML
virsh list --all                      # List all VMs

# File setup (for local ignition)
chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign
```

### From Inside VM (clawdbot@vm)
```bash
# System management
rpm-ostree status                   # Check deployment
rpm-ostree upgrade                   # Update system
sudo systemctl reboot                  # Reboot
sudo journalctl -u <service>          # Check service logs

# Verify wafflOSagus image
cat /etc/os-release                   # Should show wafflOSagus
```

## GitHub URL Method (Primary)

### VM XML Additions

Add to `<os>` section:
```xml
<kernel_args>ignition.config.url=https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign</kernel_args>
```

### Ignition File Location
```
https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
```

### Pros/Cons
- ✅ Simple setup, single kernel arg
- ✅ Easy to update via Git push
- ⚠️  Requires network on first boot
- ⚠️  GitHub rate limits possible

## Local File Method (Fallback)

### VM XML Additions

Add before `</domain>`:
```xml
<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:arg value='-fw_cfg'/>
  <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
</qemu:commandline>
```

### File Setup
```bash
# Create file
cat > /mnt/user/domains/ucore-vm.ign << 'EOF'
{...ignition JSON...}
EOF

# Set SELinux label
chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign
```

### Pros/Cons
- ✅ No network dependency
- ✅ Higher reliability
- ⚠️  Must update file on Unraid host
- ⚠️  SELinux context required

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
2. Network initializes
3. Ignition fetches config (GitHub) or loads (local)
4. User `clawdbot` created
5. Rebase service starts
6. `rpm-ostree rebase` runs
7. System auto-reboots
8. Boot into wafflOSagus image

### Normal Boot (Post-Deployment)
1. VM boots from wafflOSagus image
2. Ignition skipped (first-boot only)
3. System ready for SSH access

## Troubleshooting Quick Fixes

### Ignition Not Applying
- Check kernel_args or fw_cfg syntax
- Verify file paths are correct
- Check VNC console for error messages
- Try switching ignition method (GitHub ↔ local)

### Rebase Fails
- Check network connectivity
- Verify container registry URL
- Check logs: `journalctl -u rebase-to-wafflosagus`
- Try manual rebase from console

### SSH Not Working
- Verify user exists: `id clawdbot`
- Check SSH key in `~/.ssh/authorized_keys`
- Check sshd service: `systemctl status sshd`
- Verify network: `ip addr show`

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
└── ucore-vm.ign (local method only)
```

## URLs

- **Documentation**: `/docs/unraid-ucore-deployment.md`
- **Local Ignition Alternative**: `/docs/local-ignition-alternative.md`
- **GitHub Repo**: https://github.com/waffleophagus/wafflOSagus
- **Container Registry**: ghcr.io/waffleophagus/wafflosagus-ucore

## Key Points to Remember

1. **Ignition only runs on first boot** - won't reapply after
2. **Auto-reboot is part of design** - system will restart automatically
3. **GitHub method requires network** - use local fallback if issues
4. **Rebase is one-time operation** - updates use `rpm-ostree upgrade`
5. **SSH is primary access method** - VNC for troubleshooting only
6. **Snapshots work after deployment** - not during ignition phase
7. **wafflOSagus image is immutable** - layered via rpm-ostree

## Post-Deploy Checklist

- [ ] Verify VM boots successfully
- [ ] SSH as clawdbot works
- [ ] `rpm-ostree status` shows wafflOSagus image
- [ ] Network connectivity works (ping external host)
- [ ] Remove ignition config from XML (cleanup)
- [ ] Test system update: `rpm-ostree upgrade`
- [ ] Create snapshot for rollback safety
- [ ] Document any custom configurations

## Support Resources

- [Fedora CoreOS Docs](https://docs.fedoraproject.org/en-US/fedora-coreos/)
- [BlueBuild Docs](https://blue-build.org/)
- [Unraid Forums](https://forums.unraid.net/)
- [Ignition Spec](https://coreos.github.io/ignition/)
