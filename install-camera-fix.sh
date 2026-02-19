#!/bin/bash
#
# FaceTime HD Camera Fix for MacBook Pro/Air (2013-2015)
# Installs the facetimehd driver from PPA
#
# Usage: sudo bash install-camera-fix.sh
#

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

echo "=========================================="
echo "FaceTime HD Camera Fix for Ubuntu 24.04"
if [ "$DRY_RUN" = true ]; then
    echo "           [DRY RUN - No changes made]"
fi
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo bash install-camera-fix.sh)"
    exit 1
fi

# Verify hardware
echo "[1/5] Verifying hardware..."
if lspci -nn | grep -q "14e4:1570"; then
    echo "✓ FaceTime HD Camera detected [14e4:1570]"
else
    echo "⚠ FaceTime HD Camera not detected. This script may not be applicable."
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

# Check if camera is already working
if [ -e /dev/video0 ]; then
    CAMERA_CARD=$(v4l2-ctl --device=/dev/video0 --info 2>/dev/null | grep "Card type" | awk -F': ' '{print $2}')
    if [[ "$CAMERA_CARD" == *"Facetime"* ]] || [[ "$CAMERA_CARD" == *"facetime"* ]]; then
        echo "✓ Camera already working with facetimehd driver"
        echo ""
        echo "No action needed!"
        exit 0
    fi
fi

# Add facetimehd PPA
echo ""
echo "[2/5] Adding facetimehd PPA..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would run: sudo add-apt-repository -y ppa:greg-whiteley/facetimehd"
    echo "  → Would run: sudo apt-get update"
else
    # Check if PPA already exists
    if ! apt-cache policy | grep -q "greg-whiteley/facetimehd"; then
        add-apt-repository -y ppa:greg-whiteley/facetimehd
        apt-get update -qq
        echo "✓ PPA added"
    else
        echo "✓ PPA already exists"
        apt-get update -qq
    fi
fi

# Install driver and firmware
echo ""
echo "[3/5] Installing facetimehd driver and firmware..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would run: apt-get install -y facetimehd-dkms facetimehd-firmware"
    PACKAGE_INFO=$(apt-cache policy facetimehd-dkms 2>/dev/null | grep -A1 "Candidate:" | tail -1 | xargs)
    if [ -n "$PACKAGE_INFO" ]; then
        echo "  → Package available: $PACKAGE_INFO"
    else
        echo "  → Package status: Available in PPA"
    fi
else
    apt-get install -y facetimehd-dkms facetimehd-firmware
    echo "✓ Driver and firmware installed"
fi

# Load the module
echo ""
echo "[4/5] Loading facetimehd module..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would run: modprobe facetimehd"
    CURRENT_MODULE=$(lspci -nnk -d 14e4:1570 2>/dev/null | grep "Kernel driver in use" | awk -F': ' '{print $2}')
    echo "  → Current driver: ${CURRENT_MODULE:-none}"
else
    # Check if module is already loaded
    if ! lsmod | grep -q facetimehd; then
        modprobe facetimehd
        echo "✓ facetimehd module loaded"
    else
        echo "✓ facetimehd module already loaded"
    fi
fi

# Verify installation
echo ""
echo "[5/5] Verifying installation..."
if [ "$DRY_RUN" = true ]; then
    echo "  → Would check: /dev/video0"
    echo "  → Would run: v4l2-ctl --list-devices"
    echo ""
    echo "=========================================="
    echo "Dry Run Complete!"
    echo "=========================================="
    echo ""
    echo "No changes were made. To install for real, run:"
    echo "  sudo bash install-camera-fix.sh"
    exit 0
else
    sleep 2  # Give module time to initialize
    
    if [ -e /dev/video0 ]; then
        CAMERA_CARD=$(v4l2-ctl --device=/dev/video0 --info 2>/dev/null | grep "Card type" | awk -F': ' '{print $2}')
        echo "✓ Camera detected: $CAMERA_CARD"
        echo "✓ Device: /dev/video0"
        
        # Get resolution info
        RESOLUTION=$(v4l2-ctl --device=/dev/video0 --list-formats-ext 2>/dev/null | grep -A1 "Size: Discrete" | head -2 | tail -1 | awk '{print $2}')
        if [ -n "$RESOLUTION" ]; then
            echo "✓ Resolution: $RESOLUTION"
        fi
    else
        echo "⚠ Camera device not found. Try rebooting."
    fi
fi

# Final status
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Your FaceTime HD Camera should now work in:"
echo "  - Google Chrome / Chromium"
echo "  - Zoom"
echo "  - Skype"
echo "  - OBS Studio"
echo "  - Cheese (GNOME camera app)"
echo "  - Most Linux video applications"
echo ""
echo "Test the camera with:"
echo "  v4l2-ctl --device=/dev/video0 --all"
echo ""
if [ "$DRY_RUN" = false ]; then
    echo "Note: Some apps may require a restart to detect the camera."
fi
echo ""
