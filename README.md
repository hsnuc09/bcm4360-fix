# Broadcom BCM4360 WiFi Fix for Ubuntu 24.04+

Fix for Broadcom BCM4360 (14e4:43a0) WiFi adapter on MacBook Pro/Air (2013-2015) running Ubuntu 24.04 LTS with kernel 6.17+.

## Problem

The `broadcom-sta-dkms` driver version `6.30.223.271-23ubuntu1.1` shipped with Ubuntu 24.04 fails to compile on kernel 6.17+, resulting in non-functional WiFi on MacBook Pro/Air models with the BCM4360 chipset.

**Error:**
```
ERROR: Cannot create report: [Errno 17] File exists: '/var/crash/broadcom-sta-dkms.0.crash'
Error! Bad return status for module build on kernel: 6.17.0-14-generic
```

## Affected Hardware

- **Chip:** Broadcom BCM4360 802.11ac Dual Band Wireless Network Adapter
- **PCI ID:** `[14e4:43a0]` (rev 03)
- **Subsystem:** Apple Inc. `[106b:0134]`
- **Models:** MacBook Pro (2013-2015), MacBook Air (2013-2015), iMac (2013-2015)

Verify your hardware:
```bash
lspci -nn | grep -i network
# Should show: Broadcom Inc. and subsidiaries BCM4360 802.11ac Dual Band Wireless Network Adapter [14e4:43a0]
```

## Solution

Install the fixed driver version `6.30.223.271-23ubuntu1.2` from the `noble-proposed` repository.

**No third-party software required** - uses only official Ubuntu packages and built-in tools.

### Quick Fix (Automated)

```bash
# Clone the repository
git clone https://github.com/hsnuc09/bcm4360-fix.git
cd bcm4360-fix

# Test first (dry run - shows what would happen without making changes)
sudo bash install-fix.sh --dry-run

# Install for real
sudo bash install-fix.sh
```

### Manual Installation

1. **Add noble-proposed repository:**
   ```bash
   echo 'deb http://de.archive.ubuntu.com/ubuntu noble-proposed restricted' | sudo tee /etc/apt/sources.list.d/noble-proposed.list
   sudo apt-get update
   ```

2. **Install the fixed driver:**
   ```bash
   sudo apt-get install -y --allow-downgrades broadcom-sta-dkms=6.30.223.271-23ubuntu1.2
   ```

3. **Load the driver:**
   ```bash
   sudo modprobe -r brcmfmac b43 bcma brcmsmac
   sudo modprobe wl
   ```

4. **Verify WiFi interface:**
   ```bash
   ip link show
   # Should show: wlp2s0: <BROADCAST,MULTICAST,UP,LOWER_UP>
   ```

5. **Cleanup (optional but recommended):**
   ```bash
   sudo rm /etc/apt/sources.list.d/noble-proposed.list
   sudo apt-get update
   ```

## Connect to WiFi

**GUI:** Click network icon → Select your network → Enter password

**Command line:**
```bash
nmcli device wifi list
nmcli device wifi connect "YourSSID" password "YourPassword"
```

## Verification

Check that the driver is loaded:
```bash
lsmod | grep wl
# Should show: wl and lib80211

ip link show wlp2s0
# Should show: state UP
```

## Troubleshooting

### Driver fails to load
```bash
# Check for errors
dmesg | grep -i wl

# Reload driver
sudo modprobe -r wl
sudo modprobe wl
```

### WiFi not showing networks
```bash
# Check interface is up
sudo ip link set wlp2s0 up

# Scan for networks
sudo iwlist wlp2s0 scan
```

### Conflicts with other drivers
```bash
# Ensure conflicting drivers are blacklisted
echo -e "blacklist b43\nblacklist bcma\nblacklist brcmsmac" | sudo tee /etc/modprobe.d/broadcom-blacklist.conf
```

## Technical Details

| Driver Version | Kernel 6.17+ Support | Status |
|----------------|---------------------|--------|
| 6.30.223.271-23ubuntu1 | ❌ | Fails to compile |
| 6.30.223.271-23ubuntu1.1 | ❌ | Fails to compile |
| 6.30.223.271-23ubuntu1.2 | ✅ | Works |

The fixed version (`...ubuntu1.2`) includes patches for kernel 6.17+ compatibility.

## References

- [Ubuntu Discourse: BCM4360 driver works on 25.10 but not on 24.04.3 LTS](https://discourse.ubuntu.com/t/bcm4360-driver-works-on-25-10-but-not-on-24-04-3-lts/76543)
- [ArchWiki: Broadcom wireless](https://wiki.archlinux.org/title/Broadcom_wireless)

## MacBook Pro (2013-2015) Hardware Compatibility

| Component | Status on Ubuntu 24.04 | Notes |
|-----------|----------------------|-------|
| **WiFi** | ⚠️ Needs fix | BCM4360 - use this repo |
| **Graphics** | ✅ Works out of box | Intel Iris Pro P5200 (i915 driver) |
| **Display** | ✅ Works out of box | Retina 2880x1800 native resolution |
| **3D Acceleration** | ✅ Works out of box | Mesa 25.2.8, OpenGL 4.6 |
| **Ethernet** | ✅ Works out of box | Broadcom BCM57786 |
| **Bluetooth** | ⚠️ May need firmware | Broadcom - usually works |
| **Audio** | ⚠️ May need tweaks | Cirrus Logic - see ArchWiki |
| **Trackpad** | ✅ Works out of box | Apple SPI - basic gestures |
| **Camera** | ⚠️ Limited support | FaceTime HD - driver in development |

**Good news:** Only WiFi requires manual intervention. Everything else works with the default Ubuntu 24.04 installation!

## License

This repository contains documentation and scripts. The driver itself is proprietary Broadcom software.

## Contributing

If this fix helped you or you have improvements, please open an issue or PR.

## Credits

- **Solution by:** Qwen Code (AI Assistant)
- **Repository by:** hsnuc09

This solution was developed through collaborative debugging and research of Ubuntu community resources.

---

**Tested on:**
- MacBook Pro 11,3 (2014)
- MacBook Air 7,1 (2015)
- Ubuntu 24.04 LTS with kernel 6.17.0-14-generic
