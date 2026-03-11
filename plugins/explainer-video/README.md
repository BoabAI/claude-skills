# explainer-video

Produce professional animated marketing explainer videos for any web app. Orchestrates Playwright-powered product capture, animated Remotion scenes, ElevenLabs narration, background music, and sound effects.

## Install

```bash
/plugin marketplace add BoabAI/claude-skills
/plugin install explainer-video@boabai-skills
```

## Prerequisites

- **Node.js** (v18+) — `node --version`
- **Playwright** — `npm add -D playwright && npx playwright install chromium`
- **A running web app** (or public URL) to record

No API keys required for the core pipeline. ElevenLabs is optional for premium narration; the skill falls back to `edge-tts` (free) automatically. Remotion is installed automatically during the scaffold phase.

## Setup

Run the interactive setup script after installing:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/setup.sh"
```

## Usage

```
/explainer-video:generate
```

Claude walks you through the full pipeline using the primary `generate` skill. The plugin also bundles support skills for visual direction and Remotion-specific implementation guidance.

## Pipeline

1. **Analyze** — reads your app's code and identifies the primary user flow
2. **Brand** — configures company name, logo, colors, tagline
3. **Narrate** — writes TTS-friendly narration sections mapped to scenes
4. **Audio** — generates per-section narration and measures timing
5. **Capture** — takes high-resolution Playwright screenshots for the demo
6. **Scaffold** — creates a Remotion project with scene components
7. **Build** — animated React scenes with spring physics, transitions, light leaks, and SFX
8. **Compose** — arranges scenes with narration-synced timing, music, and SFX
9. **Render** — produces the final MP4 with `npx remotion render`

## What's New in v4.0.0

- **Remotion replaces FFmpeg** — every scene is an animated React component rendered to video
- **Screenshot-first demos** — Playwright captures polished product shots instead of relying on brittle live screen recordings
- **Spring physics** — natural motion for all text, logos, and UI elements
- **TransitionSeries** — fade, slide, wipe transitions with light leak overlays
- **Audio mixing** — narration + background music (auto-ducked) + transition SFX
- **DeviceFrame** — screenshot sequences play inside a styled browser mockup with camera choreography
- **Animated typography** — typewriter, stagger, fade-up text effects
- **Bundled support skills** — includes `frontend-design` and `remotion-best-practices` so the plugin ships its own design and Remotion guidance

## Skills

| Skill | Description |
|-------|-------------|
| `generate` | Primary user-facing pipeline that produces the explainer video |
| `frontend-design` | Bundled support skill for visual direction, typography, layout, and motion design decisions |
| `remotion-best-practices` | Bundled support skill for Remotion implementation patterns, animation, audio, and rendering |

## License

MIT
