# WiFi Handshake Cracker Tool

<div align="center">

![WiFi Security](https://img.shields.io/badge/WiFi-Security-blue?style=for-the-badge&logo=wifi)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Android-green?style=for-the-badge&logo=linux)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge&logo=opensourceinitiative)

**Advanced Automated Tool for WiFi WPA/WPA2 Handshake Cracking**

*Professional penetration testing tool for wireless security audits*

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Support](#-support-the-developer)

</div>

## 🚀 Overview

The **WiFi Handshake Cracker** is a sophisticated penetration testing tool designed to automate the process of cracking WPA/WPA2 handshakes from capture files. It streamlines the workflow from capture file analysis to password recovery, making wireless security auditing more efficient and accessible.

**⚠️ Legal Disclaimer**: This tool is for educational purposes and authorized security testing only. Always ensure you have explicit permission to test target networks. Users are solely responsible for complying with local laws and regulations.

## ✨ Features

### 🔍 Smart Extraction
- **Automatic BSSID/MAC extraction** from .cap file content
- **ESSID network name detection** for targeted attacks
- **Filename parsing fallback** when offline
- **Multiple extraction methods** for maximum compatibility

### 🛠️ Automation
- **Auto-tool installation** with network detection
- **Smart password pattern generation**
- **ESSID-based intelligent guessing**
- **One-click workflow** from capture to crack

### 📱 Cross-Platform
- **Linux support** (Debian, Ubuntu, CentOS, Arch)
- **Android Termux compatibility inside nethunter or proot-distro**
- **Online & offline operation**
- **Multiple package manager support**

### 🎯 Advanced Capabilities
- **Custom pattern configuration**
- **Progress indicators** and status updates
- **Resource-efficient** operation
- **Comprehensive error handling**

## 🛠️ Requirements

### System Requirements
- **Linux**: Most distributions (Ubuntu, Debian, CentOS, Arch)
- **Android**: Termux (Android 7.0+)
- **Storage**: 100MB free space
- **Memory**: 512MB RAM minimum

### Required Tools
The script automatically installs these if missing:
- **`aircrack-ng`** - WiFi security auditing suite
- **`crunch`** - Wordlist generator
- **`binutils`** - Strings command for analysis

## 📥 Installation

### Linux Installation
```bash
# Clone or download the script
wcracker/main/wifi_cracker.sh

# Make executable
chmod +x wifi_cracker.sh

# Run with test fi to verify
./wifi_cracker.sh --test
