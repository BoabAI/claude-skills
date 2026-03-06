---
name: explainer-video
description: Produce a branded marketing explainer video for any web application. Orchestrates Playwright screen recording, branded slide overlays, ElevenLabs narration, and FFmpeg assembly.
tags: [video, explainer, marketing, playwright, ffmpeg, elevenlabs, demo]
version: 2.0.0
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# Explainer Video Pipeline

Generate a professional branded marketing video for any web application. The pipeline records a live browser demo, overlays branded slides, adds professional narration, and assembles everything with FFmpeg.

## Prerequisites

- **Playwright** (`bun add -d playwright && bunx playwright install chromium`)
- **FFmpeg** (`brew install ffmpeg`)
- **ElevenLabs MCP** or **edge-tts** for narration
- A running web app to record

## Pipeline Phases

Execute each phase in order. All output goes to `scripts/video/` in the project.

### Phase 1: Analyze the App

1. Read `package.json`, `README.md`, and the main page component
2. Identify the app's primary user flow (the "happy path")
3. Note key CSS selectors, form fields, buttons, and navigation
4. Determine timing: how long does the full flow take?

### Phase 2: Branding Config

Ask the user for:
- Company/product name
- Logo file path (**SVG preferred** for crisp rendering at any size; PNG fallback)
- Brand colors (primary gradient, accent)
- Website URL
- Tagline (optional)

Create `scripts/video/branding.json`:
```json
{
  "company": "Company Name",
  "logoPath": "scripts/video/assets/logo.svg",
  "colors": {
    "bgPrimary": "#0d0618",
    "bgSecondary": "#1a0a2e",
    "accent": "rgba(139, 92, 246, 0.15)",
    "accentSolid": "#a78bfa",
    "accentSecondary": "#818cf8"
  },
  "url": "example.com",
  "tagline": "Your tagline here"
}
```

### Phase 3: Write Narration

Write a 60-90 second script (~150-200 words). See `references/narration-guide.md`.

Structure:
1. **Hook** (5-10s): What is this tool?
2. **Problem statement** (5-10s): What pain does it solve?
3. **Transition** (2s): "Let's see it in action"
4. **Demo walkthrough** (40-50s): Narrate what the viewer sees
5. **Value props** (10-15s): Privacy, speed, standards compliance
6. **CTA** (5s): "Ready to use today"

Save to `scripts/video/narration.txt`.

### Phase 4: Generate Audio

**Option A — ElevenLabs (preferred):**
Use `mcp__elevenlabs__text_to_speech` with a professional voice. Save to `scripts/video/narration-pro.mp3`.

**Option B — edge-tts (free fallback):**
```bash
edge-tts --text "$(cat scripts/video/narration.txt)" \
  --voice en-AU-WilliamNeural \
  --write-media scripts/video/narration-pro.mp3
```

Check duration: `ffprobe -v quiet -show_entries format=duration -of csv=p=0 scripts/video/narration-pro.mp3`

### Phase 5: Define Slides

Plan 7-10 branded slides. Available types: **intro, title, problem, benefits, stat, section, outro**.

Recommended narrative arc:

| # | Type | When | Content |
|---|------|------|---------|
| 1 | intro | 0-2s | Logo centered, border frame |
| 2 | title | 2-7s | Logo + title + subtitle + URL |
| 3 | problem | 7-13s | Pain points with red X markers |
| 4 | benefits | 13-18s | Solution bullet points with purple dots |
| 5 | stat | During feature 1 | Big number + label |
| 6 | section | During feature 2 | Heading + description |
| 7 | section | During feature 3 | Heading + description |
| 8 | benefits | Before outro | Second set of value props |
| 9 | stat | Before outro | Privacy/speed stat |
| 10 | outro | Final 5s | Logo + tagline + URL |

### Phase 6: Build Slide Renderer

Create `scripts/video/render-slides.ts` using Playwright to screenshot HTML slides.

Use the slide template from `~/.claude/skills/explainer-video/assets/slide-template.html` as the base. Customize CSS custom properties for the project's branding.

Key patterns:
- **Use inline SVG** for logos (not PNG base64) — renders crisp at any size
- Each slide type has its own HTML builder function
- Playwright screenshots at 1280x720
- Output to `scripts/video/assets/`

