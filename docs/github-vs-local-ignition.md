# GitHub URL vs Local Ignition File

This document compares ignition delivery methods and explains the technical reasons for using local files.

## Method Comparison

| Method | Bootloader Compatibility | Complexity | Reliability | Network Dependency |
|--------|------------------------|------------|-------------|-------------------|
| **Local File + fw_cfg** | ✅ UEFI (OVMF) | Low | High | None |
| **GitHub URL (kernel_args)** | ❌ UEFI (OVMF) | Medium | Low | Required |
| **GitHub URL (grub)** | ✅ UEFI (OVMF) | Very High | Medium | Required |
| **PXE/DHCP** | ✅ Any | Very High | Low | Required |

## Why Local File is Recommended

### Technical Issue with kernel_args and UEFI

**The Problem:**
1. Unraid uses **OVMF (UEFI) bootloader** by default
2. When booting via UEFI bootloader, `<kernel_args>` in libvirt XML **is not effective**
3. UEFI bootloader handles kernel parameters, not libvirt XML
4. Libvirt validates against its schema, so Unraid might reject or silently ignore kernel_args

**Evidence:**
- Fedora CoreOS docs: `<kernel_args>` only works with **direct kernel boot** (explicit `<kernel>` and `<initrd>`)
- With UEFI/OVMF, bootloader (EDK2/grub) handles configuration
- Found Unraid forum thread: "QEMU Command line form not saved - no effect" (August 2024)
- This is a known limitation of libvirt XML with UEFI bootloaders

### Why fw_cfg Works

**QEMU Firmware Configuration Device (fw_cfg):**
1. Direct QEMU feature, not affected by UEFI bootloader
2. Works with any bootloader type (UEFI, SeaBIOS, direct kernel)
3. Well documented by Fedora CoreOS as recommended method
4. Simple - just two lines in VM XML
5. Standard across platforms (QEMU, libvirt, Proxmox, VMware)

## Methods Explained

### Method 1: Local File + fw_cfg (Recommended)

**How it works:**
- QEMU's fw_cfg device passes data to guest firmware
- CoreOS ignition reads from `opt/com.coreos/config` fw_cfg entry
- No bootloader modification required
- Works identically across all hypervisors

**Setup:**
```xml
<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  <qemu:arg value='-fw_cfg'/>
  <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
</qemu:commandline>
```

**Pros:**
- ✅ Works with UEFI/OVMF (Unraid default)
- ✅ Simple setup (2 XML lines)
- ✅ Well documented (Fedora CoreOS standard)
- ✅ High reliability
- ✅ No network dependency during boot
- ✅ Easy troubleshooting

**Cons:**
- ⚠️  Must update file on Unraid host
- ⚠️  SELinux context required
- ⚠️  Single ignition run (first-boot only)

### Method 2: kernel_args + GitHub URL (Doesn't Work with UEFI)

**Why it fails:**
- `<kernel_args>` in libvirt XML is only effective with direct kernel boot
- UEFI bootloader (OVMF) ignores these parameters
- Unraid's XML editor might not preserve them (seen in forums)
- CoreOS never receives the ignition URL

**What would be needed:**
- Modify UEFI NVRAM directly
- Or inject into bootloader configuration (EDK2/grub)
- Or use direct kernel boot instead of UEFI (breaks other things)

**Conclusion:** Not viable for Unraid UEFI/OVMF setups.

### Method 3: Hybrid Approach (Local + GitHub Fetch)

**How it works:**
1. Use local fw_cfg method (reliable first-boot)
2. Local ignition fetches additional config from GitHub
3. Best of both worlds: local reliability + remote updates

**Setup:**
```json
{
  "ignition": {
    "version": "3.4.0",
    "config": {
      "merge": [
        {
          "source": "https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/extra-config.ign"
        }
      ]
    }
  },
  ...
}
```

