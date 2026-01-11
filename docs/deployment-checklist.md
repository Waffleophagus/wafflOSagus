# Unraid uCore VM Deployment Checklist

## Phase 1: Pre-Deployment

- [ ] Unraid 7.x is installed and running
- [ ] KVM virtualization is enabled
- [ ] Base qcow2 image is downloaded
- [ ] `ucore-vm.ign` exists in repository
- [ ] SSH key for `clawdbot` is known

## Phase 2: File Preparation

- [ ] Copy base qcow2 to `/mnt/user/domains/fedora-coreos-base.qcow2`
- [ ] Verify `ucore-vm.ign` is accessible at:
  ```
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
  ```
- [ ] Test GitHub URL is accessible from host:
  ```bash
  curl -I https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
  ```

## Phase 3: VM Creation

- [ ] Navigate to Virtual Machines → Add VM in Unraid
- [ ] Select Custom template
- [ ] Set Name: `wafflosagus-ucore`
- [ ] Set CPU: 4 cores
- [ ] Set Memory: 6 GB
- [ ] Set Machine Type: Q35
- [ ] Set BIOS Type: OVMF (UEFI)
- [ ] Set OS Type: Linux / Fedora
- [ ] Configure Primary vDisk: 60 GB, QCOW2 format
- [ ] Set vDisk backing store to: `/mnt/user/domains/fedora-coreos-base.qcow2`
- [ ] Set Graphics: VNC
- [ ] Set Network: br0 (VirtIO)
- [ ] Click Create VM

## Phase 4: Ignition Configuration (GitHub URL Method)

- [ ] Stop the VM (if running)
- [ ] Click VM → Edit XML
- [ ] Locate `<os>` section in XML
- [ ] Add kernel_args line:
  ```xml
  <kernel_args>ignition.config.url=https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign</kernel_args>
  ```
- [ ] Save XML
- [ ] Verify XML syntax is correct

## Phase 5: First Boot

- [ ] Start the VM
- [ ] Open VNC console to monitor boot
- [ ] Watch for network initialization
- [ ] Confirm Ignition message appears
- [ ] Watch for "Ignition: applied config successfully"
- [ ] Wait for rebase to complete
- [ ] Confirm auto-reboot message
- [ ] System reboots automatically
- [ ] Wait for second boot to complete

## Phase 6: Post-Boot Verification

- [ ] SSH as `clawdbot`:
  ```bash
  ssh clawdbot@<vm-ip>
  ```
- [ ] Verify user exists:
  ```bash
  id clawdbot
  ```
- [ ] Check OS version:
  ```bash
  cat /etc/os-release
  ```
- [ ] Verify wafflOSagus image:
  ```bash
  rpm-ostree status
  ```
  Should show: `ghcr.io/waffleophagus/wafflosagus-ucore:latest`
- [ ] Check network connectivity:
  ```bash
  ping 8.8.8.8
  ```
- [ ] Test system update:
  ```bash
  sudo rpm-ostree upgrade
  ```

## Phase 7: Cleanup

- [ ] Stop the VM
- [ ] Edit VM XML
- [ ] Remove ignition.config.url from `<kernel_args>`
  ```xml
  <!-- Remove this line after successful deployment -->
  <!-- <kernel_args>ignition.config.url=...</kernel_args> -->
  ```
- [ ] Save XML
- [ ] Start VM to verify clean boot

## Phase 8: Optional: Create Baseline Snapshot

- [ ] Stop the VM
- [ ] Navigate to VM → Snapshots
- [ ] Click Create Snapshot
- [ ] Name: "baseline-wafflosagus"
- [ ] Description: "Clean install of wafflOSagus uCore"
- [ ] Click Create
- [ ] Verify snapshot appears in list

## Troubleshooting: If Issues Arise

### Ignition Fails to Load

- [ ] Check VNC console for error messages
- [ ] Verify GitHub URL is correct
- [ ] Test URL accessibility from host:
  ```bash
  curl https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
  ```
- [ ] If GitHub fails, switch to local ignition method:
  - See [docs/local-ignition-alternative.md](docs/local-ignition-alternative.md)
  - Create local file at `/mnt/user/domains/ucore-vm.ign`
  - Set SELinux label: `chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign`
  - Edit VM XML to use qemu:commandline with fw_cfg

### Rebase Fails

- [ ] Check journal logs:
  ```bash
  journalctl -u rebase-to-wafflosagus.service
  ```
- [ ] Verify network connectivity
- [ ] Check image URL is correct:
  ```
  ghcr.io/waffleophagus/wafflosagus-ucore:latest
  ```
- [ ] Try manual rebase from console
- [ ] Check `/var/log/messages` for detailed errors

### SSH Access Fails

- [ ] Verify user exists: `id clawdbot`
- [ ] Check SSH key in `~/.ssh/authorized_keys`
- [ ] Check sshd service: `systemctl status sshd`
- [ ] Verify network is up: `ip addr show`
- [ ] Try VNC console for direct access

### System Doesn't Reboot After Rebase

- [ ] Check service logs:
  ```bash
  journalctl -u rebase-to-wafflosagus.service
  ```
- [ ] Manually reboot: `sudo systemctl reboot`
- [ ] Verify service is enabled:
  ```bash
  systemctl is-enabled rebase-to-wafflosagus.service
  ```

## Completion Checklist

- [ ] VM boots successfully
- [ ] Ignition applied configuration
- [ ] Rebase to wafflOSagus completed
- [ ] Auto-reboot occurred
- [ ] SSH as `clawdbot` works
- [ ] `rpm-ostree status` shows correct image
- [ ] Network connectivity verified
- [ ] Ignition config removed from XML
- [ ] Baseline snapshot created (optional)
- [ ] System update tested

## Post-Deploy Notes

### First Time Setup

After successful deployment, consider:
- [ ] Setting up firewall rules
- [ ] Configuring Tailscale (if needed)
- [ ] Setting up SSH key management
- [ ] Documenting any custom configurations

### Ongoing Maintenance

- [ ] Schedule regular updates via `rpm-ostree upgrade`
- [ ] Keep backups/snapshots before major changes
- [ ] Monitor disk space usage
- [ ] Review logs periodically

## Quick Reference Files

- **Full Guide**: [docs/unraid-ucore-deployment.md](docs/unraid-ucore-deployment.md)
- **Quick Reference**: [docs/quick-reference.md](docs/quick-reference.md)
- **Local Ignition Alt**: [docs/local-ignition-alternative.md](docs/local-ignition-alternative.md)
- **This Checklist**: [docs/deployment-checklist.md](docs/deployment-checklist.md)

## Success Indicators

You're done when:
- ✅ You can SSH as `clawdbot`
- ✅ `rpm-ostree status` shows wafflOSagus
- ✅ No ignition errors in VNC console
- ✅ Network connectivity works
- ✅ System updates via rpm-ostree

## Contact & Support

- **BlueBuild Docs**: https://blue-build.org/
- **Unraid Forums**: https://forums.unraid.net/
- **Fedora CoreOS**: https://docs.fedoraproject.org/en-US/fedora-coreos/
- **GitHub Issues**: https://github.com/waffleophagus/wafflOSagus/issues
