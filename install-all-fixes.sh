#!/bin/bash
#
# Complete MacBook Pro (2013-2015) Fix for Ubuntu 24.04
# Installs both WiFi and Camera drivers
#
# Usage: sudo bash install-all-fixes.sh
#

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "============================================"
echo "MacBook Pro (2013-2015) Complete Fix"
echo "for Ubuntu 24.04"
if [ "$DRY_RUN" = true ]; then
    echo "           [DRY RUN - No changes made]"
fi
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo bash install-all-fixes.sh)"
    exit 1
fi

# Detect hardware
echo "[1/4] Detecting hardware..."
HAS_WIFI=$(lspci -nn | grep -c "14e4:43a0" || echo "0")
HAS_CAMERA=$(lspci -nn | grep -c "14e4:1570" || echo "0")

if [ "$HAS_WIFI" -gt 0 ]; then
    echo "✓ BCM4360 WiFi detected [14e4:43a0]"
else
    echo "  BCM4360 WiFi not detected"
fi

if [ "$HAS_CAMERA" -gt 0 ]; then
    echo "✓ FaceTime HD Camera detected [14e4:1570]"
else
    echo "  FaceTime HD Camera not detected"
fi

if [ "$HAS_WIFI" -eq 0 ] && [ "$HAS_CAMERA" -eq 0 ]; then
    echo ""
    echo "⚠ No supported hardware detected."
    echo "  This script is for MacBook Pro (2013-2015) models."
    if [ "$DRY_RUN" = true ]; then
        exit 0
    fi
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Fix WiFi
if [ "$HAS_WIFI" -gt 0 ]; then
    echo ""
    echo "[2/4] Fixing WiFi..."
    
    # Check if already fixed
    if lsmod | grep -q wl; then
        echo "  ✓ WiFi already working (wl module loaded)"
    else
        if [ "$DRY_RUN" = true ]; then
            echo "  → Would add: noble-proposed repository"
            echo "  → Would install: broadcom-sta-dkms=6.30.223.271-23ubuntu1.2"
            echo "  → Would blacklist: b43, bcma, brcmsmac"
            echo "  → Would load: wl module"
        else
            # Add noble-proposed repo
            echo 'deb http://de.archive.ubuntu.com/ubuntu noble-proposed restricted' > /etc/apt/sources.list.d/noble-proposed.list
            apt-get update -qq
            
            # Install driver
            apt-get install -y --allow-downgrades broadcom-sta-dkms=6.30.223.271-23ubuntu1.2
            
            # Blacklist conflicting drivers
            cat > /etc/modprobe.d/broadcom-blacklist.conf << 'EOF'
blacklist b43
blacklist bcma
blacklist brcmsmac
EOF
            
            # Load driver
            modprobe -r brcmfmac b43 bcma brcmsmac 2>/dev/null || true
            modprobe wl
            
            # Cleanup
            rm -f /etc/apt/sources.list.d/noble-proposed.list
            apt-get update -qq
            
            echo "  ✓ WiFi fixed"
        fi
    fi
fi

# Fix Camera
if [ "$HAS_CAMERA" -gt 0 ]; then
    echo ""
    echo "[3/4] Fixing Camera..."
    
    # Check if already fixed
    if [ -e /dev/video0 ]; then
        CAMERA_CARD=$(v4l2-ctl --device=/dev/video0 --info 2>/dev/null | grep "Card type" | awk -F': ' '{print $2}')
        if [[ "$CAMERA_CARD" == *"Facetime"* ]] || [[ "$CAMERA_CARD" == *"facetime"* ]]; then
            echo "  ✓ Camera already working (facetimehd driver)"
            HAS_CAMERA_FIXED=true
        else
            HAS_CAMERA_FIXED=false
        fi
    else
        HAS_CAMERA_FIXED=false
    fi
    
    if [ "$HAS_CAMERA_FIXED" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  → Would add: ppa:greg-whiteley/facetimehd"
            echo "  → Would install: facetimehd-dkms facetimehd-firmware"
            echo "  → Would load: facetimehd module"
        else
            # Add PPA
            if ! apt-cache policy | grep -q "greg-whiteley/facetimehd"; then
                add-apt-repository -y ppa:greg-whiteley/facetimehd
                apt-get update -qq
            fi
            
            # Install driver
            apt-get install -y facetimehd-dkms facetimehd-firmware
            
            # Load module
            modprobe facetimehd
            
            echo "  ✓ Camera fixed"
        fi
    fi
fi

# Final verification
echo ""
echo "[4/4] Verifying installation..."
if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "============================================"
    echo "Dry Run Complete!"
    echo "============================================"
    echo ""
    echo "No changes were made. To install for real, run:"
    echo "  sudo bash install-all-fixes.sh"
    echo ""
    exit 0
else
    sleep 2  # Give modules time to initialize
    
    WIFI_STATUS="❌ Not working"
    CAMERA_STATUS="❌ Not working"
    
    if [ "$HAS_WIFI" -gt 0 ]; then
        if ip link show wlp2s0 &>/dev/null && lsmod | grep -q wl; then
            WIFI_STATUS="✅ Working"
        fi
    else
        WIFI_STATUS="⊘ Not present"
    fi
    
    if [ "$HAS_CAMERA" -gt 0 ]; then
        if [ -e /dev/video0 ]; then
            CAMERA_CARD=$(v4l2-ctl --device=/dev/video0 --info 2>/dev/null | grep "Card type" | awk -F': ' '{print $2}')
            if [[ "$CAMERA_CARD" == *"Facetime"* ]] || [[ "$CAMERA_CARD" == *"facetime"* ]]; then
                CAMERA_STATUS="✅ Working"
            fi
        fi
    else
        CAMERA_STATUS="⊘ Not present"
    fi
    
    echo ""
    echo "============================================"
    echo "Installation Complete!"
    echo "============================================"
    echo ""
    echo "Status:"
    echo "  WiFi:     $WIFI_STATUS"
    echo "  Camera:   $CAMERA_STATUS"
    echo ""
    
    if [ "$HAS_WIFI" -gt 0 ] && [[ "$WIFI_STATUS" == "✅ Working" ]]; then
        echo "WiFi Instructions:"
        echo "  - GUI: Click network icon → Select network → Enter password"
        echo "  - CLI: nmcli device wifi connect \"YourSSID\" password \"YourPassword\""
        echo ""
    fi
    
    if [ "$HAS_CAMERA" -gt 0 ] && [[ "$CAMERA_STATUS" == "✅ Working" ]]; then
        echo "Camera will work in:"
        echo "  - Google Chrome / Chromium"
        echo "  - Zoom"
        echo "  - Skype"
        echo "  - OBS Studio"
        echo "  - Cheese (GNOME camera app)"
        echo ""
    fi
    
    echo "For more information, see:"
    echo "  https://github.com/hsnuc09/bcm4360-fix"
    echo ""
fi