```typescript
// SVG logo — read as UTF-8 string, inject directly into HTML
const LOGO_SVG = readFileSync("assets/logo.svg", "utf-8");

// In slide HTML: wrap in a sized container
`<div class="logo-svg" style="height:200px;">${LOGO_SVG}</div>`

// Slide types with their HTML builders
type SlideType = "intro" | "title" | "problem" | "stat" | "section" | "benefits" | "outro";

// Problem slide: red X markers for pain points
case "problem": {
  const items = slide.content.items.split("|");
  return `<div class="slide-problem">
    <h2>${slide.content.heading}</h2>
    <ul class="problem-list">
      ${items.map(item => `<li><span class="problem-x">✕</span>${item}</li>`).join("\n")}
    </ul>
  </div>`;
}

// Benefits slide: purple dot markers for value props
case "benefits": {
  const items = slide.content.items.split("|");
  return `<div class="slide-benefits">
    <h2>${slide.content.heading}</h2>
    <ul class="benefits-list">
      ${items.map(item => `<li><span class="benefit-dot"></span>${item}</li>`).join("\n")}
    </ul>
  </div>`;
}
```

### Phase 7: Render Slides

```bash
bun scripts/video/render-slides.ts
```

Verify output PNGs exist and look correct.

### Phase 8: Write Recording Script

Create `scripts/video/record-demo.ts` — a Playwright script that:

1. Launches headless Chromium with `recordVideo: { dir, size: { width: 1280, height: 720 } }`
2. Navigates to the app
3. Performs the full user flow with realistic timing
4. Includes "hold" periods where slide overlays will appear

See `references/playwright-recording.md` for patterns.

**Critical timing:** Align hold periods with slide overlay timestamps. The recording should have ~5-10s of "idle" time at each slide overlay point so the demo footage isn't competing with the overlay.

### Phase 9: Write Assembly Script

Create `scripts/video/assemble.sh` — FFmpeg complex filter graph that composites everything.

See `references/ffmpeg-assembly.md` for the complete pattern.

**CRITICAL rules (learned from production bugs):**

1. **ALWAYS use full audio duration for ALL loop inputs:** `-loop 1 -t "$ADUR"`. Short durations cause FFmpeg to consume frames even when `enable` is false, exhausting the stream before later overlay windows.

2. **Use ABSOLUTE timestamps for fades**, not relative to the input stream. The fade `st` values are output timeline positions.

3. **Staggered crossfade for consecutive slides:** The incoming slide must start fading in 0.5s BEFORE the outgoing slide starts fading out. This prevents the base video (form/app) from bleeding through during transitions.

```
# CORRECT: Staggered crossfade — no bleed-through
Title fade-out:    st=6.5  (starts fading at 6.5, gone by 7.0)
Problem fade-in:   st=6.0  (starts fading at 6.0, solid by 6.5)
→ Problem is fully opaque BEFORE title starts fading out

# WRONG: Simultaneous crossfade — form bleeds through
Title fade-out:    st=6.5
Problem fade-in:   st=6.5
→ Both at 50% alpha mid-fade, base video visible
```

### Phase 10: Write Orchestrator

Create `scripts/video/generate.sh` that runs the full pipeline:

```bash
#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 1. Check narration exists
# 2. Render slides
bun "$SCRIPT_DIR/render-slides.ts"
# 3. Start dev server
bun dev &
DEV_PID=$!
trap "kill $DEV_PID 2>/dev/null || true" EXIT
# Wait for server...
# 4. Record demo
bun "$SCRIPT_DIR/record-demo.ts"
# 5. Assemble
bash "$SCRIPT_DIR/assemble.sh"
```

### Phase 11: Run and Iterate

```bash
bash scripts/video/generate.sh
```

Review the output video. Use frame extraction to verify transitions:

```bash
# Extract frames at 4fps for a time range
ffmpeg -ss 0 -t 20 -i output/explainer-video.mp4 -vf "fps=4" /tmp/frames/f_%03d.png
```

Common adjustments:
- **Slide timing off:** Adjust `enable='between(t,X,Y)'` values in `assemble.sh`
- **Form bleeds through transitions:** Use staggered crossfade (see Phase 9)
- **Recording too fast/slow:** Adjust `waitForTimeout()` values in `record-demo.ts`
- **Logo too small/large:** Adjust height in `render-slides.ts`
- **Logo grainy:** Switch from PNG to inline SVG
- **Audio doesn't match:** Re-generate narration or adjust recording timing

## File Structure

```
scripts/video/
  branding.json            # Brand config
  narration.txt            # Narration script
  narration-pro.mp3        # Generated audio
  render-slides.ts         # Slide renderer (Playwright)
  record-demo.ts           # Screen recorder (Playwright)
  assemble.sh              # FFmpeg assembly
  generate.sh              # Full pipeline orchestrator
  slides/
    slide-template.html    # HTML/CSS template
  assets/
    logo.svg               # Brand logo (SVG preferred)
    01-intro.png           # Rendered slides
    02-title.png
    02a-problem.png
    02b-benefits-start.png
    ...
output/
  demo.webm                # Raw recording
  explainer-video.mp4      # Final output
```
