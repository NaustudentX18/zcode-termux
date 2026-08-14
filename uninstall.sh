#!/data/data/com.termux/files/usr/bin/bash
#
# Uninstall ZCode from Termux proot
#
set -euo pipefail

echo "[INFO] Removing ZCode from Debian proot..."
proot-distro login debian -- bash -c "dpkg --purge zcode 2>/dev/null || true"

echo "[INFO] Removing launcher..."
rm -f "$PREFIX/bin/zcode" 2>/dev/null || true

echo "[INFO] Removing shortcut..."
rm -f "$HOME/.shortcuts/ZCode" 2>/dev/null || true

echo "[INFO] Removing cached .deb..."
rm -f /tmp/zcode-*-arm64.deb 2>/dev/null || true

echo ""
echo "[OK] ZCode removed."
echo "[INFO] Debian proot left in place (use 'proot-distro remove debian' to delete fully)"