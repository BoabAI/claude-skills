#!/bin/bash
set -euo pipefail

# BoabAI Explainer Video Skill -- Setup
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
header "Explainer Video Skill -- Setup"
echo -e "${DIM}Checks prerequisites and configures optional services.${NC}"

# -------------------------------------------------------------------
header "1. Prerequisites"

# FFmpeg
if command -v ffmpeg &>/dev/null; then
  ok "FFmpeg $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
else
  fail "FFmpeg not found"
  echo -e "     Install: ${DIM}brew install ffmpeg${NC} (macOS) or ${DIM}apt install ffmpeg${NC} (Linux)"
  ISSUES=$((ISSUES + 1))
fi

# Playwright
if command -v bunx &>/dev/null && bunx playwright --version &>/dev/null 2>&1; then
  ok "Playwright $(bunx playwright --version 2>&1)"
elif command -v npx &>/dev/null && npx playwright --version &>/dev/null 2>&1; then
  ok "Playwright $(npx playwright --version 2>&1)"
else
  fail "Playwright not found"
  echo -e "     Install: ${DIM}bun add -d playwright && bunx playwright install chromium${NC}"
  ISSUES=$((ISSUES + 1))
fi

# Chromium for Playwright
CHROMIUM_PATH=""
for p in "$HOME/Library/Caches/ms-playwright/chromium-"*/chrome-mac/Chromium.app \
         "$HOME/.cache/ms-playwright/chromium-"*/chrome-linux/chrome; do
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
    # Ensure settings directory exists
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

    if [ -f "$CLAUDE_SETTINGS" ]; then
      # Add or update ElevenLabs MCP server in existing settings
      jq --arg key "$elevenlabs_key" '
        .mcpServers.elevenlabs = {
          "command": "npx",
          "args": ["-y", "@anthropic-ai/elevenlabs-mcp-server"],
          "env": { "ELEVENLABS_API_KEY": $key }
        }
      ' "$CLAUDE_SETTINGS" > /tmp/claude-settings.json \
        && mv /tmp/claude-settings.json "$CLAUDE_SETTINGS"
    else
      # Create new settings file
      cat > "$CLAUDE_SETTINGS" << SETTINGSEOF
{
  "mcpServers": {
    "elevenlabs": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/elevenlabs-mcp-server"],
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
  warn "Skipping ElevenLabs -- skill will use edge-tts for narration"
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
  echo -e "  ${GREEN}All prerequisites met.${NC} Run ${BOLD}/explainer-video${NC} to get started."
else
  echo -e "  ${YELLOW}$ISSUES issue(s) found.${NC} Install missing prerequisites above, then re-run this script."
fi

echo ""
