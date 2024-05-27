#!/bin/sh
# Void Linux Post-Installation Script for Wayland
# Author: Speyll
# Last-update: 03-04-2024

# Enable debugging output and exit on error
set -x

# Add multilib and nonfree repositories
sudo xbps-install -Sy void-repo-nonfree

# Update package lists and upgrade existing packages
sudo xbps-install -Syu

# Install GPU drivers
install_gpu_driver() {
  gpu_driver=""
  case "$(lspci | grep -E 'VGA|3D')" in
    *Intel*) gpu_driver="mesa-dri intel-video-accel vulkan-loader mesa-vulkan-intel" ;;
    *AMD*)   gpu_driver="mesa-dri mesa-vaapi mesa-vdpau vulkan-loader mesa-vulkan-radeon" ;;
    *NVIDIA*)gpu_driver="mesa-dri nvidia nvidia-libs-32bit" ;;
  esac
  for pkg in $gpu_driver; do
    [ -n "$pkg" ] && sudo xbps-install -y "$pkg"
  done
}

install_gpu_driver

# Install CPU microcode updates
if lspci | grep -q 'Intel'; then
  sudo xbps-install -y intel-ucode
  sudo xbps-reconfigure -f linux-$(uname -r)
fi

# Install other packages
install_packages() {
  sudo xbps-install -y \
    git wayland dbus dbus-glib curl elogind polkit-elogind \
    xdg-utils xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-desktop-portal \
    pipewire gstreamer1-pipewire libspa-bluetooth pavucontrol \
    noto-fonts-emoji noto-fonts-ttf font-inconsolata-otf font-awesome \
    grim slurp wl-clipboard cliphist \
    qimgv swaybg mpv ffmpeg \
    mako libnotify \
    nnn unzip p7zip unrar pcmanfm-qt ffmpegthumbnailer lxqt-archiver gvfs-smb gvfs-afc gvfs-mtp udisks2 \
    breeze-gtk breeze-snow-cursor-theme breeze-icons \
    qt5-wayland wireguard bluez \
    sway nano foot Waybar wlsunset tofi brightnessctl labwc nwg-look kvantum vscode
}

#Install Flatpak

  sudo xbps-install -y flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub io.gitlab.librewolf-community
  flatpak install flathub net.cozic.joplin_desktop
  flatpak install flathub io.github.shiftey.Desktop

#Install Bun
  curl -fsSL https://bun.sh/install | bash

# Set up PipeWire autostart
sudo ln -s /usr/share/applications/pipewire.desktop /etc/xdg/autostart/pipewire.desktop

# Set up elogind
sudo ln -s /etc/sv/elogind /var/service/

# Set up bluetooth autostart
sudo ln -s /etc/sv/bluetoothd /var/service/

# Remove unused services (TTYs)
sudo rm -rf /var/service/agetty-tty3
sudo rm -rf /var/service/agetty-tty4
sudo rm -rf /var/service/agetty-tty5
sudo rm -rf /var/service/agetty-tty6

# Set up ACPI
sudo ln -s /etc/sv/acpid/ /var/service/
sudo sv enable acpid
sudo sv start acpid

# Clone and set up dotfiles
git clone https://github.com/jaycee1285/LWC/vrit "$HOME/dotfiles"
cp -r "$HOME/dotfiles/."* "$HOME/"
rm -rf "$HOME/dotfiles"
chmod -R +X "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/autostart/"
chmod +x "$HOME/.config/autostart/*" "$HOME/.local/bin/*" 
ln -s "$HOME/.config/mimeapps.list" "$HOME/.local/share/applications/"

# Add user to wheel group for sudo access
sudo echo "%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/halt, /usr/bin/poweroff, /usr/bin/reboot, /usr/bin/shutdown, /usr/bin/zzz, /usr/bin/ZZZ" | sudo tee -a /etc/sudoers.d/wheel