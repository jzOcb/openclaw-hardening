#!/bin/bash
# ============================================
# Verify Your Bot Is Actually Hidden
# Tests public vs. private network access
# Based on: https://x.com/tomcrawshaw01/status/2018348937208627380
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Verifying OpenClaw Security${NC}"
echo "=========================================="
echo ""

# Get OpenClaw port from docker
OPENCLAW_PORT=$(docker ps --format '{{.Ports}}' 2>/dev/null | grep -oE '0\.0\.0\.0:([0-9]+)' | head -1 | cut -d: -f2)

if [ -z "$OPENCLAW_PORT" ]; then
    echo -e "${RED}❌ OpenClaw container not found${NC}"
    echo "  Run: docker ps"
    exit 1
fi

echo -e "OpenClaw port: ${YELLOW}$OPENCLAW_PORT${NC}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "unknown")
echo -e "Public IP: ${YELLOW}$PUBLIC_IP${NC}"
echo ""

# Get Tailscale IP
if command -v tailscale &>/dev/null && tailscale status &>/dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)
    TAILSCALE_URL=$(tailscale serve status 2>/dev/null | grep -oE 'https://[^[:space:]]+\.ts\.net' | head -1)
    echo -e "Tailscale IP: ${GREEN}$TAILSCALE_IP${NC}"
    if [ -n "$TAILSCALE_URL" ]; then
        echo -e "Tailscale URL: ${GREEN}$TAILSCALE_URL${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Tailscale not running${NC}"
    TAILSCALE_IP=""
fi

echo ""
echo "=========================================="
echo -e "${YELLOW}Testing Public Access (should FAIL)...${NC}"
echo ""

# Test public IP (should be blocked)
PUBLIC_TEST_URL="http://$PUBLIC_IP:$OPENCLAW_PORT"
echo -e "Testing: ${YELLOW}$PUBLIC_TEST_URL${NC}"

if timeout 5 curl -s -o /dev/null -w "%{http_code}" "$PUBLIC_TEST_URL" 2>/dev/null | grep -q "200"; then
    echo -e "${RED}❌ EXPOSED! Public IP is accessible${NC}"
    echo ""
    echo -e "${RED}🚨 Your OpenClaw is NOT secured!${NC}"
    echo "  Anyone can access: $PUBLIC_TEST_URL"
    echo ""
    echo "Fix it:"
    echo "  1. Check firewall: sudo ufw status"
    echo "  2. Block port: sudo ufw deny $OPENCLAW_PORT"
    echo "  3. Re-run this test"
    exit 1
else
    echo -e "${GREEN}✅ GOOD: Public access blocked${NC}"
fi

echo ""
echo "=========================================="

if [ -n "$TAILSCALE_URL" ]; then
    echo -e "${YELLOW}Testing Private Access (should WORK)...${NC}"
    echo ""
    echo -e "Testing: ${YELLOW}$TAILSCALE_URL${NC}"
    
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" "$TAILSCALE_URL" 2>/dev/null | grep -qE "200|401|403"; then
        echo -e "${GREEN}✅ GOOD: Tailscale access works${NC}"
        echo "  (401/403 is OK — means auth is working)"
    else
        echo -e "${RED}⚠️  Tailscale URL not responding${NC}"
        echo "  Check: tailscale serve status"
    fi
fi

echo ""
echo "=========================================="
echo -e "${GREEN}🔒 Security Status Summary${NC}"
echo "=========================================="
echo ""

# Firewall check
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
    echo -e "${GREEN}✅${NC} Firewall: Active"
    if sudo ufw status | grep -q "$OPENCLAW_PORT"; then
        echo -e "${GREEN}✅${NC} Port $OPENCLAW_PORT: Blocked by firewall"
    else
        echo -e "${YELLOW}⚠️${NC}  Port $OPENCLAW_PORT not explicitly blocked"
    fi
else
    echo -e "${RED}❌${NC} Firewall: Inactive"
fi

# fail2ban check
if systemctl is-active fail2ban &>/dev/null; then
    echo -e "${GREEN}✅${NC} fail2ban: Running"
else
    echo -e "${YELLOW}⚠️${NC}  fail2ban: Not running"
fi

# Tailscale check
if [ -n "$TAILSCALE_IP" ]; then
    echo -e "${GREEN}✅${NC} Tailscale: Connected ($TAILSCALE_IP)"
else
    echo -e "${RED}❌${NC} Tailscale: Not running"
fi

# Auto-updates check
if systemctl is-enabled unattended-upgrades &>/dev/null; then
    echo -e "${GREEN}✅${NC} Auto-updates: Enabled"
else
    echo -e "${YELLOW}⚠️${NC}  Auto-updates: Not configured"
    echo "  Run: sudo bash security/auto-updates.sh"
fi

echo ""

# Final verdict
if sudo ufw status 2>/dev/null | grep -q "Status: active" && \
   systemctl is-active fail2ban &>/dev/null && \
   [ -n "$TAILSCALE_IP" ]; then
    echo -e "${GREEN}🎉 Your OpenClaw is properly secured!${NC}"
    echo ""
    echo "Access your bot:"
    if [ -n "$TAILSCALE_URL" ]; then
        echo "  $TAILSCALE_URL?token=YOUR_TOKEN"
        echo ""
        echo "Get token: docker inspect \$(docker ps -q) | grep -i OPENCLAW_GATEWAY_TOKEN"
    fi
else
    echo -e "${YELLOW}⚠️  Some security features are missing${NC}"
    echo ""
    echo "Run the full hardening:"
    echo "  sudo bash security/harden.sh"
fi

echo ""
