#!/bin/bash
# ===================================
#   Linux System Recon Tool
#   by David Khoury
#   Enhanced as we learn more Linux!
# ===================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ── Banner ──
echo -e "${CYAN}"
echo "=========================================="
echo "   LINUX SYSTEM RECON TOOL"
echo "   by David Khoury"
echo "=========================================="
echo -e "${NC}"

# ── EP1: Basic System Info ──
echo -e "${YELLOW}[+] SYSTEM INFO${NC}"
echo "────────────────────────────"
echo "  Hostname  : $(hostname)"
echo "  User      : $(whoami)"
echo "  OS        : $(uname -o)"
echo "  Kernel    : $(uname -r)"
echo "  Uptime    : $(uptime -p)"
echo ""

# ── EP2: File System Info ──
echo -e "${YELLOW}[+] FILE SYSTEM${NC}"
echo "────────────────────────────"
echo "  Current Dir : $(pwd)"
echo "  Disk Usage  :"
df -h | grep -v tmpfs
echo ""

# ── EP4: Users Info ──
echo -e "${YELLOW}[+] USERS${NC}"
echo "────────────────────────────"
echo "  Logged in   : $(who | awk '{print $1}' | sort | uniq | tr '\n' ' ')"
echo "  Total users : $(cat /etc/passwd | wc -l)"
echo "  Sudo users  :"
grep -Po '^sudo.+:\K.*$' /etc/group | tr ',' '\n' | sed 's/^/    /'
echo ""

# ── EP5: Installed Security Tools ──
echo -e "${YELLOW}[+] SECURITY TOOLS INSTALLED${NC}"
echo "────────────────────────────"
tools=("nmap" "netcat" "wireshark" "hydra" "sqlmap" "git" "python3" "pip")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo -e "  ${GREEN}[✓]${NC} $tool"
    else
        echo -e "  ${RED}[✗]${NC} $tool not installed"
    fi
done
echo ""

# ── EP6: Running Services ──
echo -e "${YELLOW}[+] RUNNING SERVICES${NC}"
echo "────────────────────────────"
systemctl list-units --type=service --state=running | grep ".service" | awk '{print "  "$1}' | head -10
echo ""

# ── Network Info ──
echo -e "${YELLOW}[+] NETWORK INFO${NC}"
echo "────────────────────────────"
echo "  Interfaces :"
ip -br addr | awk '{print "    "$1" → "$3}'
echo ""
echo "  Open Ports :"
ss -tuln | grep LISTEN | awk '{print "    "$5}' | sort
echo ""

# ── EP2: Recent Log Activity ──
echo -e "${YELLOW}[+] RECENT AUTH LOG (last 5 lines)${NC}"
echo "────────────────────────────"
if [ -f /var/log/auth.log ]; then
    tail -5 /var/log/auth.log | sed 's/^/  /'
else
    echo "  auth.log not found"
fi
echo ""

# ── EP7: Process Monitor ──
echo -e "${YELLOW}[+] TOP 10 RUNNING PROCESSES${NC}"
echo "────────────────────────────"
ps aux --sort=-%cpu | head -11 | tail -10 | awk '{print "  "$1"\t"$11}'
echo ""

# ── EP7: Suspicious Processes ──
echo -e "${YELLOW}[+] SUSPICIOUS PROCESSES CHECK${NC}"
echo "────────────────────────────"
suspects=("netcat" "nc" "ncat" "meterpreter" "shell" "backdoor")
for proc in "${suspects[@]}"; do
    result=$(ps aux | grep -iw $proc | grep -v grep | grep -v kworker | grep -v systemd)
    if [ ! -z "$result" ]; then
        echo -e "  ${RED}[!!] SUSPICIOUS: $proc found running!${NC}"
        echo "  $result"
    else
        echo -e "  ${GREEN}[OK]${NC} $proc not running"
    fi
done
echo ""

# ── EP8: Network Connections ──
echo -e "${YELLOW}[+] ACTIVE NETWORK CONNECTIONS${NC}"
echo "────────────────────────────"
ss -tunp | grep ESTAB | awk '{print "  "$5" -> "$6}' | head -10
echo ""

# ── EP8: Curl Check ──
echo -e "${YELLOW}[+] INTERNET CONNECTIVITY${NC}"
echo "────────────────────────────"
if curl -s --max-time 5 http://google.com > /dev/null; then
    echo -e "  ${GREEN}[✓]${NC} Internet is reachable"
else
    echo -e "  ${RED}[✗]${NC} No internet connection"
fi
echo ""

# ── EP9: Speed & Efficiency ──
echo -e "${YELLOW}[+] COMMAND HISTORY (last 10)${NC}"
echo "────────────────────────────"
history | tail -10 | awk '{print "  "$0}'
echo ""

echo -e "${YELLOW}[+] ALIASES SET${NC}"
echo "────────────────────────────"
alias | awk '{print "  "$0}'
echo ""

echo -e "${YELLOW}[+] ENVIRONMENT VARIABLES${NC}"
echo "────────────────────────────"
echo "  PATH    : $PATH"
echo "  HOME    : $HOME"
echo "  SHELL   : $SHELL"
echo "  USER    : $USER"
echo ""

# ── EP10: System Safety Checks ──
echo -e "${YELLOW}[+] DANGEROUS PERMISSIONS CHECK${NC}"
echo "────────────────────────────"
echo "  World-writable files in /etc:"
find /etc -maxdepth 1 -perm -o+w 2>/dev/null | sed 's/^/    /' 
if [ -z "$(find /etc -maxdepth 1 -perm -o+w 2>/dev/null)" ]; then
    echo -e "  ${GREEN}[OK]${NC} No world-writable files found in /etc"
fi
echo ""

echo -e "${YELLOW}[+] SUID FILES CHECK${NC}"
echo "────────────────────────────"
echo "  Files with SUID bit set (potential privilege escalation):"
find / -perm -u=s -type f 2>/dev/null | head -10 | sed 's/^/    /'
echo ""

echo -e "${YELLOW}[+] CRITICAL FILES INTEGRITY${NC}"
echo "────────────────────────────"
critical_files=("/etc/passwd" "/etc/shadow" "/etc/hosts" "/etc/sudoers")
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        perms=$(stat -c "%a" $file)
        echo -e "  ${GREEN}[✓]${NC} $file exists (permissions: $perms)"
    else
        echo -e "  ${RED}[✗]${NC} $file MISSING — system may be compromised!"
    fi
done
echo ""

echo -e "${YELLOW}[+] DISK SPACE WARNING${NC}"
echo "────────────────────────────"
disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ $disk_usage -gt 90 ]; then
    echo -e "  ${RED}[!!] WARNING: Disk is ${disk_usage}% full!${NC}"
elif [ $disk_usage -gt 70 ]; then
    echo -e "  ${YELLOW}[!] NOTICE: Disk is ${disk_usage}% full${NC}"
else
    echo -e "  ${GREEN}[OK]${NC} Disk usage is ${disk_usage}% — healthy"
fi
echo ""


echo -e "${CYAN}=========================================="
echo "   Recon Complete!"
echo -e "==========================================${NC}"
