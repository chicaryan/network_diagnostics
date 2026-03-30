# 📡 Network Diagnostics Tool

![Version](https://img.shields.io/badge/version-v1.2.0-brightgreen) ![Platform](https://img.shields.io/badge/platform-Termux-black) ![Author](https://img.shields.io/badge/author-rchics-cyan)

A simple shell-based network diagnostics tool built for **Termux** on Android.

> **Current Version: v1.2.0** — Added version display, input validation, better error handling, and tput color support.

---

## 📋 Features

- 📶 Show network info (IP, gateway, interface)
- 🏓 Ping test to any host
- ⚡ Internet speed test
- 🔍 Traceroute
- 🖥️ Scan devices on your own network
- 🌐 DNS lookup
- 🌍 Public IP & location info
- 🔓 Port scanner
- 📡 WiFi signal strength
- 📊 Connection monitor (stability check)
- 🔎 Whois lookup
- 💾 Save diagnostics report to file

---

## 📲 Installation in Termux

### Step 1 — Install Termux
Download **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended, not Play Store)

### Step 2 — Update Termux packages
```bash
pkg update && pkg upgrade -y
```

### Step 3 — Install Git
```bash
pkg install git -y
```

### Step 4 — Clone this repository
```bash
git clone https://github.com/chicaryan/network_diagnostics.git
```

### Step 5 — Go into the folder
```bash
cd network_diagnostics
```

### Step 6 — Give permission to the script
```bash
chmod +x network_diagnostics.sh
```

### Step 7 — Run the script
```bash
bash network_diagnostics.sh
```

---

## ⚡ One-Line Install (Run directly from GitHub)

```bash
curl -sL https://raw.githubusercontent.com/chicaryan/network_diagnostics/main/network_diagnostics.sh | bash
```

---

## 📦 Dependencies

These are auto-installed by the script if missing:

| Package | Purpose |
|---------|---------|
| `nmap` | Network scanning & port scanning |
| `curl` | HTTP requests & public IP lookup |
| `whois` | Domain/IP registration info |
| `speedtest-cli` | Speed test |
| `traceroute` | Traceroute |
| `python` | Required for speedtest-cli |
| `termux-api` | WiFi signal strength (optional) |

You can also install them manually:
```bash
pkg install nmap curl whois traceroute python -y
pip install speedtest-cli
```

---

## 🖥️ Menu Options

```
==============================
   Network Diagnostics Tool
==============================
1.  Show Network Info
2.  Ping Test
3.  Speed Test
4.  Traceroute
5.  Scan Your Own Network (nmap)
6.  DNS Lookup
7.  Public IP & Location
8.  Port Scanner
9.  WiFi Signal Strength
10. Connection Monitor
11. Whois Lookup
12. Save Diagnostics Report
0.  Exit
==============================
```

---

## 📝 Feature Details

| Option | Description |
|--------|-------------|
| Show Network Info | Displays IP address, interface, and gateway |
| Ping Test | Ping any host to test connectivity |
| Speed Test | Measures download/upload speed |
| Traceroute | Shows network hops to a destination |
| Scan Network | Lists all devices on your own network |
| DNS Lookup | Resolves domain to IP |
| Public IP & Location | Shows your external IP and geo info |
| Port Scanner | Scans open ports on a host |
| WiFi Signal Strength | Shows signal level of connected WiFi |
| Connection Monitor | Monitors internet stability over time |
| Whois Lookup | Shows domain/IP registration details |
| Save Report | Saves all diagnostics to a `.txt` file |

---

## ⚠️ Disclaimer

This tool is intended for **educational purposes** and for use on **your own network only**.
Do not use this tool on networks you do not own or have explicit permission to test.

---

## 📤 Upload to GitHub

```bash
git init
git add .
git commit -m "initial commit"
git branch -M main
git remote add origin https://github.com/chicaryan/network_diagnostics.git
git push -u origin main
```

---

## 📱 Requirements

- Android phone with **Termux** installed
- Internet connection
- Storage permission: `termux-setup-storage`

---

## 📌 Changelog

| Version | Changes |
|---------|---------|
| v1.2.0 | Added version number, input validation, error handling, tput colors |
| v1.1.0 | Added hacker theme, ASCII banner, author rchics |
| v1.0.0 | Initial release |
