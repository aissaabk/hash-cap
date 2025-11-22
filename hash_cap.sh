#!/bin/bash

# =============================================================================
# WiFi Handshake Cracker Tool
# Developer: Aissa Abk
# Version: 2.4 - Fixed Extraction
# GitHub: www.github.aissaabk
# Facebook: www.facebook.com/devbelmel
# =============================================================================

show_help() {
    echo "================================================================"
    echo "               WiFi Handshake Cracker Tool"
    echo "================================================================"
    echo ""
    echo "📖 ABOUT:"
    echo "  Automated tool for cracking WiFi handshake captures (.cap files)"
    echo "  Uses aircrack-ng for reliable network information extraction"
    echo ""
    echo "👨‍💻 DEVELOPER:"
    echo "  Aissa Abk"
    echo "  GitHub:   www.github.aissaabk"
    echo "  Facebook: www.facebook.com/devbelmel"
    echo ""
    echo "⚡ USAGE:"
    echo "  $0 <handshake.cap>"
    echo "  $0 --help"
    echo "  $0 --version"
    echo "  $0 --test"
    echo ""
    echo "🔧 REQUIREMENTS:"
    echo "  - aircrack-ng: WiFi security auditing tools"
    echo "  - crunch: Password wordlist generator"
    echo "  - binutils: For strings command"
    echo ""
    echo "================================================================"
}

show_version() {
    echo "WiFi Handshake Cracker Tool v2.4"
    echo "Fixed BSSID extraction"
    echo "Developed by Aissa Abk"
}

# Function to check and install required tools
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
        return 0
    fi
    
    echo "🔧 Missing tools: ${missing_tools[*]}"
    echo "📥 Attempting to install missing tools..."
    
    # Check internet connectivity
    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        echo "🌐 Network connected. Installing tools..."
        
        # Detect package manager and install
        if command -v apt-get &> /dev/null; then
            echo "📦 Using apt package manager..."
            sudo apt-get update > /dev/null 2>&1
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    strings)
                        echo "📥 Installing binutils (strings)..."
                        sudo apt-get install -y binutils > /dev/null 2>&1
                        ;;
                    crunch)
                        echo "📥 Installing crunch..."
                        sudo apt-get install -y crunch > /dev/null 2>&1
                        ;;
                    aircrack-ng)
                        echo "📥 Installing aircrack-ng..."
                        sudo apt-get install -y aircrack-ng > /dev/null 2>&1
                        ;;
                esac
            done
        elif command -v yum &> /dev/null; then
            echo "📦 Using yum package manager..."
            sudo yum install -y epel-release > /dev/null 2>&1
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    strings)
                        sudo yum install -y binutils > /dev/null 2>&1
                        ;;
                    crunch)
                        sudo yum install -y crunch > /dev/null 2>&1
                        ;;
                    aircrack-ng)
                        sudo yum install -y aircrack-ng > /dev/null 2>&1
                        ;;
                esac
            done
        elif command -v dnf &> /dev/null; then
            echo "📦 Using dnf package manager..."
            sudo dnf install -y epel-release > /dev/null 2>&1
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    strings)
                        sudo dnf install -y binutils > /dev/null 2>&1
                        ;;
                    crunch)
                        sudo dnf install -y crunch > /dev/null 2>&1
                        ;;
                    aircrack-ng)
                        sudo dnf install -y aircrack-ng > /dev/null 2>&1
                        ;;
                esac
            done
        elif command -v pacman &> /dev/null; then
            echo "📦 Using pacman package manager..."
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    strings)
                        sudo pacman -S --noconfirm binutils > /dev/null 2>&1
                        ;;
                    crunch)
                        sudo pacman -S --noconfirm crunch > /dev/null 2>&1
                        ;;
                    aircrack-ng)
                        sudo pacman -S --noconfirm aircrack-ng > /dev/null 2>&1
                        ;;
                esac
            done
        else
            echo "❌ Unknown package manager. Please install manually."
            return 1
        fi
        
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
            return 1
        fi
    else
        echo "🌐 No network connection. Skipping automatic installation."
        echo "💡 Please install these tools manually: ${missing_tools[*]}"
        return 1
    fi
}

