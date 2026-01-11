# Unraid uCore VM Deployment Checklist

## Phase 1: Pre-Deployment

- [ ] Unraid 7.x is installed and running
- [ ] KVM virtualization is enabled
- [ ] Base qcow2 image is downloaded
- [ ] `ucore-vm.ign` exists in repository
- [ ] SSH key for `clawdbot` is known

## Phase 2: Prepare Ignition File Locally

- [ ] Download ignition file to Unraid:
  ```bash
  wget -O /mnt/user/domains/ucore-vm.ign \
    https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
  ```

- [ ] Set SELinux label (REQUIRED):
  ```bash
  chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
  ```

- [ ] Verify file and SELinux context:
  ```bash
  ls -Z /mnt/user/domains/ucore-vm.ign
  ```

- [ ] Confirm context shows: `svirt_home_t`

## Phase 3: File Preparation

- [ ] Copy base qcow2 to `/mnt/user/domains/fedora-coreos-base.qcow2`
- [ ] Verify qcow2 file exists: `ls -la /mnt/user/domains/fedora-coreos-base.qcow2`
- [ ] Verify ignition file exists: `ls -la /mnt/user/domains/ucore-vm.ign`

## Phase 4: VM Creation

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

## Phase 5: Configure Ignition (fw_cfg Method)

- [ ] Stop VM (if running)
- [ ] Click VM → Edit XML
- [ ] Scroll to end of XML, locate `</domain>` closing tag
- [ ] Add qemu:commandline section before `</domain>`:
  ```xml
  <qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
    <qemu:arg value='-fw_cfg'/>
    <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
  </qemu:commandline>
  ```
- [ ] Verify placement is AFTER `<devices>` section
- [ ] Save XML
- [ ] Verify XML syntax is correct (no validation errors)

## Phase 6: First Boot

- [ ] Start VM
- [ ] Open VNC console to monitor boot
- [ ] Watch for Ignition message: "Applying config from fw_cfg"
- [ ] Confirm: "Ignition: applied config successfully"
- [ ] Wait for rebase to complete
- [ ] Confirm auto-reboot message
- [ ] System reboots automatically
- [ ] Wait for second boot to complete

## Phase 7: Post-Boot Verification

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

## Phase 8: Cleanup

- [ ] Stop VM
- [ ] Edit VM XML
- [ ] Remove `<qemu:commandline>` section:
  ```xml
  <!-- Remove entire qemu:commandline section -->
  ```
- [ ] Save XML
- [ ] Start VM to verify clean boot
- [ ] Verify no ignition errors in VNC console

## Phase 9: Optional: Create Baseline Snapshot

- [ ] Stop VM
- [ ] Navigate to VM → Snapshots
- [ ] Click Create Snapshot
- [ ] Name: "baseline-wafflosagus"
- [ ] Description: "Clean install of wafflOSagus uCore"
- [ ] Click Create
- [ ] Verify snapshot appears in list

## Troubleshooting: Ignition Issues

### Ignition Fails to Load

- [ ] Check VNC console for error messages
- [ ] Verify ignition file exists:
  ```bash
  ls -la /mnt/user/domains/ucore-vm.ign
  ```

- [ ] Check SELinux context:
  ```bash
  ls -Z /mnt/user/domains/ucore-vm.ign
  ```
  Should show: `svirt_home_t`

- [ ] Fix SELinux context if wrong:
  ```bash
  chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
  ```

- [ ] Verify qemu:commandline in XML:
  ```bash
  grep -A3 "qemu:commandline" /etc/libvirt/qemu/wafflosagus-ucore.xml
  ```

- [ ] Check XML placement: Must be before `</domain>`

### SELinux Denials

- [ ] Check for AVC denials:
  ```bash
  sudo journalctl -xe | grep AVC
  ```

- [ ] If SELinux issues, try:
  ```bash
  setenforce 0  # Temporary (not recommended)
  setenforce 1  # Re-enable after boot
  ```

