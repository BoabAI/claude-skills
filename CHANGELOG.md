# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.0.0] - 2026-03-09

### Changed
- Moved supporting files (references/, assets/) into skill directory for proper plugin cache resolution
- Replaced hardcoded absolute paths with portable `${CLAUDE_SKILL_DIR}` references
- Removed non-standard SKILL.md frontmatter fields (`tags`, `version`)
- Removed `Agent` from allowed-tools (not a standard Claude Code tool)
- Made plugin description generic (removed SMEC AI branding from metadata)
- Added `$schema` to marketplace.json matching the official Anthropic pattern
- Moved marketplace description from `metadata.description` to top level

### Added
- Full plugin.json metadata: `author`, `homepage`, `repository`, `license`, `keywords`
- Plugin-level README.md and LICENSE symlink (included in plugin cache)
- Repository `.gitignore`
- `disable-model-invocation: true` to prevent unintended auto-triggering
- This CHANGELOG

### Fixed
- Version mismatch: synced marketplace.json and README to match plugin.json at 3.0.0

## [2.0.0] - 2026-02-15

### Changed
- SMEC AI branding defaults and production learnings
- Replaced absolute paths with relative skill paths
- Rewrote description for better skill triggering

## [1.0.0] - 2026-01-20

### Added
- Initial explainer video pipeline
- Playwright screen recording and slide rendering
- FFmpeg assembly with branded overlays
- ElevenLabs / edge-tts narration support
- YouTube upload via browser automation