# Function to extract from cap file using aircrack-ng
extract_from_cap_content() {
    local file="$1"
    local bssid=""
    local essid=""
    
    echo "🔍 Analyzing cap file using aircrack-ng..." >&2
    
    # Use aircrack-ng to analyze the capture file
    if command -v aircrack-ng &> /dev/null; then
        echo "📡 Running aircrack-ng analysis..." >&2
        
        # Run aircrack-ng and capture output
        local air_output
        air_output=$(aircrack-ng "$file" 2>/dev/null)
        
        # Extract BSSID - look for lines with MAC addresses in the network list
        bssid=$(echo "$air_output" | grep -E '^[[:space:]]*[0-9]+[[:space:]]+([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1 | awk '{print $2}')
        
        # Extract ESSID - look for network names after BSSID
        essid=$(echo "$air_output" | grep -E '^[[:space:]]*[0-9]+[[:space:]]+([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1 | awk '{for(i=3;i<=NF;i++) if ($i != "WPA" && $i != "WEP" && $i != "OPN" && $i !~ /handshake/) printf "%s ", $i}' | sed 's/ $//')
        
        # Alternative method: look for "Choosing first network as target" section
        if [ -z "$bssid" ]; then
            bssid=$(echo "$air_output" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)
        fi
        
        # Check if handshake is detected
        local handshake_detected
        handshake_detected=$(echo "$air_output" | grep -c "handshake")
        
        if [ -n "$bssid" ]; then
            echo "✅ Aircrack-ng analysis successful" >&2
            if [ "$handshake_detected" -gt 0 ]; then
                echo "✅ Handshake detected in capture file" >&2
            else
                echo "⚠️  No handshake detected - may not be able to crack" >&2
            fi
            echo "$bssid|$essid"
            return 0
        fi
    fi
    
    # Fallback to strings method if aircrack-ng fails
    echo "⚠️  Aircrack-ng extraction failed, trying alternative methods..." >&2
    
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
    
    echo "📁 Extracting from filename..." >&2
    
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

# Function to verify handshake with aircrack-ng
verify_handshake() {
    local file="$1"
    local bssid="$2"
    
    echo "🔎 Verifying handshake with aircrack-ng..." >&2
    
    if command -v aircrack-ng &> /dev/null; then
        # Run aircrack-ng to check for handshake
        local verification
        verification=$(aircrack-ng "$file" -b "$bssid" 2>/dev/null | grep -i "handshake")
        
        if [ -n "$verification" ]; then
            echo "✅ Valid WPA handshake confirmed" >&2
            return 0
        else
            echo "❌ No valid handshake found for BSSID: $bssid" >&2
            return 1
        fi
    else
        echo "⚠️  Cannot verify - aircrack-ng not available" >&2
        return 2
    fi
}

# Function to clean and validate MAC address
clean_mac_address() {
    local mac="$1"
    # Remove any non-MAC characters and ensure proper format
    mac=$(echo "$mac" | grep -oE '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' | head -1)
    mac=$(echo "$mac" | sed 's/-/:/g' | tr '[:lower:]' '[:upper:]')
    echo "$mac"
}

# Function to validate MAC address format
validate_mac() {
    local mac="$1"
    if [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        return 0
    else
        return 1
    fi
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
    -v|--version|version)
        show_version
        exit 0
        ;;
    --test)
        echo "🧪 Test mode: Creating sample analysis..."
        echo "This would simulate: aircrack-ng wpa.full.cap"
        echo "Expected output: BSSID: 00:14:6C:7E:40:80, ESSID: teddy"
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

FILEPATH=$(realpath "$1")
FILENAME=$(basename "$FILEPATH")

echo "================================================================"
echo "               WiFi Handshake Cracker Tool"
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

# First try to extract from cap file content using aircrack-ng
if result=$(extract_from_cap_content "$FILEPATH" 2>/dev/null); then
    echo "✅ Successfully extracted from cap file content"
    BSSID=$(echo "$result" | cut -d "|" -f 1)
    ESSID=$(echo "$result" | cut -d "|" -f 2)
    MAC="$BSSID"
    EXTRACTION_METHOD="aircrack-ng_analysis"
    
    # Clean and validate MAC address
    BSSID=$(clean_mac_address "$BSSID")
    MAC=$(clean_mac_address "$MAC")
    
    # Verify the handshake
    verify_handshake "$FILEPATH" "$BSSID"
else
    # Fallback to filename parsing
    echo "⚠ Could not extract from cap file content, trying filename..."
    result=$(extract_from_filename "$FILENAME")
    BSSID=$(echo "$result" | cut -d "|" -f 1)
    MAC=$(echo "$result" | cut -d "|" -f 2)
    TIMESTAMP=$(echo "$result" | cut -d "|" -f 3)
    EXTRACTION_METHOD="filename"
    
    # Clean and validate MAC addresses
    BSSID=$(clean_mac_address "$BSSID")
    MAC=$(clean_mac_address "$MAC")
fi

# Final validation - if still no valid BSSID/MAC, ask user
if [ -z "$BSSID" ] || ! validate_mac "$BSSID"; then
    echo "❌ Could not automatically extract valid BSSID/MAC"
    echo "Please enter the target information manually:"
    while true; do
        read -p "BSSID/MAC address (format: 00:11:22:33:44:55): " BSSID
        BSSID=$(clean_mac_address "$BSSID")
        if validate_mac "$BSSID"; then
            break
        else
            echo "❌ Invalid MAC format. Please use format: 00:11:22:33:44:55"
        fi
    done
    MAC="$BSSID"
    EXTRACTION_METHOD="manual"
fi

# Final cleanup
BSSID=$(clean_mac_address "$BSSID")
MAC=$(clean_mac_address "$MAC")

# --------------------------------------------------------------------
# Display extracted information
# --------------------------------------------------------------------
echo ""
echo "=== Extracted Information ==="
echo "Extraction method: $EXTRACTION_METHOD"
echo "BSSID:            $BSSID"
echo "MAC Address:      $MAC"
if [ -n "$ESSID" ] && [ "$ESSID" != " " ]; then
    echo "Network ESSID:    $ESSID"
fi
if [ -n "$TIMESTAMP" ]; then
    echo "Timestamp:        $TIMESTAMP"
fi
echo ""

# Show aircrack-ng style output
echo "=== Aircrack-ng Analysis ==="
aircrack-ng "$FILEPATH" 2>/dev/null | head -20
echo ""

# --------------------------------------------------------------------
# Generate additional parameters
# --------------------------------------------------------------------
TOOLS_ARG1="8"
TOOLS_ARG2="8"
TOOLS_ARG3="%%%%%%%%"

echo "Generated parameters:"
echo "TOOLS_ARG1 = $TOOLS_ARG1"
echo "TOOLS_ARG2 = $TOOLS_ARG2"
echo "TOOLS_ARG3 = $TOOLS_ARG3"
echo ""

while true; do
    echo "=== Parameter Selection ==="
    echo "1) Use default arguments (recommended)"
    echo "2) Enter custom arguments"
    if [ -n "$ESSID" ] && [ "$ESSID" != " " ]; then
        echo "3) Use ESSID-based pattern"
    fi
    echo "4) Show aircrack-ng analysis"
    echo "x) Exit"
    echo ""
    read -p "Choose option (1, 2, 3, 4, or x): " CHOICE

    # Convert input to lowercase
    CHOICE=${CHOICE,,}

    case "$CHOICE" in
        1)
            ARG1="$TOOLS_ARG1"
            ARG2="$TOOLS_ARG2"
            ARG3="$TOOLS_ARG3"

            echo ""
            echo "Using default values:"
            echo "  Min length = $ARG1"
            echo "  Max length = $ARG2"
            echo "  Pattern    = $ARG3"
            echo ""
            break
            ;;

        2)
            read -p "Enter min length: ex 8 : " ARG1
            read -p "Enter max length: ex 8 : " ARG2
            read -p "Enter pattern (pattern for -t): ex %%%%@@@@ : " ARG3

            echo ""
            echo "Using custom values:"
            echo "  Min length = $ARG1"
            echo "  Max length = $ARG2"
            echo "  Pattern    = $ARG3"
            echo ""
            break
            ;;

        3)
            if [ -n "$ESSID" ] && [ "$ESSID" != " " ]; then
                ARG1="8"
                ARG2="12"
                # Create pattern based on ESSID (first 4 chars as uppercase, rest as lowercase)
                ESSID_PATTERN=$(echo "$ESSID" | sed 's/\(....\).*/@@@@\L\1/')
                ARG3="$ESSID_PATTERN"
                
                echo ""
                echo "Using ESSID-based pattern:"
                echo "  Min length = $ARG1"
                echo "  Max length = $ARG2"
                echo "  Pattern    = $ARG3 (based on ESSID: $ESSID)"
                echo ""
                break
            else
                echo "❌ No ESSID available for pattern generation"
            fi
            ;;

        4)
            echo ""
            echo "=== Full Aircrack-ng Analysis ==="
            aircrack-ng "$FILEPATH"
            echo ""
            ;;

        x)
            echo "Exiting."
            exit 0
            ;;

        *)
            echo ""
            echo "❌ Invalid choice. Please try again."
            echo ""
            ;;
    esac
