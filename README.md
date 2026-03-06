# Claude Code Skills Marketplace

Reusable skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI. Each skill is a self-contained package that teaches Claude Code how to perform a specific workflow.

## Available Skills

| Skill | Description | Version |
|-------|-------------|---------|
| [explainer-video](skills/explainer-video/) | Produce branded marketing explainer videos for any web app. Orchestrates Playwright screen recording, slide overlays, ElevenLabs narration, and FFmpeg assembly. | 2.0.0 |

## Installation

Copy a skill directory into your Claude Code skills folder:

```bash
# Global skill (available in all projects)
cp -r skills/explainer-video ~/.claude/skills/explainer-video

# Project-local skill (available only in this project)
cp -r skills/explainer-video .claude/skills/explainer-video
```

Then invoke the skill in Claude Code:

```
/explainer-video
```

## Skill Structure

Each skill follows this structure:

```
skills/<skill-name>/
  SKILL.md              # Main skill definition (required)
  assets/               # Templates, configs, static files
  references/           # Detailed reference docs for Claude
```

The `SKILL.md` frontmatter defines metadata:

```yaml
---
name: skill-name
description: What this skill does
tags: [relevant, tags]
version: 1.0.0
user-invocable: true
allowed-tools: Bash, Read, Write, Edit
---
```

## Contributing

To add a new skill:

1. Create a directory under `skills/` with your skill name
2. Add a `SKILL.md` with proper frontmatter and pipeline instructions
3. Include any templates in `assets/` and reference docs in `references/`
4. Update the table in this README
5. Submit a PR

## License

MIT
