#!/bin/bash

# Network Diagnostics Tool
# Run in Termux: bash network_diagnostics.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="network_report_$(date +%Y%m%d_%H%M%S).txt"

check_deps() {
    for pkg in nmap curl whois; do
        if ! command -v $pkg &>/dev/null; then
            echo -e "${YELLOW}Installing $pkg...${NC}"
            pkg install -y $pkg
        fi
    done
}

log() {
    echo -e "$1"
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$REPORT_FILE"
}

show_network_info() {
    log "\n${CYAN}=== Network Info ===${NC}"
    log "$(ip addr show 2>/dev/null || ifconfig)"
    log "\n${GREEN}Gateway:${NC}"
    log "$(ip route | grep default)"
}

ping_test() {
    log "\n${CYAN}=== Ping Test ===${NC}"
    read -p "Enter host to ping (default: google.com): " host
    host=${host:-google.com}
    log "$(ping -c 4 "$host")"
}

speed_test() {
    echo -e "\n${CYAN}=== Speed Test ===${NC}"
    if ! command -v speedtest-cli &>/dev/null; then
        pkg install -y python
        pip install speedtest-cli
    fi
    speedtest-cli
}

traceroute_test() {
    log "\n${CYAN}=== Traceroute ===${NC}"
    read -p "Enter host (default: google.com): " host
    host=${host:-google.com}
    if ! command -v traceroute &>/dev/null; then
        pkg install -y traceroute
    fi
    log "$(traceroute "$host")"
}

scan_network() {
    log "\n${CYAN}=== Scan Your Own Network ===${NC}"
    gateway=$(ip route | grep default | awk '{print $3}')
    subnet=$(echo "$gateway" | cut -d'.' -f1-3).0/24
    log "${YELLOW}Scanning subnet: $subnet${NC}"
    log "$(nmap -sn "$subnet")"
}

dns_lookup() {
    log "\n${CYAN}=== DNS Lookup ===${NC}"
    read -p "Enter domain: " domain
    log "$(nslookup "$domain" 2>/dev/null || host "$domain")"
}

# NEW: Public IP
public_ip() {
    log "\n${CYAN}=== Public IP ===${NC}"
    ip=$(curl -s https://api.ipify.org)
    info=$(curl -s "https://ipinfo.io/$ip/json")
    log "${GREEN}Public IP:${NC} $ip"
    log "$info"
}

# NEW: Port Scanner
port_scan() {
    log "\n${CYAN}=== Port Scanner ===${NC}"
    read -p "Enter host to scan (default: localhost): " host
    host=${host:-localhost}
    read -p "Enter port range (default: 1-1024): " range
    range=${range:-1-1024}
    log "${YELLOW}Scanning $host ports $range...${NC}"
    log "$(nmap -p "$range" "$host")"
}

# NEW: WiFi Signal Strength
wifi_signal() {
    echo -e "\n${CYAN}=== WiFi Signal Strength ===${NC}"
    if [ -f /proc/net/wireless ]; then
        echo -e "${GREEN}Interface | Status | Link | Level | Noise${NC}"
        cat /proc/net/wireless | tail -n +3
    else
        # Termux fallback
        termux-wifi-connectioninfo 2>/dev/null || echo -e "${YELLOW}Install Termux:API and run: pkg install termux-api${NC}"
    fi
}

# NEW: Connection Monitor
connection_monitor() {
    echo -e "\n${CYAN}=== Connection Monitor ===${NC}"
    read -p "Duration in seconds (default: 30): " duration
    duration=${duration:-30}
    read -p "Host to monitor (default: 8.8.8.8): " host
    host=${host:-8.8.8.8}
    echo -e "${YELLOW}Monitoring connection to $host for ${duration}s... Press Ctrl+C to stop${NC}"
    success=0; fail=0
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        if ping -c 1 -W 1 "$host" &>/dev/null; then
            echo -e "${GREEN}[$(date +%H:%M:%S)] Connected${NC}"
            ((success++))
        else
            echo -e "${RED}[$(date +%H:%M:%S)] No response${NC}"
            ((fail++))
        fi
        sleep 1
    done
    echo -e "\n${CYAN}Results: ${GREEN}$success success${NC} | ${RED}$fail failed${NC}"
}

# NEW: Whois Lookup
whois_lookup() {
    log "\n${CYAN}=== Whois Lookup ===${NC}"
    read -p "Enter domain or IP: " target
    log "$(whois "$target")"
}

# NEW: Save Report
save_report() {
    echo -e "\n${CYAN}=== Save Diagnostics Report ===${NC}"
    echo -e "${YELLOW}Running all diagnostics and saving to $REPORT_FILE...${NC}"
    show_network_info
    public_ip
    dns_lookup <<< "google.com"
    echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"
}

menu() {
    echo -e "\n${BLUE}==============================${NC}"
    echo -e "${BLUE}   Network Diagnostics Tool   ${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo "1.  Show Network Info"
    echo "2.  Ping Test"
    echo "3.  Speed Test"
    echo "4.  Traceroute"
    echo "5.  Scan Your Own Network (nmap)"
    echo "6.  DNS Lookup"
    echo "7.  Public IP & Location"
    echo "8.  Port Scanner"
    echo "9.  WiFi Signal Strength"
    echo "10. Connection Monitor"
    echo "11. Whois Lookup"
    echo "12. Save Diagnostics Report"
    echo "0.  Exit"
    echo -e "${BLUE}==============================${NC}"
    read -p "Choose an option: " choice

    case $choice in
        1)  show_network_info ;;
        2)  ping_test ;;
        3)  speed_test ;;
        4)  traceroute_test ;;
        5)  scan_network ;;
        6)  dns_lookup ;;
        7)  public_ip ;;
        8)  port_scan ;;
        9)  wifi_signal ;;
        10) connection_monitor ;;
        11) whois_lookup ;;
        12) save_report ;;
        0)  echo -e "${RED}Exiting...${NC}"; exit 0 ;;
        *)  echo -e "${RED}Invalid option${NC}" ;;
    esac
}

check_deps
while true; do
    menu
done
