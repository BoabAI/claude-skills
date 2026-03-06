# BoabAI Skills — Claude Code Plugin Marketplace

Production-tested [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills from BoabAI.

## Installation

```bash
# Add the marketplace
/plugin marketplace add BoabAI/claude-skills

# Install a skill
/plugin install explainer-video@boabai-skills
```

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| `explainer-video` | Produce branded marketing explainer videos for any web app. Playwright recording + slide overlays + narration + FFmpeg assembly. | 2.0.0 |

## Usage

After installing, invoke a skill by name:

```
/explainer-video
```

## Contributing

1. Create a plugin directory under `plugins/` with `.claude-plugin/plugin.json` and `skills/<name>/SKILL.md`
2. Add the plugin entry to `.claude-plugin/marketplace.json`
3. Submit a PR

## License

MIT
