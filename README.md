# wafflOSagus &nbsp; [![bluebuild build badge](https://github.com/waffleophagus/wafflosagus/actions/workflows/build.yml/badge.svg)](https://github.com/waffleophagus/wafflosagus/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

After setup, it is recommended you update this README to describe your custom image.

## Installation

> **Warning**  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/waffleophagus/wafflosagus:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Documentation

Complete documentation for deploying and managing wafflOSagus is available in the [docs/](docs/) directory:

- **[Unraid uCore VM Deployment](docs/unraid-ucore-deployment.md)** - Complete guide for headless VM setup (primary method)
- **[GitHub vs Local Ignition](docs/github-vs-local-ignition.md)** - Technical comparison and migration guide
- **[Quick Reference](docs/quick-reference.md)** - TL;DR command summary and common tasks
- **[Deployment Checklist](docs/deployment-checklist.md)** - Step-by-step verification and troubleshooting

### Quick Start for Unraid VM

**Note:** The recommended method uses local ignition file + fw_cfg for reliability with UEFI/OVMF bootloaders.

1. Download ignition file to Unraid:
   ```bash
   wget -O /mnt/user/domains/ucore-vm.ign \
     https://raw.githubusercontent.com/waffleophagus/wafflOSagus/main/ucore-vm.ign
   chcon --type svirt_home_t /mnt/user/domains/ucore-vm.ign
   ```

2. Create VM with: 4 CPU, 6GB RAM, 60GB disk, Q35 machine type, OVMF BIOS

3. Edit VM XML to add fw_cfg configuration:
   ```xml
   <qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
     <qemu:arg value='-fw_cfg'/>
     <qemu:arg value='name=opt/com.coreos/config,file=/mnt/user/domains/ucore-vm.ign'/>
   </qemu:commandline>
   ```

4. Boot VM - ignition will configure user and rebase to wafflOSagus
5. SSH as `clawdbot` after reboot

See [docs/unraid-ucore-deployment.md](docs/unraid-ucore-deployment.md) for full details and explanation of why this method is recommended.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/waffleophagus/wafflosagus
```
