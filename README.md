# BoabAI Skills -- Claude Code Plugin Marketplace

Production-tested [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills from BoabAI.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| `explainer-video` | Produce branded marketing explainer videos for any web app. Playwright recording + slide overlays + narration + FFmpeg assembly. | 2.1.0 |

## Installation

### Claude Code (CLI)

```bash
# Add the marketplace
/plugin marketplace add BoabAI/claude-skills

# Install a skill
/plugin install explainer-video@boabai-skills
```

### Claude Code (VS Code / JetBrains)

1. Open Claude Code in your IDE
2. Type `/plugin marketplace add BoabAI/claude-skills`
3. Type `/plugin install explainer-video@boabai-skills`

### Claude Desktop

Claude Desktop doesn't natively support Claude Code skills/plugins. To use these skills with Claude Desktop:

1. **Copy the skill prompt manually** -- open the `SKILL.md` file from this repo and paste its contents into your Claude Desktop project instructions or system prompt
2. **Reference files** -- copy the `references/` and `assets/` directories into your project so Claude Desktop can read them when you reference them in conversation
3. **Invoke manually** -- instead of `/explainer-video`, describe what you want: *"Follow the explainer video pipeline to create a marketing video for my app"*

> **Note:** Claude Desktop lacks Bash tool access and MCP tool orchestration that Claude Code provides. Some pipeline phases (FFmpeg assembly, Playwright recording) will need to be run manually in your terminal based on Claude Desktop's generated scripts.

## Usage

After installing in Claude Code, invoke a skill by name:

```
/explainer-video
```

Claude will walk you through the full pipeline -- analyzing your app, collecting branding, writing narration, recording a demo, and assembling the final video.

### Prerequisites

- **Playwright** -- `bun add -d playwright && bunx playwright install chromium`
- **FFmpeg** -- `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux)
- **A running web app** to record

### Optional Dependencies

- **ElevenLabs MCP** -- for high-quality AI narration (free alternative: `edge-tts`)
- **Composio YouTube MCP** -- for direct YouTube upload (free alternative: manual upload)

No API keys are required for the core pipeline. ElevenLabs and YouTube upload are optional enhancements.

## Contributing

1. Create a plugin directory under `plugins/` with `.claude-plugin/plugin.json` and `skills/<name>/SKILL.md`
2. Versions are synced automatically -- update the version in your plugin's `plugin.json` and the CI will update `marketplace.json` and `README.md`
3. Submit a PR

## License

MIT
