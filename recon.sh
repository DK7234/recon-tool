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

echo -e "${CYAN}=========================================="
echo "   Recon Complete!"
echo -e "==========================================${NC}"
