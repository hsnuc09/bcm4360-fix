#!/bin/bash
#
# Broadcom BCM4360 WiFi Fix for Ubuntu 24.04+
# Installs the fixed broadcom-sta-dkms driver (version 6.30.223.271-23ubuntu1.2)
#
# Usage: 
#   sudo bash install-fix.sh           # Full installation
#   sudo bash install-fix.sh --dry-run # Test without changes
#

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "=========================================="
echo "Broadcom BCM4360 WiFi Fix for Ubuntu 24.04"
if [ "$DRY_RUN" = true ]; then
    echo "           [DRY RUN - No changes made]"
fi
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
    if [ "$DRY_RUN" = true ]; then
        echo "  Exiting dry run."
        exit 0
    fi
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Add noble-proposed repository
echo ""
echo "[2/6] Adding noble-proposed repository..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would add: deb http://de.archive.ubuntu.com/ubuntu noble-proposed restricted"
    echo "  → Would run: apt-get update"
else
    echo 'deb http://de.archive.ubuntu.com/ubuntu noble-proposed restricted' > /etc/apt/sources.list.d/noble-proposed.list
    apt-get update -qq
    echo "✓ Repository added"
fi

# Install fixed driver
echo ""
echo "[3/6] Installing fixed driver (6.30.223.271-23ubuntu1.2)..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would run: apt-get install -y --allow-downgrades broadcom-sta-dkms=6.30.223.271-23ubuntu1.2"
    echo "  → Package available: $(apt-cache policy broadcom-sta-dkms 2>/dev/null | grep -A1 'Candidate:' | tail -1 | xargs)"
else
    apt-get install -y --allow-downgrades broadcom-sta-dkms=6.30.223.271-23ubuntu1.2
    echo "✓ Driver installed"
fi

# Blacklist conflicting drivers
echo ""
echo "[4/6] Blacklisting conflicting drivers..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would create: /etc/modprobe.d/broadcom-blacklist.conf"
    echo "  → Would blacklist: b43, bcma, brcmsmac"
else
    cat > /etc/modprobe.d/broadcom-blacklist.conf << 'EOF'
blacklist b43
blacklist bcma
blacklist brcmsmac
EOF
    echo "✓ Conflicting drivers blacklisted"
fi

# Load the wl driver
echo ""
echo "[5/6] Loading wl driver..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would run: modprobe -r brcmfmac b43 bcma brcmsmac"
    echo "  → Would run: modprobe wl"
    CURRENT_DRIVER=$(lspci -nnk -d 14e4:43a0 | grep "Kernel driver in use" | awk -F': ' '{print $2}')
    echo "  → Current driver: ${CURRENT_DRIVER:-none}"
else
    modprobe -r brcmfmac b43 bcma brcmsmac 2>/dev/null || true
    modprobe wl
    echo "✓ wl driver loaded"
fi

# Cleanup repository
echo ""
echo "[6/6] Cleaning up..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would remove: /etc/apt/sources.list.d/noble-proposed.list"
    echo "  → Would run: apt-get update"
    echo ""
    echo "=========================================="
    echo "Dry Run Complete!"
    echo "=========================================="
    echo ""
    echo "No changes were made. To install for real, run:"
    echo "  sudo bash install-fix.sh"
    exit 0
else
    rm -f /etc/apt/sources.list.d/noble-proposed.list
    apt-get update -qq
    echo "✓ Cleanup complete"
fi

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
