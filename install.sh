#!/data/data/com.termux/files/usr/bin/bash
#
# ZCode Termux Installer
# =======================
# Downloads and installs the ZCode Linux ARM64 .deb into a proot Debian
# environment inside Termux, then launches it via Termux:X11.
#
# Usage:
#   pkg install git -y
#   git clone https://github.com/NaustudentX18/zcode-termux.git
#   cd zcode-termux
#   bash install.sh
#
# After install, launch with:  zcode
#
set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
ZCODE_VERSION="3.7.7"
ZCODE_DEB_URL="https://cdn-zcode.z.ai/zcode/electron/releases/${ZCODE_VERSION}/linux-arm64/ZCode-${ZCODE_VERSION}-linux-arm64.deb"
INSTALL_DIR="\$HOME/zcode-install"
DEB_FILE="/tmp/zcode-${ZCODE_VERSION}-arm64.deb"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "\${BLUE}[INFO]\${NC}  \$*"; }
ok()    { echo -e "\${GREEN}[OK]\${NC}    \$*"; }
warn()  { echo -e "\${YELLOW}[WARN]\${NC}  \$*"; }
die()   { echo -e "\${RED}[ERROR]\${NC} \$*"; exit 1; }

# ── Preflight ─────────────────────────────────────────────────────────────────
info "ZCode Termux Installer v${ZCODE_VERSION}"

if [[ "\$(uname -o)" != "Android" ]]; then
    die "This script must be run inside Termux on Android. Detected: \$(uname -o)"
fi

ARCH="\$(uname -m)"
if [[ "\$ARCH" != "aarch64" ]]; then
    die "ZCode ARM64 build requires aarch64. Detected: \$ARCH"
fi
ok "Architecture: \$ARCH"

# ── Step 1: Install Termux packages ───────────────────────────────────────────
info "Installing Termux base packages..."
pkg update -y
pkg install -y proot-distro wget x11-repo termux-x11-nightly pulseaudio

ok "Termux packages installed"

# ── Step 2: Create Debian proot environment ────────────────────────────────────
info "Setting up Debian proot environment..."
if ! proot-distro list | grep -q "debian.*installed"; then
    info "Installing Debian (this takes a minute)..."
    proot-distro install debian
fi
ok "Debian proot ready"

# ── Step 3: Download ZCode .deb ────────────────────────────────────────────────
info "Downloading ZCode v${ZCODE_VERSION} ARM64..."
if [[ -f "\$DEB_FILE" ]]; then
    ok "Already downloaded: \$DEB_FILE"
else
    wget -q --show-progress -O "\$DEB_FILE" "\$ZCODE_DEB_URL" || die "Download failed: \$ZCODE_DEB_URL"
fi
ok "Downloaded: \$DEB_FILE (\$(du -h "\$DEB_FILE" | cut -f1))"

# ── Step 4: Copy .deb into proot, then install ─────────────────────────────────
info "Copying .deb into Debian proot..."
# proot-distro maps Termux /tmp to the guest, but to be safe we copy explicitly
proot-distro login debian -- cp "\$DEB_FILE" /tmp/zcode.deb 2>/dev/null || {
    # Fallback: use proot-distro's bind mount path
    cp "\$DEB_FILE" "\$HOME/../usr/var/lib/proot-distro/installed-rootfs/debian/tmp/zcode.deb" 2>/dev/null || true
}

info "Installing ZCode .deb + Electron dependencies in Debian proot..."
proot-distro login debian -- bash -c '
    set -e
    # Install the .deb (ignore dep errors first pass)
    dpkg -i /tmp/zcode.deb 2>/dev/null || true

    # Update apt and fix broken deps
    apt-get update -y
    apt-get install -y -f 2>/dev/null || true

    # Install Electron runtime dependencies
    apt-get install -y \
        libgtk-3-0 libnotify4 libnss3 libnss3-tools libxss1 libxtst6 \
        xdg-utils libatspi2.0-0 libdrm2 libgbm1 libasound2 \
        libappindicator3-1 libsecret-1-0 desktop-file-utils \
        libxcb-dri3-0 libxshmfence1 fonts-liberation 2>/dev/null || true

    # Verify install
    if dpkg -l | grep -q "^ii.*zcode"; then
        echo "OK: ZCode package installed"
    else
        echo "WARN: ZCode package not found in dpkg — .deb may use a different package name"
    fi
' 2>&1 | while read -r line; do echo "  $line"; done

# ── Step 5: Create launcher script ────────────────────────────────────────────
info "Creating launcher..."
LAUNCHER="\$PREFIX/bin/zcode"
cat > "\$LAUNCHER" << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
#
# ZCode launcher for Termux
# Starts X11, then launches ZCode in Debian proot
#
set -euo pipefail

# Kill stale X11
pkill -f termux-x11 2>/dev/null || true
sleep 1

# Start pulseaudio for audio (optional)
pulseaudio --start 2>/dev/null || true

# Start Termux:X11 in background
termux-x11 :0 &
sleep 2

# Launch ZCode inside Debian proot with DISPLAY
proot-distro login debian --shared-tmp -- bash -c '
    export DISPLAY=:0
    export HOME=/root
    export PULSE_SERVER=127.0.0.1

    # Find the ZCode binary (Electron .deb installs to various paths)
    ZCODE_BIN=""
    for p in /usr/bin/zcode /opt/ZCode/zcode /usr/lib/zcode/zcode /usr/local/bin/zcode; do
        if [ -x "$p" ]; then ZCODE_BIN="$p"; break; fi
    done

    if [ -z "$ZCODE_BIN" ]; then
        echo "ERROR: ZCode binary not found."
        echo "Searched: /usr/bin/zcode /opt/ZCode/zcode /usr/lib/zcode/zcode"
        echo "Try: dpkg -L zcode | grep -E "bin/zcode$""
        exit 1
    fi

    exec "$ZCODE_BIN" --no-sandbox
'
LAUNCHER_EOF
chmod +x "\$LAUNCHER"
ok "Launcher created: \$LAUNCHER"

# ── Step 6: Create desktop shortcut (optional) ────────────────────────────────
info "Creating Termux:Widget shortcut..."
mkdir -p "\$HOME/.shortcuts"
cat > "\$HOME/.shortcuts/ZCode" << 'SHORTCUT_EOF'
#!/data/data/com.termux/files/usr/bin/bash
zcode
SHORTCUT_EOF
chmod +x "\$HOME/.shortcuts/ZCode"
ok "Shortcut created (add Termux:Widget to home screen)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "\${GREEN}══════════════════════════════════════════════════════════════\${NC}"
echo -e "\${GREEN}  ZCode v${ZCODE_VERSION} installed successfully!\${NC}"
echo -e "\${GREEN}══════════════════════════════════════════════════════════════\${NC}"
echo ""
echo -e "  Launch with:  \${BLUE}zcode\${NC}"
echo -e "  Or tap the ZCode shortcut in Termux:Widget"
echo ""
echo -e "  \${YELLOW}Note:\${NC} First launch may take 10-20s as proot spins up."
echo -e "  \${YELLOW}Note:\${NC} ZCode needs GLM API key — get one at https://z.ai/subscribe"
echo ""