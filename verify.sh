#!/bin/bash
#
# Verify BCM4360 WiFi fix installation
#

echo "=========================================="
echo "BCM4360 WiFi Fix Verification"
echo "=========================================="
echo ""

# Check hardware
echo "Hardware:"
lspci -nn | grep -i network | grep -E "14e4:43a0|Broadcom" || echo "  ⚠ BCM4360 not detected"
echo ""

# Check driver version
echo "Driver:"
dpkg -l | grep broadcom-sta-dkms || echo "  ⚠ broadcom-sta-dkms not installed"
echo ""

# Check loaded modules
echo "Loaded Modules:"
if lsmod | grep -q wl; then
    echo "  ✓ wl module loaded"
    lsmod | grep wl
else
    echo "  ✗ wl module not loaded"
fi
echo ""

# Check WiFi interface
echo "Network Interfaces:"
ip link show | grep -E "wlp|wlan" || echo "  ⚠ No WiFi interface found"
echo ""

# Check connection status
echo "WiFi Status:"
if command -v nmcli &>/dev/null; then
    nmcli device status | grep wifi || echo "  No WiFi device managed by NetworkManager"
else
    iwconfig 2>/dev/null | grep -E "ESSID|Mode" || echo "  iwconfig not available"
fi
echo ""

echo "=========================================="
