#!/bin/bash
# ============================================
# Auto Security Updates Setup
# Based on: https://x.com/tomcrawshaw01/status/2018348937208627380
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[Auto Updates] Installing unattended-upgrades...${NC}"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash auto-updates.sh"
    exit 1
fi

# Install unattended-upgrades
apt-get update -qq
apt-get install -y unattended-upgrades

# Configure (select "Yes" automatically)
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# Verify it's enabled
if systemctl is-enabled unattended-upgrades &>/dev/null; then
    echo -e "${GREEN}✅ Auto security updates enabled${NC}"
    echo "  Your server will now patch itself automatically"
    echo "  Check status: systemctl status unattended-upgrades"
else
    echo "⚠️  May need manual verification"
    echo "  Run: sudo systemctl enable unattended-upgrades"
fi

# Optional: Configure email notifications (if you want them)
if [ -n "$ADMIN_EMAIL" ]; then
    echo "Unattended-Upgrade::Mail \"$ADMIN_EMAIL\";" >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo "  Email notifications configured for: $ADMIN_EMAIL"
fi

echo ""
echo "Done. One less thing to worry about."
