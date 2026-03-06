---
name: explainer-video
description: Produce a branded SMEC AI marketing explainer video for any web application. Orchestrates Playwright screen recording, branded slide overlays, ElevenLabs narration, and FFmpeg assembly. Works across any project repo.
tags: [video, explainer, marketing, playwright, ffmpeg, elevenlabs, demo, smec-ai]
version: 3.0.0
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# SMEC AI Explainer Video Pipeline

Generate a professional SMEC AI branded marketing video for any web application. The pipeline records a live browser demo, overlays branded slides, adds professional narration, and assembles everything with FFmpeg. This skill works across any project repo — it creates the `scripts/video/` directory in the target project.

## Prerequisites

- **Playwright** (`bun add -d playwright && bunx playwright install chromium`)
- **FFmpeg** (`brew install ffmpeg`)
- **ElevenLabs MCP** or **edge-tts** for narration
- A running web app to record

## Architecture Note

The recorded app may be **fully client-side** — all processing happens in the browser with the hosting platform (e.g. AWS Amplify, Vercel, Netlify) just serving static files. No patient/user data touches the server. When writing narration and slides, emphasise this as a privacy/data sovereignty feature if applicable (e.g. "Everything runs locally in the browser. No data leaves the device.").

## Pipeline Phases

Execute each phase in order. All output goes to `scripts/video/` in the target project.

### Phase 1: Analyze the App

1. Read `package.json`, `README.md`, and the main page component
2. Identify the app's primary user flow (the "happy path")
3. Note key CSS selectors, form fields, buttons, and navigation
4. Determine timing: how long does the full flow take?

### Phase 2: Branding Config

Confirm or override these defaults with the user:
- **Company/product name** — default: **SMEC AI**
- **Logo** — default: SMEC AI SVG logo. Build the SVG from the `SmecLogo.tsx` component (house icon + person + "SMEC AI" text, purple gradient `#8B5CF6` → `#A855F7`). PNG fallback: `smec_ai_logo_horizontal.png` (found in multiple SMEC projects and `~/.claude/skills/markdown-to-pdf/`).
- **Brand colors** — default: dark purple theme (`#0d0618` bg, `#a78bfa` accent). Ask the user if project-specific.
- **Website URL** — default: **smecai.au**
- **Tagline** — ask the user (project-specific)

**Recording approach** — default: **record against localhost** (start dev server, record with Playwright)

**Voice** — default: **Male Australian accent** (ElevenLabs or edge-tts `en-AU-WilliamNeural`)

Create `scripts/video/branding.json`:
```json
{
  "company": "SMEC AI",
  "logoPath": "scripts/video/assets/logo.svg",
  "colors": {
    "bgPrimary": "#0d0618",
    "bgSecondary": "#1a0a2e",
    "accent": "rgba(139, 92, 246, 0.15)",
    "accentSolid": "#a78bfa",
    "accentSecondary": "#818cf8"
  },
  "url": "smecai.au",
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

**Pronunciation gotchas for TTS (IMPORTANT):**
- **SMEC AI** — write as **"Smeck A I"** in narration text so TTS pronounces it correctly (not "smee-k" or "smek-ay"). Similarly write **"Smeck A I dot au"** for the URL, not "smecai.au".
- **Avoid "analyses"** (verb) — TTS reads it as the noun ("uh-NAL-uh-seez"). Use "reviews", "processes", or "examines" instead.
- **Spell out abbreviations** that TTS might mangle: ".docx" → "dot docx", "PDF" is fine as-is.
- **Test the audio** before full assembly — listen for mispronunciations and rephrase problem words.

Save to `scripts/video/narration.txt`.

### Phase 4: Generate Audio

**Voice default:** Male Australian accent.

**Option A — ElevenLabs (preferred):**
Use `mcp__elevenlabs__text_to_speech` with a professional male Australian voice.

**IMPORTANT: Voice library vs account voices.** `search_voice_library` returns PUBLIC voices that are NOT usable until added to your account. Use `search_voices` (no "library") to find voices already in the account. If no suitable voice exists, use an account voice like "startup presentation" or fall back to edge-tts.

Save to `scripts/video/narration-pro.mp3`.

**Option B — edge-tts (free fallback):**
```bash
edge-tts --text "$(cat scripts/video/narration.txt)" \
  --voice en-AU-WilliamNeural \
  --write-media scripts/video/narration-pro.mp3
