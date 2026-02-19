#!/bin/bash
# Push BCM4360 fix to GitHub after creating the repo

echo "=========================================="
echo "Push BCM4360 Fix to GitHub"
echo "=========================================="
echo ""
echo "First, create the repository on GitHub:"
echo "1. Go to: https://github.com/new"
echo "2. Repository name: bcm4360-fix"
echo "3. Description: WiFi fix for Broadcom BCM4360 on Ubuntu 24.04"
echo "4. Make it Public"
echo "5. Click 'Create repository'"
echo ""
read -p "Press Enter after you've created the repo..."

cd /home/hasan/ws/broadcom

echo ""
echo "Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Success! Your fix is now live at:"
    echo "  https://github.com/hsnuc09/bcm4360-fix"
    echo ""
    echo "Share it with others who have BCM4360 WiFi issues!"
else
    echo ""
    echo "✗ Push failed. Make sure you created the repo first."
fi
