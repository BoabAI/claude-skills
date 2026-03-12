#!/bin/bash
set -euo pipefail

# Explainer Video Plugin -- Setup (v4.0.0 Remotion)
# Run once after installing to check prerequisites and configure optional services.

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok() { echo -e "  ${GREEN}OK${NC} $1"; }
warn() { echo -e "  ${YELLOW}--${NC} $1"; }
fail() { echo -e "  ${RED}MISSING${NC} $1"; }
header() { echo -e "\n${BOLD}${CYAN}$1${NC}"; }

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
ISSUES=0

# -------------------------------------------------------------------
header "Explainer Video Plugin -- Setup (v4.0.0 Remotion)"
echo -e "${DIM}Checks prerequisites and configures optional services.${NC}"

# -------------------------------------------------------------------
header "1. Prerequisites"

# Node.js
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 18 ]; then
    ok "Node.js $NODE_VER"
  else
    fail "Node.js $NODE_VER (v18+ required for Remotion)"
    ISSUES=$((ISSUES + 1))
  fi
else
  fail "Node.js not found (v18+ required)"
  echo -e "     Install: ${DIM}https://nodejs.org${NC} or ${DIM}nvm install 18${NC}"
  ISSUES=$((ISSUES + 1))
fi

# npm
if command -v npm &>/dev/null; then
  ok "npm $(npm --version)"
else
  fail "npm not found"
  ISSUES=$((ISSUES + 1))
fi

# Playwright
if command -v npx &>/dev/null && npx playwright --version &>/dev/null 2>&1; then
  ok "Playwright $(npx playwright --version 2>&1)"
elif command -v bunx &>/dev/null && bunx playwright --version &>/dev/null 2>&1; then
  ok "Playwright $(bunx playwright --version 2>&1)"
else
  warn "Playwright not found (will be installed during pipeline)"
  echo -e "     Install: ${DIM}npm add -D playwright && npx playwright install chromium${NC}"
fi

# Chromium for Playwright
CHROMIUM_PATH=""
for p in "$HOME/Library/Caches/ms-playwright/chromium-"*/chrome-mac/Chromium.app \
         "$HOME/.cache/ms-playwright/chromium-"*/chrome-linux/chrome \
         "$HOME/Library/Caches/ms-playwright/chromium-"*; do
  if [ -e "$p" ]; then CHROMIUM_PATH="$p"; break; fi
done
if [ -n "$CHROMIUM_PATH" ]; then
  ok "Chromium browser installed"
else
  warn "Chromium browser not detected (Playwright may install it on first run)"
fi

# edge-tts (free fallback)
if command -v edge-tts &>/dev/null; then
  ok "edge-tts (free TTS fallback)"
else
  warn "edge-tts not installed (free narration fallback)"
  echo -e "     Install: ${DIM}pip install edge-tts${NC}"
fi

# -------------------------------------------------------------------
header "2. Narration Voice (optional)"
echo -e "${DIM}ElevenLabs provides premium AI voices. Without it, the skill${NC}"
echo -e "${DIM}falls back to edge-tts (free, no key needed).${NC}\n"

read -rp "Do you have an ElevenLabs API key? [y/N] " has_elevenlabs

if [[ "$has_elevenlabs" =~ ^[Yy] ]]; then
  read -rp "ElevenLabs API key: " elevenlabs_key

  if [ -z "$elevenlabs_key" ]; then
    warn "No key entered, skipping ElevenLabs setup"
  else
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

    if [ -f "$CLAUDE_SETTINGS" ]; then
      jq --arg key "$elevenlabs_key" '
        .mcpServers.elevenlabs = {
          "command": "uvx",
          "args": ["elevenlabs-mcp"],
          "env": { "ELEVENLABS_API_KEY": $key }
        }
      ' "$CLAUDE_SETTINGS" > /tmp/claude-settings.json \
        && mv /tmp/claude-settings.json "$CLAUDE_SETTINGS"
    else
      cat > "$CLAUDE_SETTINGS" << SETTINGSEOF
{
  "mcpServers": {
    "elevenlabs": {
      "command": "uvx",
      "args": ["elevenlabs-mcp"],
      "env": {
        "ELEVENLABS_API_KEY": "$elevenlabs_key"
      }
    }
  }
}
SETTINGSEOF
    fi

    ok "ElevenLabs MCP added to $CLAUDE_SETTINGS"
    echo -e "     ${DIM}Restart Claude Code to activate${NC}"
  fi
else
  warn "Skipping ElevenLabs -- plugin will use edge-tts for narration"
fi

# -------------------------------------------------------------------
header "3. YouTube Upload (optional)"
echo -e "${DIM}Composio YouTube MCP enables direct upload from the pipeline.${NC}"
echo -e "${DIM}Without it, you can manually upload the output video.${NC}\n"

read -rp "Set up Composio YouTube integration? [y/N] " has_composio

if [[ "$has_composio" =~ ^[Yy] ]]; then
  echo ""
  echo -e "  Composio requires OAuth setup through their dashboard."
  echo -e "  1. Sign up at ${CYAN}https://app.composio.dev${NC}"
  echo -e "  2. Connect your YouTube account"
  echo -e "  3. Add the Composio MCP server to Claude Code"
  echo -e ""
  echo -e "  ${DIM}See: https://docs.composio.dev/mcp/mcp-tools${NC}"
  warn "Manual setup required -- follow the steps above"
else
  warn "Skipping YouTube upload -- you can upload videos manually"
fi

# -------------------------------------------------------------------
header "Summary"

if [ $ISSUES -eq 0 ]; then
  echo -e "  ${GREEN}All prerequisites met.${NC} Run ${BOLD}/explainer-video:generate${NC} to get started."
else
  echo -e "  ${YELLOW}$ISSUES issue(s) found.${NC} Install missing prerequisites above, then re-run this script."
fi

echo ""
