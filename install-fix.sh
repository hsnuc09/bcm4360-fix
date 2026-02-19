#!/bin/bash
#
# Broadcom BCM4360 WiFi Fix for Ubuntu 24.04+
# Installs the fixed broadcom-sta-dkms driver (version 6.30.223.271-23ubuntu1.2)
#
# Usage: sudo bash install-fix.sh
#

set -e

echo "=========================================="
echo "Broadcom BCM4360 WiFi Fix for Ubuntu 24.04"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo bash install-fix.sh)"
    exit 1
fi

# Verify hardware
echo "[1/6] Verifying hardware..."
if lspci -nn | grep -q "14e4:43a0"; then
    echo "✓ BCM4360 detected"
else
    echo "⚠ BCM4360 not detected. This script may not be applicable."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Add noble-proposed repository
echo ""
echo "[2/6] Adding noble-proposed repository..."
echo 'deb http://de.archive.ubuntu.com/ubuntu noble-proposed restricted' > /etc/apt/sources.list.d/noble-proposed.list
apt-get update -qq
echo "✓ Repository added"

# Install fixed driver
echo ""
echo "[3/6] Installing fixed driver (6.30.223.271-23ubuntu1.2)..."
apt-get install -y --allow-downgrades broadcom-sta-dkms=6.30.223.271-23ubuntu1.2
echo "✓ Driver installed"

# Blacklist conflicting drivers
echo ""
echo "[4/6] Blacklisting conflicting drivers..."
cat > /etc/modprobe.d/broadcom-blacklist.conf << 'EOF'
blacklist b43
blacklist bcma
blacklist brcmsmac
EOF
echo "✓ Conflicting drivers blacklisted"

# Load the wl driver
echo ""
echo "[5/6] Loading wl driver..."
modprobe -r brcmfmac b43 bcma brcmsmac 2>/dev/null || true
modprobe wl
echo "✓ wl driver loaded"

# Cleanup repository
echo ""
echo "[6/6] Cleaning up..."
rm -f /etc/apt/sources.list.d/noble-proposed.list
apt-get update -qq
echo "✓ Cleanup complete"

# Verify
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""

if ip link show wlp2s0 &>/dev/null; then
    echo "✓ WiFi interface detected: wlp2s0"
    echo ""
    echo "To connect to WiFi:"
    echo "  - GUI: Click network icon → Select network → Enter password"
    echo "  - CLI: nmcli device wifi connect \"YourSSID\" password \"YourPassword\""
else
    echo "⚠ WiFi interface not found. Try rebooting."
    echo "  sudo reboot"
fi

echo ""
echo "For more information, see: https://github.com/yourusername/bcm4360-fix"
echo ""
