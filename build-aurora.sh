#!/usr/bin/env bash
# Aurora Linux: sleek, animated KDE Plasma 6 live ISO on Debian 13 (trixie)
# Run on Debian/Ubuntu (VM is fine): 8GB+ RAM, 30GB+ free disk, internet.
#   chmod +x build-aurora.sh && sudo ./build-aurora.sh
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Run with sudo"; exit 1; }

NAME="Aurora"
apt-get update && apt-get install -y live-build debootstrap squashfs-tools xorriso

WORK=./aurora-build
mkdir -p "$WORK" && cd "$WORK"

lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash" \
  --iso-application "$NAME" --iso-volume "$NAME" \
  --archive-areas "main contrib non-free-firmware" \
  --debian-installer none

# ---------- packages ----------
mkdir -p config/package-lists
cat > config/package-lists/aurora.list.chroot <<'EOF'
kde-plasma-desktop
sddm
plasma-nm
plasma-pa
dolphin
konsole
kate
firefox-esr
calamares
calamares-settings-debian
papirus-icon-theme
fonts-inter
fonts-jetbrains-mono
plymouth
plymouth-themes
network-manager
EOF

# ---------- default look & animations (applied to every new user) ----------
SKEL=config/includes.chroot/etc/skel/.config
mkdir -p "$SKEL"

# Dark theme, Papirus icons, Inter font
cat > "$SKEL/kdeglobals" <<'EOF'
[General]
font=Inter,10,-1,5,50,0,0,0,0,0
fixed=JetBrains Mono,10,-1,5,50,0,0,0,0,0
[Icons]
Theme=Papirus-Dark
[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
AnimationDurationFactor=0.7
EOF

# KWin effects: blur, wobbly windows, magic lamp minimize, smooth transitions
cat > "$SKEL/kwinrc" <<'EOF'
[Plugins]
blurEnabled=true
wobblywindowsEnabled=true
magiclampEnabled=true
squashEnabled=false
slideEnabled=true
fadeEnabled=true
glideEnabled=true
translucencyEnabled=true
overviewEnabled=true
desktopgridEnabled=true
[Effect-overview]
BorderActivate=9
[Effect-blur]
BlurStrength=7
NoiseStrength=3
[Effect-wobblywindows]
Drag=85
Stiffness=8
WobblynessLevel=1
[org.kde.kdecoration2]
ButtonsOnLeft=XIA
ButtonsOnRight=
EOF

# ---------- boot splash, login, branding, live-session polish ----------
mkdir -p config/hooks/live
cat > config/hooks/live/0100-aurora.hook.chroot <<EOF
#!/bin/sh
set -e
# Animated boot splash
plymouth-set-default-theme -R spinner || true
# Modern SDDM login with Breeze (dark)
mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=breeze\n' > /etc/sddm.conf.d/10-theme.conf
# Branding
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="$NAME Linux"/; s/^NAME=.*/NAME="$NAME Linux"/' /etc/os-release || true
echo "$NAME" > /etc/hostname
EOF
chmod +x config/hooks/live/0100-aurora.hook.chroot

# ---------- build ----------
lb build 2>&1 | tee build.log
ls -lh ./*.iso && echo "Done. Test with: qemu-system-x86_64 -m 4G -enable-kvm -cdrom live-image-amd64.hybrid.iso"
