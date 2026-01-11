# Switching to Local Ignition File

## When to Switch

Use this guide if GitHub URL-based ignition fails:

- Network issues during first boot
- GitHub rate limiting or access problems
- Ignition fetch times out or fails
- Need to troubleshoot deployment
- Air-gapped environment

## Quick Switch: GitHub → Local

### Step 1: Create Local Ignition File

Your ignition file should already exist in your repo. Copy it locally:

```bash
# From Unraid terminal
mkdir -p /mnt/user/domains
cat > /mnt/user/domains/ucore-vm.ign << 'EOF'
{
  "ignition": {
    "version": "3.4.0"
  },
  "passwd": {
    "users": [
      {
        "name": "clawdbot",
        "sshAuthorizedKeys": [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfWxLwuoAmPHoXS4OMdRNz+e4lisJedtm6ElSHLb5Q8 waffleophagus@gmail.com"
        ]
      }
    ]
  },
  "systemd": {
    "units": [
      {
        "name": "rebase-to-wafflosagus.service",
        "enabled": true,
        "contents": "[Unit]\nDescription=Rebase to wafflosagus image\nConditionPathExists=/etc/ignition-machine-config\nAfter=network-online.target\nWants=network-online.target\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus-ucore:latest\nExecStart=/usr/bin/systemctl reboot\n\n[Install]\nWantedBy=multi-user.target\n"
      }
    ]
  }
}
EOF
```

### Step 2: Set SELinux Label (Required for libvirt)

```bash
chcon --verbose --type svirt_home_t /mnt/user/domains/ucore-vm.ign
```

### Step 3: Edit VM XML

1. Stop the VM
2. Click VM → Edit XML
3. **Remove** the ignition.config.url from `<kernel_args>`:
   ```xml
   <!-- REMOVE this line: -->
   <!-- <kernel_args>ignition.config.url=https://raw.githubusercontent.com/...</kernel_args> -->
   ```

4. **Add** qemu:commandline at end of XML (before `</domain>`):
   ```xml
   <qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
     <qemu:arg value='-fw_cfg'/>
     <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
   </qemu:commandline>
   ```

5. Save XML

### Step 4: Boot VM

Boot normally. Ignition will now load from local file instead of GitHub.

## Quick Switch: Local → GitHub (Rollback)

If you want to switch back to GitHub method:

1. Stop VM
2. Edit XML
3. **Remove** qemu:commandline section:
   ```xml
   <!-- REMOVE entire qemu:commandline section -->
   ```
4. **Add** kernel_args back to `<os>` section:
   ```xml
   <kernel_args>ignition.config.url=https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign</kernel_args>
   ```
5. Save XML
6. Boot VM

## Comparison

| Aspect | GitHub URL | Local File |
|--------|-----------|------------|
| Network Dependency | Required during first boot | None |
| Initial Setup Complexity | Low (kernel_args) | Medium (fw_cfg + SELinux) |
| Updates | Push to GitHub | Edit on Unraid host |
| Troubleshooting | Network issues problematic | Easier to debug |
| Reliability | Depends on GitHub access | Higher |
| Portability | Works anywhere | File must be present on host |

## Common Issues

### SELinux Error

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

### fw_cfg Not Supported

**Error**: "fw_cfg device not available" (rare on modern systems)

**Solution**: Use kernel_args method instead (GitHub URL or HTTP server)

### File Path Issues

**Error**: Ignition can't find config file

**Check**:
```bash
# Verify file exists
ls -la /mnt/user/domains/ucore-vm.ign

# Verify path in XML matches actual location
grep -A1 "qemu:commandline" /etc/libvirt/qemu/wafflosagus-ucore.xml
```

## Hybrid Approach

For maximum reliability:

1. **Use local ignition** for critical first-boot configuration (user, rebase)
2. **Use remote ignition** inside local config for fetching additional configs:

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

This way:
- Critical boot config is local (no network dependency)
- Additional configs can be fetched from GitHub
- Best of both worlds

## Testing Ignition File

Before deploying to VM, validate your ignition file:

```bash
# Using Butane (if you have YAML)
butane --version

# Validate Ignition JSON
# No built-in validator, but you can check JSON syntax:
python3 -m json.tool /mnt/user/domains/ucore-vm.ign
```
