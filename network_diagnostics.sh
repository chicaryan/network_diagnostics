#!/bin/bash

VERSION="1.2.0"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BOLD=$(tput bold)
RESET=$(tput sgr0)
BG=$(tput setab 0)

REPORT_FILE="network_report_$(date +%Y%m%d_%H%M%S).txt"

banner() {
    clear
    echo "${BG}${GREEN}${BOLD}"
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
    echo "${RESET}"
    echo "${BG}${CYAN}${BOLD}                      [ network_diagnostics ]${RESET}"
    echo "${BG}${YELLOW}${BOLD}                         Author : rchics${RESET}"
    echo "${BG}${GREEN}${BOLD}                         Version: v${VERSION}${RESET}"
    echo "${BG}${GREEN}  ==========================================================================${RESET}"
}

check_deps() {
    for pkg in nmap curl whois; do
        if ! command -v $pkg &>/dev/null; then
            echo "${YELLOW}[*] Installing $pkg...${RESET}"
            pkg install -y $pkg 2>/dev/null || echo "${RED}[!] Failed to install $pkg. Install manually: pkg install $pkg${RESET}"
        fi
    done
}

log() {
    echo -e "$1"
    echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$REPORT_FILE"
}

validate_host() {
    local input="$1"
    if [[ -z "$input" ]]; then
        echo "${RED}[!] Host cannot be empty.${RESET}"
        return 1
    fi
    if [[ ! "$input" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "${RED}[!] Invalid host: $input${RESET}"
        return 1
    fi
    return 0
}

validate_port_range() {
    local range="$1"
    if [[ ! "$range" =~ ^[0-9]+-[0-9]+$ ]]; then
        echo "${RED}[!] Invalid port range. Use format: 1-1024${RESET}"
        return 1
    fi
    local start end
    start=$(echo "$range" | cut -d'-' -f1)
    end=$(echo "$range" | cut -d'-' -f2)
    if (( start < 1 || end > 65535 || start > end )); then
        echo "${RED}[!] Port range must be between 1-65535 and start < end.${RESET}"
        return 1
    fi
    return 0
}

validate_duration() {
    local val="$1"
    if [[ ! "$val" =~ ^[0-9]+$ ]] || (( val < 1 || val > 3600 )); then
        echo "${RED}[!] Duration must be a number between 1 and 3600.${RESET}"
        return 1
    fi
    return 0
}

show_network_info() {
    log "\n${GREEN}[+] Network Info${RESET}"
    log "$(ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "${RED}[!] Could not retrieve network info.${RESET}")"
    log "\n${GREEN}[+] Gateway:${RESET}"
    local gw
    gw=$(ip route | grep default)
    log "${gw:-${YELLOW}[!] No gateway found.${RESET}}"
}

ping_test() {
    log "\n${GREEN}[+] Ping Test${RESET}"
    read -p "${CYAN}  Enter host (default: google.com): ${RESET}" host
    host=${host:-google.com}
    validate_host "$host" || return
    log "$(ping -c 4 "$host" 2>&1)"
}

speed_test() {
    echo "\n${GREEN}[+] Speed Test${RESET}"
    if ! command -v speedtest-cli &>/dev/null; then
        echo "${YELLOW}[*] Installing speedtest-cli...${RESET}"
        pkg install -y python 2>/dev/null && pip install speedtest-cli 2>/dev/null
        if ! command -v speedtest-cli &>/dev/null; then
            echo "${RED}[!] speedtest-cli could not be installed. Try: pip install speedtest-cli${RESET}"
            return
        fi
    fi
    speedtest-cli
}

traceroute_test() {
    log "\n${GREEN}[+] Traceroute${RESET}"
    read -p "${CYAN}  Enter host (default: google.com): ${RESET}" host
    host=${host:-google.com}
    validate_host "$host" || return
    if ! command -v traceroute &>/dev/null; then
        echo "${YELLOW}[*] Installing traceroute...${RESET}"
        pkg install -y traceroute 2>/dev/null || { echo "${RED}[!] traceroute not available.${RESET}"; return; }
    fi
    log "$(traceroute "$host" 2>&1)"
}

scan_network() {
    log "\n${GREEN}[+] Scanning Your Own Network${RESET}"
    local gateway subnet
    gateway=$(ip route | grep default | awk '{print $3}')
    if [[ -z "$gateway" ]]; then
        echo "${RED}[!] Could not detect gateway. Are you connected to a network?${RESET}"
        return
    fi
    subnet=$(echo "$gateway" | cut -d'.' -f1-3).0/24
    log "${YELLOW}[*] Subnet: $subnet${RESET}"
    log "$(nmap -sn "$subnet" 2>&1)"
}

dns_lookup() {
    log "\n${GREEN}[+] DNS Lookup${RESET}"
    read -p "${CYAN}  Enter domain: ${RESET}" domain
    if [[ -z "$domain" ]]; then
        echo "${RED}[!] Domain cannot be empty.${RESET}"; return
    fi
    validate_host "$domain" || return
    log "$(nslookup "$domain" 2>/dev/null || host "$domain" 2>/dev/null || echo "${RED}[!] DNS lookup failed.${RESET}")"
}

public_ip() {
    log "\n${GREEN}[+] Public IP & Location${RESET}"
    local ip info
    ip=$(curl -s --max-time 5 https://api.ipify.org)
    if [[ -z "$ip" ]]; then
        echo "${RED}[!] Could not retrieve public IP. Check your internet connection.${RESET}"; return
    fi
    info=$(curl -s --max-time 5 "https://ipinfo.io/$ip/json")
    log "${YELLOW}[*] Public IP: $ip${RESET}"
    log "$info"
}

port_scan() {
    log "\n${GREEN}[+] Port Scanner${RESET}"
    read -p "${CYAN}  Enter host (default: localhost): ${RESET}" host
    host=${host:-localhost}
    validate_host "$host" || return
    read -p "${CYAN}  Enter port range (default: 1-1024): ${RESET}" range
    range=${range:-1-1024}
    validate_port_range "$range" || return
    log "${YELLOW}[*] Scanning $host ports $range...${RESET}"
    log "$(nmap -p "$range" "$host" 2>&1)"
}

wifi_signal() {
    echo "\n${GREEN}[+] WiFi Signal Strength${RESET}"
    if [[ -f /proc/net/wireless ]]; then
        echo "${YELLOW}  Interface | Status | Link | Level | Noise${RESET}"
        tail -n +3 /proc/net/wireless
    elif command -v termux-wifi-connectioninfo &>/dev/null; then
        termux-wifi-connectioninfo
    else
        echo "${YELLOW}[!] WiFi info unavailable.${RESET}"
        echo "${CYAN}    To enable: pkg install termux-api && termux-setup-storage${RESET}"
    fi
}

connection_monitor() {
    echo "\n${GREEN}[+] Connection Monitor${RESET}"
    read -p "${CYAN}  Duration in seconds (default: 30): ${RESET}" duration
    duration=${duration:-30}
    validate_duration "$duration" || return
    read -p "${CYAN}  Host to monitor (default: 8.8.8.8): ${RESET}" host
    host=${host:-8.8.8.8}
    validate_host "$host" || return
    echo "${YELLOW}[*] Monitoring $host for ${duration}s... Ctrl+C to stop${RESET}"
    local success=0 fail=0
    local end=$((SECONDS + duration))
    while [[ $SECONDS -lt $end ]]; do
        if ping -c 1 -W 1 "$host" &>/dev/null; then
            echo "${GREEN}  [$(date +%H:%M:%S)] ✔ Connected${RESET}"
            ((success++))
        else
            echo "${RED}  [$(date +%H:%M:%S)] ✘ No response${RESET}"
            ((fail++))
        fi
        sleep 1
    done
    echo "\n${CYAN}  Results → ${GREEN}$success success${RESET} | ${RED}$fail failed${RESET}"
}

whois_lookup() {
    log "\n${GREEN}[+] Whois Lookup${RESET}"
    read -p "${CYAN}  Enter domain or IP: ${RESET}" target
    if [[ -z "$target" ]]; then
        echo "${RED}[!] Input cannot be empty.${RESET}"; return
    fi
    validate_host "$target" || return
    log "$(whois "$target" 2>/dev/null || echo "${RED}[!] Whois lookup failed.${RESET}")"
}

save_report() {
    echo "\n${GREEN}[+] Save Diagnostics Report${RESET}"
    echo "${YELLOW}[*] Saving to $REPORT_FILE...${RESET}"
    show_network_info
    public_ip
    echo "${GREEN}[✔] Report saved: $REPORT_FILE${RESET}"
}

menu() {
    banner
    echo "${BG}${GREEN}${BOLD}"
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
    echo "  ==========================================================================${RESET}"
    read -p "${CYAN}  root@rchics:~# ${RESET}" choice

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
        0|00)  echo "${RED}  [!] Exiting...${RESET}"; exit 0 ;;
        *)     echo "${RED}  [!] Invalid option. Choose 00-12.${RESET}" ;;
    esac
    echo "\n${YELLOW}  Press [ENTER] to return to menu...${RESET}"
    read
}

check_deps
while true; do
    menu
done
