#!/bin/bash

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BGREEN='\033[42m'
BBLACK='\033[40m'
NC='\033[0m'

REPORT_FILE="network_report_$(date +%Y%m%d_%H%M%S).txt"

banner() {
    clear
    echo -e "${BBLACK}${GREEN}"
    echo "  ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗"
    echo "  ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝"
    echo "  ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ "
    echo "  ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ "
    echo "  ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗"
    echo "  ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo ""
    echo "  ██████╗ ██╗ █████╗  ██████╗ ███╗   ██╗ ██████╗ ███████╗████████╗██╗ ██████╗███████╗"
    echo "  ██╔══██╗██║██╔══██╗██╔════╝ ████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██║██╔════╝██╔════╝"
    echo "  ██║  ██║██║███████║██║  ███╗██╔██╗ ██║██║   ██║███████╗   ██║   ██║██║     ███████╗"
    echo "  ██║  ██║██║██╔══██║██║   ██║██║╚██╗██║██║   ██║╚════██║   ██║   ██║██║     ╚════██║"
    echo "  ██████╔╝██║██║  ██║╚██████╔╝██║ ╚████║╚██████╔╝███████║   ██║   ██║╚██████╗███████║"
    echo "  ╚═════╝ ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚══════╝"
    echo -e "${NC}"
    echo -e "${BBLACK}${CYAN}                      [ network_diagnostics ]${NC}"
    echo -e "${BBLACK}${YELLOW}                         Author: rchics${NC}"
    echo -e "${BBLACK}${GREEN}  ==========================================================================${NC}"
}

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
    log "\n${GREEN}[+] Network Info${NC}"
    log "$(ip addr show 2>/dev/null || ifconfig)"
    log "\n${GREEN}[+] Gateway:${NC}"
    log "$(ip route | grep default)"
}

ping_test() {
    log "\n${GREEN}[+] Ping Test${NC}"
    read -p "$(echo -e ${CYAN}Enter host \(default: google.com\): ${NC})" host
    host=${host:-google.com}
    log "$(ping -c 4 "$host")"
}

speed_test() {
    echo -e "\n${GREEN}[+] Speed Test${NC}"
    if ! command -v speedtest-cli &>/dev/null; then
        pkg install -y python
        pip install speedtest-cli
    fi
    speedtest-cli
}

traceroute_test() {
    log "\n${GREEN}[+] Traceroute${NC}"
    read -p "$(echo -e ${CYAN}Enter host \(default: google.com\): ${NC})" host
    host=${host:-google.com}
    if ! command -v traceroute &>/dev/null; then
        pkg install -y traceroute
    fi
    log "$(traceroute "$host")"
}

scan_network() {
    log "\n${GREEN}[+] Scanning Your Own Network${NC}"
    gateway=$(ip route | grep default | awk '{print $3}')
    subnet=$(echo "$gateway" | cut -d'.' -f1-3).0/24
    log "${YELLOW}[*] Subnet: $subnet${NC}"
    log "$(nmap -sn "$subnet")"
}

dns_lookup() {
    log "\n${GREEN}[+] DNS Lookup${NC}"
    read -p "$(echo -e ${CYAN}Enter domain: ${NC})" domain
    log "$(nslookup "$domain" 2>/dev/null || host "$domain")"
}

public_ip() {
    log "\n${GREEN}[+] Public IP & Location${NC}"
    ip=$(curl -s https://api.ipify.org)
    info=$(curl -s "https://ipinfo.io/$ip/json")
    log "${YELLOW}[*] Public IP: $ip${NC}"
    log "$info"
}

port_scan() {
    log "\n${GREEN}[+] Port Scanner${NC}"
    read -p "$(echo -e ${CYAN}Enter host \(default: localhost\): ${NC})" host
    host=${host:-localhost}
    read -p "$(echo -e ${CYAN}Enter port range \(default: 1-1024\): ${NC})" range
    range=${range:-1-1024}
    log "${YELLOW}[*] Scanning $host ports $range...${NC}"
    log "$(nmap -p "$range" "$host")"
}

wifi_signal() {
    echo -e "\n${GREEN}[+] WiFi Signal Strength${NC}"
    if [ -f /proc/net/wireless ]; then
        echo -e "${YELLOW}Interface | Status | Link | Level | Noise${NC}"
        cat /proc/net/wireless | tail -n +3
    else
        termux-wifi-connectioninfo 2>/dev/null || echo -e "${YELLOW}[!] Install Termux:API → pkg install termux-api${NC}"
    fi
}

connection_monitor() {
    echo -e "\n${GREEN}[+] Connection Monitor${NC}"
    read -p "$(echo -e ${CYAN}Duration in seconds \(default: 30\): ${NC})" duration
    duration=${duration:-30}
    read -p "$(echo -e ${CYAN}Host to monitor \(default: 8.8.8.8\): ${NC})" host
    host=${host:-8.8.8.8}
    echo -e "${YELLOW}[*] Monitoring $host for ${duration}s... Ctrl+C to stop${NC}"
    success=0; fail=0
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        if ping -c 1 -W 1 "$host" &>/dev/null; then
            echo -e "${GREEN}[$(date +%H:%M:%S)] ✔ Connected${NC}"
            ((success++))
        else
            echo -e "${RED}[$(date +%H:%M:%S)] ✘ No response${NC}"
            ((fail++))
        fi
        sleep 1
    done
    echo -e "\n${CYAN}Results → ${GREEN}$success success${NC} | ${RED}$fail failed${NC}"
}

whois_lookup() {
    log "\n${GREEN}[+] Whois Lookup${NC}"
    read -p "$(echo -e ${CYAN}Enter domain or IP: ${NC})" target
    log "$(whois "$target")"
}

save_report() {
    echo -e "\n${GREEN}[+] Save Diagnostics Report${NC}"
    echo -e "${YELLOW}[*] Saving to $REPORT_FILE...${NC}"
    show_network_info
    public_ip
    dns_lookup <<< "google.com"
    echo -e "${GREEN}[✔] Report saved: $REPORT_FILE${NC}"
}

menu() {
    banner
    echo -e "${BBLACK}${GREEN}"
    echo "  [01]  Show Network Info"
    echo "  [02]  Ping Test"
    echo "  [03]  Speed Test"
    echo "  [04]  Traceroute"
    echo "  [05]  Scan Your Own Network"
    echo "  [06]  DNS Lookup"
    echo "  [07]  Public IP & Location"
    echo "  [08]  Port Scanner"
    echo "  [09]  WiFi Signal Strength"
    echo "  [10]  Connection Monitor"
    echo "  [11]  Whois Lookup"
    echo "  [12]  Save Diagnostics Report"
    echo "  [00]  Exit"
    echo -e "  ==========================================================================${NC}"
    read -p "$(echo -e ${CYAN}  root@rchics:~# ${NC})" choice

    case $choice in
        1|01)  show_network_info ;;
        2|02)  ping_test ;;
        3|03)  speed_test ;;
        4|04)  traceroute_test ;;
        5|05)  scan_network ;;
        6|06)  dns_lookup ;;
        7|07)  public_ip ;;
        8|08)  port_scan ;;
        9|09)  wifi_signal ;;
        10)    connection_monitor ;;
        11)    whois_lookup ;;
        12)    save_report ;;
        0|00)  echo -e "${RED}  [!] Exiting...${NC}"; exit 0 ;;
        *)     echo -e "${RED}  [!] Invalid option${NC}" ;;
    esac
    echo -e "\n${YELLOW}  Press [ENTER] to return to menu...${NC}"
    read
}

check_deps
while true; do
    menu
done