```

Check duration: `ffprobe -v quiet -show_entries format=duration -of csv=p=0 scripts/video/narration-pro.mp3`

### Phase 5: Define Slides

Plan 7-10 branded slides. Available types: **intro, title, problem, benefits, stat, section, outro**.

**Do NOT include `section-line` divs** (gradient accent bars under headings) — they look out of place in most designs. Keep slides clean with just headings + content.

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
- **No section-line divs** — omit the gradient bar elements

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

// Benefits slide: purple dot markers for value props (NO section-line div)
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

**Recording must be >= narration duration.** If the recording is shorter, use `tpad=stop_mode=clone:stop_duration=15` in the FFmpeg filter to pad with the last frame. Processing times vary between runs (caching effects), so always pad.

**Slide overlap strategy for form-filling demos:** Start filling form fields BEFORE the last slide fades out. The first few fields fill UNDER the slide (invisible), so when the slide fades, the viewer sees the form partially filled and the cursor actively typing — more engaging than watching an empty form. Key: ensure the most interesting interaction (e.g. autocomplete dropdown, dynamic validation) happens AFTER the slide fades, not underneath it.

**Google Places Autocomplete in Playwright recordings:** Headless Playwright can trigger Google Places autocomplete. Type a partial address with `pressSequentially()`, wait for `.pac-container .pac-item` selector, then click the first suggestion. Include a fallback to manual entry in case the API doesn't respond. The autocomplete dropdown renders normally in headless mode.

### Phase 9: Write Assembly Script

Create `scripts/video/assemble.sh` — FFmpeg complex filter graph that composites everything.

See `references/ffmpeg-assembly.md` for the complete pattern.

**CRITICAL rules (learned from production bugs):**

1. **ALWAYS use full audio duration for ALL loop inputs:** `-loop 1 -t "$ADUR"`. Short durations cause FFmpeg to consume frames even when `enable` is false, exhausting the stream before later overlay windows.

2. **Use ABSOLUTE timestamps for fades**, not relative to the input stream. The fade `st` values are output timeline positions.

3. **Staggered crossfade for consecutive slides:** The incoming slide must start fading in 0.5s BEFORE the outgoing slide starts fading out. This prevents the base video (form/app) from bleeding through during transitions.

4. **NO bash comments inside filter_complex string.** FFmpeg treats `#` as part of the filter syntax and fails with "Trailing garbage" errors. Put all comments OUTSIDE the filter_complex block.

5. **Pad short recordings:** Add `tpad=stop_mode=clone:stop_duration=15` to the base video filter chain to clone the last frame if the recording is shorter than the audio.

```
# CORRECT: Staggered crossfade — no bleed-through
Title fade-out:    st=6.5  (starts fading at 6.5, gone by 7.0)
Problem fade-in:   st=6.0  (starts fading at 6.0, solid by 6.5)
-> Problem is fully opaque BEFORE title starts fading out

# WRONG: Simultaneous crossfade — form bleeds through
Title fade-out:    st=6.5
Problem fade-in:   st=6.5
-> Both at 50% alpha mid-fade, base video visible
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
- **Recording shorter than audio:** Increase hold times or add `tpad` padding in FFmpeg
- **Logo too small/large:** Adjust height in `render-slides.ts`
- **Logo grainy:** Switch from PNG to inline SVG
- **Unwanted horizontal bar on slides:** Remove `section-line` divs from `render-slides.ts`
- **Audio doesn't match:** Re-generate narration or adjust recording timing
- **TTS mispronunciation:** Rephrase the word (see pronunciation gotchas in Phase 3)
- **Interactive feature hidden by slide:** Start form filling earlier so interactions are visible between slide overlays — see "Slide overlap strategy" in Phase 8

### Phase 12: YouTube Upload

**No YouTube MCP tools are available.** Use Chrome browser automation:

1. Open YouTube Studio: `mcp__claude-in-chrome__navigate` to `https://studio.youtube.com`
2. Click **Create** → **Upload videos**
3. The native OS file picker cannot be automated — tell the user to click **Select files** and navigate to `output/explainer-video.mp4` (tip: **Cmd+Shift+G** in macOS file picker to paste path)
4. Once uploading, use browser automation to fill in title, description, tags, and visibility

**Suggested YouTube metadata:**
- **Title:** `[Product Name] — [Tagline]` (e.g. "Health Report Generator — Microsoft Word to Professional PDF")
- **Description:** Include product URL, feature list, and "Built by SMEC AI — smecai.au"
- **Tags:** product name, SMEC AI, key features
- **Visibility:** Unlisted (for review) or Public

## File Structure

```
scripts/video/
  branding.json            # Brand config
  narration.txt            # Narration script (with TTS-friendly spelling)
  narration-pro.mp3        # Generated audio
  render-slides.ts         # Slide renderer (Playwright)
  record-demo.ts           # Screen recorder (Playwright)
  assemble.sh              # FFmpeg assembly
  generate.sh              # Full pipeline orchestrator
  slides/
    slide-template.html    # HTML/CSS template
  assets/
    logo.svg               # SMEC AI SVG logo (purple gradient)
    logo.png               # SMEC AI PNG logo (watermark fallback)
    01-intro.png           # Rendered slides
    02-title.png
    03-problem.png
    04-benefits.png
    ...
output/
  demo.webm                # Raw recording
  explainer-video.mp4      # Final output
```

## .gitignore Additions

Add these to the project's `.gitignore` to avoid committing large binaries:
```
/output/
scripts/video/narration-pro.mp3
scripts/video/assets/*.png
scripts/video/assets/logo.png
```