done

# --------------------------------------------------------------------
# Final command execution
# --------------------------------------------------------------------
echo "🎯 Final command:"
echo "crunch $ARG1 $ARG2 -t \"$ARG3\" --stdout | aircrack-ng -w- -b \"$BSSID\" \"$FILEPATH\""
echo ""

# Final check for required tools
if ! command -v crunch &> /dev/null; then
    echo "❌ Error: 'crunch' is not available."
    echo "💡 Install it with: sudo apt-get install crunch"
    exit 1
fi

if ! command -v aircrack-ng &> /dev/null; then
    echo "❌ Error: 'aircrack-ng' is not available."
    echo "💡 Install it with: sudo apt-get install aircrack-ng"
    exit 1
fi

# Final MAC validation before execution
if ! validate_mac "$BSSID"; then
    echo "❌ Error: Invalid BSSID format: $BSSID"
    echo "💡 BSSID must be in format: 00:11:22:33:44:55"
    exit 1
fi

read -p "Run this command? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "🚀 Starting attack..."
    echo "⏳ This may take a while. Press Ctrl+C to stop."
    echo ""
    crunch $ARG1 $ARG2 -t "$ARG3" --stdout | aircrack-ng -w- -b "$BSSID" "$FILEPATH"
else
    echo "❌ Cancelled."
fi

echo ""
echo "================================================================"
echo "💝 Support the developer!"
echo "🌐 GitHub: www.github.aissaabk"
echo "📘 Facebook: www.facebook.com/devbelmel"
echo "================================================================"