### fw_cfg Issues

- [ ] Verify fw_cfg line format in XML
- [ ] Check for syntax errors
- [ ] Try restarting libvirt:
  ```bash
  systemctl restart libvirtd
  ```

## Troubleshooting: Rebase Issues

### Rebase Fails

- [ ] Check journal logs:
  ```bash
  journalctl -u rebase-to-wafflosagus.service
  ```

- [ ] Verify network connectivity from VM
- [ ] Check image URL is correct:
  ```
  ghcr.io/waffleophagus/wafflosagus-ucore:latest
  ```

- [ ] Try manual rebase from console:
  ```bash
  sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus-ucore:latest
  ```

- [ ] Check `/var/log/messages` for detailed errors
- [ ] Verify container registry is accessible from VM

## Troubleshooting: SSH Issues

### SSH Access Fails

- [ ] Verify user exists: `id clawdbot`
- [ ] Check SSH key in `~/.ssh/authorized_keys`
- [ ] Check sshd service: `systemctl status sshd`
- [ ] Verify network is up: `ip addr show`
- [ ] Try VNC console for direct access
- [ ] Check firewall rules if applicable
- [ ] Verify VM network bridge is correct

## Troubleshooting: Boot Issues

### System Doesn't Boot

- [ ] Check VNC console for error messages
- [ ] Verify qcow2 image is valid
- [ ] Check disk size and format
- [ ] Verify backing store path is correct
- [ ] Try different machine type (Q35)
- [ ] Check OVMF BIOS is selected

### Auto-Reboot Fails

- [ ] Check service logs:
  ```bash
  journalctl -u rebase-to-wafflosagus.service
  ```

- [ ] Manually reboot if service failed: `sudo systemctl reboot`

- [ ] Verify service is enabled:
  ```bash
  systemctl is-enabled rebase-to-wafflosagus.service
  ```

## Completion Checklist

- [ ] VM boots successfully
- [ ] Ignition applied configuration
- [ ] User clawdbot created
- [ ] Rebase to wafflOSagus completed
- [ ] Auto-reboot occurred
- [ ] SSH as `clawdbot` works
- [ ] `rpm-ostree status` shows correct image
- [ ] Network connectivity verified
- [ ] qemu:commandline removed from XML
- [ ] Baseline snapshot created (optional)
- [ ] System update tested

## Post-Deploy Notes

### First Time Setup

After successful deployment, consider:
- [ ] Setting up firewall rules
- [ ] Configuring Tailscale (if needed)
- [ ] Setting up SSH key management
- [ ] Documenting any custom configurations
- [ ] Creating backup strategy

### Ongoing Maintenance

- [ ] Schedule regular updates via `rpm-ostree upgrade`
- [ ] Keep backups/snapshots before major changes
- [ ] Monitor disk space usage
- [ ] Review logs periodically
- [ ] Keep ignition file updated for future deployments

## Quick Reference Files

- **Full Guide**: [docs/unraid-ucore-deployment.md](docs/unraid-ucore-deployment.md)
- **Quick Reference**: [docs/quick-reference.md](docs/quick-reference.md)
- **This Checklist**: [docs/deployment-checklist.md](docs/deployment-checklist.md)
- **Docs Index**: [docs/README.md](docs/README.md)

## Success Indicators

You're done when:
- ✅ You can SSH as `clawdbot`
- ✅ `rpm-ostree status` shows wafflOSagus
- ✅ No ignition errors in VNC console
- ✅ Network connectivity works
- ✅ System updates via rpm-ostree
- ✅ Ignition config removed from XML
- ✅ SELinux context correct on ignition file

## Contact & Support

- **BlueBuild Docs**: https://blue-build.org/
- **Unraid Forums**: https://forums.unraid.net/
- **Fedora CoreOS**: https://docs.fedoraproject.org/en-US/fedora-coreos/
- **GitHub Issues**: https://github.com/waffleophagus/wafflOSagus/issues
