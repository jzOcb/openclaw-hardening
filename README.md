# 🔒 OpenClaw Hardening Kit

Security hardening + token optimization for your OpenClaw / Clawdbot deployment. One kit, production-ready.

> **Who is this for?** Anyone running OpenClaw on a VPS or cloud server. Local Mac users can still benefit from the token optimization sections.

[🇨🇳 中文版 README](./README_CN.md)

---

## Why?

OpenClaw's default configuration is **not secure**. From the official docs:

> *"Running an AI agent with shell access on your machine is... spicy. There is no 'perfectly secure' setup."*

Specific risks:
- SSH password login enabled → brute force attacks
- Gateway port exposed to the internet → unauthorized access
- API keys stored in plaintext → credential leaks
- Session logs unencrypted → privacy exposure
- All traffic routed through the most expensive model → money burned

**This repo provides a battle-tested hardening playbook.**

---

## Quick Start

```bash
git clone https://github.com/jzOcb/openclaw-hardening.git
cd openclaw-hardening

# 1. Audit your current security posture
bash security/audit.sh

# 2. One-click hardening (interactive, confirms each step)
sudo bash security/harden.sh

# 3. Apply secure Gateway config
cp config/openclaw-secure.json5 ~/.openclaw/openclaw.json.example
# Manually merge into your openclaw.json

# 4. Install recommended skills
bash setup/install-skills.sh
```

---

## 📁 Repo Structure

```
openclaw-hardening/
├── README.md                    # Chinese docs
├── README_EN.md                 # English docs (you are here)
├── security/
│   ├── audit.sh                 # Security audit (9 checks)
│   └── harden.sh                # One-click hardening (UFW+SSH+fail2ban+Tailscale)
├── config/
│   ├── openclaw-secure.json5    # Secure Gateway config template
│   └── token-optimization.json5 # Token optimization config template
├── setup/
│   └── install-skills.sh        # Recommended skills installer
└── docs/
    ├── SECURITY.md              # Security deep dive
    ├── TOKEN-OPTIMIZATION.md    # Token cost optimization
    └── MODEL-ROUTING.md         # Multi-model routing guide
```

---

## 🛡️ Security Hardening

### audit.sh — Security Audit

Checks 9 security indicators:

| # | Check | What it looks for |
|---|-------|-------------------|
| 1 | SSH config | Port, password auth, root login |
| 2 | Firewall | UFW enabled and configured |
| 3 | fail2ban | Brute force protection active |
| 4 | Open ports | Unnecessary port exposure |
| 5 | Gateway config | Bind address, auth mode |
| 6 | Tailscale | Secure remote access setup |
| 7 | Credential storage | Plaintext API keys |
| 8 | File permissions | Config and log file permissions |
| 9 | Browser control | Port 18791 exposure |

```bash
bash security/audit.sh
```

### harden.sh — Hardening Script

Interactive execution — confirms before each step:

1. **UFW Firewall** — Allow SSH only, deny all other inbound
2. **SSH Hardening** — Custom port, disable password auth, disable root, limit retries
3. **fail2ban** — Ban IP after 3 failures for 1 hour
4. **Tailscale Setup** — Secure remote access (replaces public port exposure)

```bash
sudo bash security/harden.sh
```

> ⚠️ **Important:** Keep your current SSH session open while running harden.sh. Open a second terminal to test the new port before closing!

---

## 💰 Token Optimization

### The Problem

OpenClaw defaults to using the same model for everything. If you're on Claude Opus, every heartbeat, every sub-agent, every routine check burns premium tokens.

### The Solution: Model Tiering

| Task Type | Recommended Model | Relative Cost |
|-----------|------------------|---------------|
| Main conversation | Claude Opus 4.5 | $$$$$ |
| Sub-agents | Claude Sonnet 4 | $ |
| Heartbeat checks | Claude Sonnet 4 | $ |
| Fallback | Claude Sonnet 4 | $ |

### Configuration

Merge into `~/.openclaw/openclaw.json`:

```json5
{
  agents: {
    defaults: {
      // Primary model
      model: { primary: "anthropic/claude-opus-4-5" },
      
      // Cheaper model for sub-agents
      subagents: { model: "anthropic/claude-sonnet-4-5" },
      
      // NOTE: fallbacks not supported in 2026.1.24-1
      // Use /model command to switch manually if needed
      
      // Heartbeat interval (55min keeps 1h cache warm)
      heartbeat: { every: "55m" },
      
      // Auto-prune old tool outputs
      contextPruning: { mode: "cache-ttl", ttl: "1h" },
    }
  }
}
```

### Expected Savings

- Heartbeats no longer burn Opus → **5x cheaper**
- Sub-agents auto-route to Sonnet → **5x cheaper**
- Cache warming reduces duplicate writes → **saves cache write costs**
- Estimated overall savings: **30–50%**

### Manual Model Switching

Switch models on the fly in chat:
```
/model              # Search available models
/model sonnet       # Switch to Sonnet
/new                # Recommended: start new session before switching
```

---

## 🔌 Recommended Skills

15 curated high-value skills:

| Category | Skill | Purpose |
|----------|-------|---------|
| Security | clawdbot-security-suite | Command sanitization, pattern detection |
| Infra | digital-ocean | DigitalOcean server management |
| Infra | tailscale | Tailscale network management |
| Finance | polymarket | Prediction market data |
| Finance | ibkr-trader | IBKR trading automation |
| Finance | yahoo-finance | Stock & financial data |
| Search | brave-search | Brave Search API |
| Search | tavily | AI-optimized search |
| Search | last30days | Recent Reddit/X/Web results |
| Tools | duckdb-en | SQL data analysis |
| Tools | youtube-summarizer | YouTube video summaries |
| Tools | auto-updater | Auto-update OpenClaw |
| Tools | search | General web search |
| Maintenance | skills-audit | Skills security audit |
| Docs | clawddocs | Official docs expert |

```bash
bash setup/install-skills.sh
```

---

## 🙏 Credits

- [Tom Crawshaw (@tomcrawshaw01)](https://x.com/tomcrawshaw01) — [Security hardening guide](https://x.com/tomcrawshaw01/status/2018348937208627380) (31.4K views) & [video walkthrough](https://youtu.be/qIJXGLfoxyg)
- [OpenClaw Official Security Docs](https://docs.clawd.bot)
- [歸藏 (@op7418)](https://x.com/op7418) — Model configuration tutorial
- [huangserva (@servasyy_ai)](https://x.com/servasyy_ai) — Security vulnerability deep dive
- [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) — Skills directory

---

## 📜 License

MIT — Use freely, attribution appreciated.

---

## 🤝 Contributing

PRs welcome! Especially:
- Additional security checks
- Hardening scripts for other cloud providers (AWS, Hetzner, etc.)
- More token optimization techniques
- Model routing configs for other providers (OpenAI, DeepSeek, Gemini, etc.)
