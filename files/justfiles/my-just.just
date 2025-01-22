# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
jetbrains-toolbox:
  #!/usr/bin/env bash
  BUILD_VERSION="2.0.2.16660"
  echo "Installing JetBrains Toolbox"
  pushd "$(mktemp -d)"
  curl -sSfL -O https://download.jetbrains.com/toolbox/jetbrains-toolbox-$BUILD_VERSION.tar.gz
  curl -sSfL https://download.jetbrains.com/toolbox/jetbrains-toolbox-$BUILD_VERSION.tar.gz.sha256 | sha256sum -c
  tar zxf jetbrains-toolbox-$BUILD_VERSION.tar.gz
  echo "Launching JetBrains Toolbox"
  ./jetbrains-toolbox-$BUILD_VERSION/jetbrains-toolbox
  
# Build my ubuntu
assemble-my-distrobox:
  distrobox assemble create --replace --file /usr/etc/distrobox/distrobox.ini
  
# Install nix and Devbox
nix-devbox:
  echo 'Setting phasers to kill. Installing nix.'
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  echo 'Installing devbox!'
  curl -fsSL https://get.jetpack.io/devbox | bash
  echo 'You MUST reboot to continue'
  
distrobox-assemble:
  distrobox assemble create --file /usr/etc/distrobox/distrobox.ini


  #Start the podman socket (User)
podman-socket:
  systemctl --user start podman.socket
  
#Install ArcDPS for GW2
arcDPS-install:
   wget -O ~/.local/share/Steam/steamapps/common/Guild\ Wars\ 2/d3d11.dll https://www.deltaconnected.com/arcdps/x64/d3d11.dll
   
#Delete ArcDPS for GW2
arcDPS-remove: 
   rm ~/.local/share/Steam/steamapps/common/Guild\ Wars\ 2/d3d11.dll

#Bluefin
rebase-bluefin:
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus-bluefin-dx:latest
   
#Bazzite
rebase-bazzite:
   rpm-ostree rebase ostree-image-signed:docker://ghcr.io/waffleophagus/wafflosagus-bazzite:latest

# Ptyxis terminal transparency
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
      printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>{{ opacity }}" | bc -q) -eq 1 ]]; then
      raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
      uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
      for i in ${uuids}; do
        location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
        gsettings set "${location}" opacity "{{ opacity }}"; done
      printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
      printf "Value must be between 0 and 1: %s.\n" "{{ opacity }}"
    fi
    
    
# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    echo "Launching JetBrains Toolbox"
    ./jetbrains-toolbox-"${BUILD_VERSION}"/jetbrains-toolbox
    