**Pros:**
- ✅ Reliable first-boot (local fw_cfg)
- ✅ Can update configs via GitHub
- ✅ Works with UEFI/OVMF

**Cons:**
- ⚠️  More complex (two-stage config)
- ⚠️  Still network dependency for GitHub fetch
- ⚠️  More moving parts to debug

## SELinux Context Requirements

When using local file method, SELinux context is critical:

```bash
# Check current context
ls -Z /mnt/user/domains/ucore-vm.ign

# If wrong, fix it
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify correct
ls -Z /mnt/user/domains/ucore-vm.ign
# Should show: svirt_home_t
```

**Why required:**
- Libvirt runs with SELinux confinement
- QEMU process needs specific context to read files
- Wrong context causes "Permission denied" during boot
- Ignition fails silently if can't access config

## Migration Guide: GitHub URL → Local File

### Step 1: Remove GitHub Configuration

1. Stop VM
2. Edit XML
3. Remove kernel_args line (if exists):
   ```xml
   <!-- Remove this line -->
   <!-- <kernel_args>ignition.config.url=https://...</kernel_args> -->
   ```

### Step 2: Download Ignition Locally

```bash
# Download to Unraid
wget -O /mnt/user/domains/ucore-vm.ign \
  https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign

# Set SELinux label
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign

# Verify
ls -Z /mnt/user/domains/ucore-vm.ign
```

### Step 3: Add fw_cfg Configuration

1. Edit VM XML
2. Add at end of XML, before `</domain>`:
   ```xml
   <qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
     <qemu:arg value='-fw_cfg'/>
     <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
   </qemu:commandline>
   ```

### Step 4: Boot and Verify

- Start VM
- Watch VNC console for ignition message
- Verify user created and rebase completed
- Test SSH access

## FAQ

### Q: Can I use GitHub URLs at all?

**A:** Yes, but via hybrid approach:
1. Use local fw_cfg for first-boot reliability
2. Local ignition fetches additional configs from GitHub
3. See "Hybrid Approach" section above

### Q: Why not modify UEFI NVRAM directly?

**A:** Possible but not recommended:
- Complex and fragile
- Difficult to troubleshoot
- Changes might be overwritten by Unraid
- fw_cfg is simpler and standard

### Q: What if I need to update ignition frequently?

**A:** For frequent updates, consider:
1. Hybrid approach (local fw_cfg + GitHub fetch)
2. Or use script to download and update local file
3. Or create new VM for each major configuration change

### Q: Can I test ignition file before deploying?

**A:** Validate JSON syntax:
```bash
python3 -m json.tool /mnt/user/domains/ucore-vm.ign
```

No built-in Ignition validator, but syntax check helps catch obvious errors.

### Q: Why did kernel_args work in other setups?

**A:** Works when:
- Using direct kernel boot (not UEFI)
- Booting via PXE with kernel parameters
- Using bootloader that respects libvirt kernel_args

With Unraid's OVMF UEFI bootloader, this doesn't work.

## Recommendations

### For Production
- Use local file + fw_cfg method
- Set SELinux context correctly
- Test in disposable VM first
- Keep ignition file in version control (GitHub)
- Download fresh for each new deployment

### For Development/Testing
- Consider hybrid approach if frequent updates needed
- Use local file for base configuration
- Fetch experimental configs from GitHub
- Keep detailed logs for debugging

### For Multiple VMs
- Store ignition files in central location on Unraid
- Create script to download and configure multiple VMs
- Use snapshots to preserve working states
- Document each VM's ignition requirements

## References

- [Fedora CoreOS Provisioning on QEMU](https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-qemu/)
- [libvirt XML Format](https://libvirt.org/formatdomain.html)
- [QEMU fw_cfg Documentation](https://www.qemu.org/docs/master/system/qemu-cmds.html)
- [Unraid Forums: QEMU Command Line Issues](https://forums.unraid.net/topic/174051-qemu-command-line-form-not-saved-no-effect/)
