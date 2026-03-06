# BoabAI Skills -- Claude Code Plugin Marketplace

Production-tested [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills from BoabAI.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| `explainer-video` | Produce branded marketing explainer videos for any web app. Playwright recording + slide overlays + narration + FFmpeg assembly. | 0.1.0 |

## Prerequisites

- **Playwright** -- `bun add -d playwright && bunx playwright install chromium`
- **FFmpeg** -- `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)
- **A running web app** to record

No API keys required for the core pipeline. See [Optional Enhancements](#optional-enhancements) below.

---

## Claude Code

### Install

```bash
# Add the marketplace
/plugin marketplace add BoabAI/claude-skills

# Install a skill
/plugin install explainer-video@boabai-skills
```

Works in CLI, VS Code, and JetBrains -- same commands everywhere.

### Setup

Run the interactive setup script to check prerequisites and configure optional services:

```bash
bash ~/.claude/plugins/*/explainer-video/setup.sh
```

This checks for FFmpeg, Playwright, and edge-tts, then optionally configures ElevenLabs API key and Composio YouTube integration.

### Use

```
/explainer-video
```

Claude walks you through the full pipeline -- analyzing your app, collecting branding, writing narration, recording a demo, and assembling the final video.

### Claude Cowork

Cowork orchestrates Claude Code agents, so installed skills carry through automatically. Install the plugin in Claude Code (above), then any Cowork session has access.

Alternatively, paste the `SKILL.md` contents into your Cowork task instructions -- Cowork passes these to the agent as context.

---

## Claude Desktop

Claude Desktop doesn't support Claude Code plugins natively. To use these skills:

1. **Copy the skill prompt** -- open the plugin's [`SKILL.md`](plugins/explainer-video/skills/explainer-video/SKILL.md) and paste its contents into your project instructions or system prompt
2. **Copy reference files** -- add the [`references/`](plugins/explainer-video/references) and [`assets/`](plugins/explainer-video/assets) directories to your project so Claude can read them in conversation
3. **Invoke by description** -- instead of `/explainer-video`, say: *"Follow the explainer video pipeline to create a marketing video for my app"*

> **Note:** Claude Desktop lacks Bash tool access. Pipeline phases that run shell commands (Playwright recording, FFmpeg assembly) will need to be executed manually in your terminal using the scripts Claude Desktop generates.

---

## Optional Enhancements

### ElevenLabs (High-Quality Narration)

The skill automatically falls back to `edge-tts` (free, no key needed) if ElevenLabs is not configured. To enable premium voice quality:

1. Get an API key from [elevenlabs.io](https://elevenlabs.io) (free tier available)
2. Add the ElevenLabs MCP server to your Claude Code config (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "elevenlabs": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/elevenlabs-mcp-server"],
      "env": {
        "ELEVENLABS_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

3. Restart Claude Code -- the skill uses ElevenLabs automatically when available

### Composio YouTube (Direct Upload)

For direct YouTube upload from the pipeline, configure the [Composio YouTube MCP](https://docs.composio.dev). Without it, manually upload the output video.

---

## Contributing

1. Create a plugin directory under `plugins/` with `.claude-plugin/plugin.json` and `skills/<name>/SKILL.md`
2. Patch versions auto-increment on content changes via CI
3. Submit a PR

## License

MIT
