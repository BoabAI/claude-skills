# Narration Guide

Reference for writing effective explainer video narration scripts.

## Length

- **Target:** 150-200 words for 60-90 seconds
- **Speaking rate:** ~2.3 words/second (professional narration)
- **Shorter is better** — every word competes with the visual demo

## Format: Per-Section JSON

Narration is written as a JSON array of named sections, NOT as one continuous script with estimated timestamps. Each section is generated as a separate TTS audio file, and the **measured audio duration** of each segment drives that scene's `durationInFrames`.

Save as `scripts/video/narration-sections.json`:

```json
[
  { "sceneId": "title", "text": "Product name. A one-sentence description of what it does." },
  { "sceneId": "problem", "text": "The pain point it solves. One to two sentences." },
  { "sceneId": "transition", "text": "Here's how it works." },
  { "sceneId": "demo-01", "screenshotId": "01-homepage-hero", "text": "Narration for the first screenshot..." },
  { "sceneId": "demo-02", "screenshotId": "02-features", "text": "Narration for the second screenshot..." },
  { "sceneId": "demo-03", "screenshotId": "03-product", "text": "Narration for the third screenshot..." },
  { "sceneId": "demo-04", "screenshotId": "04-integrations", "text": "Narration for the fourth screenshot..." },
  { "sceneId": "demo-05", "screenshotId": "05-pricing", "text": "Narration for the fifth screenshot..." },
  { "sceneId": "stats", "text": "Key metrics or social proof." },
  { "sceneId": "cta", "text": "Call to action." }
]
```

### Section types

| sceneId pattern | Purpose | Typical length |
| --- | --- | --- |
| `title` | Hook — what is this tool? | 1-2 sentences, ~15-25 words |
| `problem` | Pain point it solves | 1-2 sentences, ~15-25 words |
| `transition` | Bridge to demo | 1 short sentence |
| `demo-01` through `demo-08` | One per screenshot, narrate what's on screen | 1-3 sentences, ~20-35 words each |
| `stats` | Key metrics / social proof | 1-2 sentences |
| `cta` | Call to action | 1 sentence |

Demo sections include a `screenshotId` that links to the corresponding entry in `tour-plan.json`.

## Writing Style

- **Short, clear sentences.** Average 10-15 words per sentence.
- **Active voice.** "The system calculates scores" not "Scores are calculated by the system"
- **Present tense.** "The patient enters" not "The patient will enter"
- **No jargon in narration** unless the audience expects it (clinical terms for medical, technical terms for developers)
- **No filler phrases.** Cut "basically", "essentially", "as you can see"
- **Match the platform's tone.** B2B enterprise = confident and authoritative. Creative tools = energetic and modern. Developer tools = calm and technical.

## Cross-Section Flow (CRITICAL)

Because each section is generated as a separate TTS file and then concatenated, the narration must feel like one continuous narrative — not a series of disconnected clips.

### Guidelines

- **Trailing endings:** Each section's last sentence should trail off naturally (no abrupt stops). End with periods, not exclamation marks.
- **Connective openings:** Each section's first sentence should continue the narrative thread. Use phrases like:
  - "And with..."
  - "From here..."
  - "What's more..."
  - "Beyond that..."
  - "On top of that..."
- **Avoid repeating openers:** Don't start two consecutive sections the same way.
- **Consistent punctuation:** End every section with a period. Avoid exclamation marks — they create tonal spikes between segments.
- **Natural breathing room:** The concatenation pipeline adds 300ms of silence between segments. Write section endings that feel complete at the end of a thought.

### Good example (flows naturally across sections)

```json
[
  { "sceneId": "demo-01", "screenshotId": "01-dashboard", "text": "The dashboard gives you a complete view of your team's activity, with time tracked, tasks completed, and productivity scores all in one place." },
  { "sceneId": "demo-02", "screenshotId": "02-reports", "text": "From here, detailed reports break down hours by project, client, or team member — making invoicing and payroll effortless." },
  { "sceneId": "demo-03", "screenshotId": "03-integrations", "text": "And with over thirty integrations, everything connects to the tools your team already uses." }
]
```

### Bad example (disconnected, jarring between sections)

```json
[
  { "sceneId": "demo-01", "screenshotId": "01-dashboard", "text": "Check out the dashboard! It shows activity!" },
  { "sceneId": "demo-02", "screenshotId": "02-reports", "text": "Reports are available. You can see hours." },
  { "sceneId": "demo-03", "screenshotId": "03-integrations", "text": "There are integrations too!" }
]
```

## Pronunciation Gotchas for TTS

- Spell out abbreviations TTS might mangle: ".docx" → "dot docx"
- Avoid "analyses" (verb) — TTS reads it as the noun. Use "reviews" or "examines"
- Numbers: spell out for consistent pronunciation ("thirty-five" not "35", "a hundred thousand" not "100,000")
- URLs: use "dot" instead of "." ("hubstaff dot com")
- Acronyms: spell out if uncommon ("A-P-I" not "API" if the voice stumbles on it)

## Voice Selection

Do NOT default to a hardcoded voice. The voice should match the platform's audience and tone.

### Voice matching heuristic

| Platform Type | Voice Style | Search Terms |
| --- | --- | --- |
| B2B SaaS / Enterprise | Confident, clear, mid-age | "corporate narrator", "professional explainer" |
| Creative / Design tools | Energetic, modern, younger | "modern narration", "dynamic explainer" |
| Developer tools | Calm, technical, articulate | "technical narrator", "developer" |
| Consumer / Lifestyle | Warm, friendly, approachable | "friendly narrator", "conversational" |
| Healthcare / Finance | Trustworthy, authoritative | "authoritative narrator", "documentary" |

### Voice parameters for explainer quality

- `stability`: 0.55–0.65 — enough consistency without sounding robotic
- `similarity_boost`: 0.75–0.85 — maintains voice character across sections
- `style`: 0.1–0.2 — subtle expressiveness, not theatrical
- `speed`: 0.9–1.0 — slightly slower for clarity

### Consistency across sections

All sections MUST use the same `voice_id`, `stability`, `similarity_boost`, `style`, and `speed`. The text itself naturally varies the tone (problem sections feel heavier, CTAs feel upbeat) — you don't need different TTS settings per section.

## Timing

**There are no hardcoded timestamps.** Scene durations are derived from measured audio:

1. Each section is generated as a separate TTS file (Phase 4b)
2. Each file's duration is measured with `ffprobe` (Phase 4c)
3. Measured durations are saved to `narration-timing.json`
4. Remotion reads `narration-timing.json` to set `durationInFrames` for each scene

This guarantees perfect audio-visual sync. The narrator can never drift ahead of or behind the visuals.
