# Narration Guide

Reference for writing effective explainer video narration scripts.

## Length

- **Default target:** 130-175 words for 45-70 seconds
- **Only go longer** when the user explicitly asks for a slower, more educational, or more documentary-style explainer
- **Speaking rate:** ~2.6-3.0 words/second for most SaaS and product videos
- **Shorter is better** — every word competes with the visual demo
- **Hard pacing rule:** if a spoken line runs longer than the current visual can support, shorten the line or add another visual beat

## Macro Pacing

Use this editorial map by default:

- **0-2s:** hook or product promise lands immediately
- **6-8s:** product or interface is visible
- **8-12s:** demo begins
- **12-15s max before the demo is fully underway:** no long exposition runway
- **Every 2-4s:** introduce a new claim, proof point, or visual beat

## Format: Per-Section JSON

Narration is written as a JSON array of named sections, NOT as one continuous script with estimated timestamps. Each section is generated as a separate TTS audio file, and the **measured audio duration** of each segment drives that scene's `durationInFrames`.

Save as `scripts/video/narration-sections.json`:

```json
[
  { "sceneId": "title", "text": "Product name. A one-sentence description of what it does." },
  { "sceneId": "problem", "text": "The pain point it solves. One to two sentences." },
  { "sceneId": "transition", "text": "Here's how it works." },
  { "sceneId": "demo-01", "beatId": "hero-claim", "primaryShotId": "01-homepage-hero", "text": "Narration for the first screenshot..." },
  { "sceneId": "demo-02", "beatId": "proof-moment", "primaryShotId": "02-features", "text": "Narration for the second screenshot..." },
  { "sceneId": "demo-03", "beatId": "workflow-moment", "primaryShotId": "03-product", "text": "Narration for the third screenshot..." },
  { "sceneId": "demo-04", "beatId": "result-moment", "primaryShotId": "04-integrations", "text": "Narration for the fourth screenshot..." },
  { "sceneId": "demo-05", "beatId": "cta-moment", "primaryShotId": "05-pricing", "text": "Narration for the fifth screenshot..." },
  { "sceneId": "stats", "text": "Key metrics or social proof." },
  { "sceneId": "cta", "text": "Call to action." }
]
```

### Section types

| sceneId pattern | Purpose | Typical length |
| --- | --- | --- |
| `title` | Hook — what is this tool? | 1-2 sentences, ~10-18 words |
| `problem` | Pain point it solves | 1-2 sentences, ~10-20 words |
| `transition` | Bridge to demo | 1 short sentence |
| `demo-01` through `demo-08` | One per message beat, not one frozen screenshot | 1-2 sentences, ~12-24 words each |
| `stats` | Key metrics / social proof | 1-2 sentences |
| `cta` | Call to action | 1 sentence |

Demo sections should include a `beatId` that links to `interaction-plan.json` and a `primaryShotId` that links to the main entry in `tour-plan.json`. A polished demo can still use more than one visual beat or caption variant inside that narration window.

## Writing Style

- **Short, clear sentences.** Average 10-15 words per sentence.
- **Active voice.** "The system calculates scores" not "Scores are calculated by the system"
- **Present tense.** "The patient enters" not "The patient will enter"
- **No jargon in narration** unless the audience expects it (clinical terms for medical, technical terms for developers)
- **No filler phrases.** Cut "basically", "essentially", "as you can see"
- **Match the platform's tone.** B2B enterprise = confident and authoritative. Creative tools = energetic and modern. Developer tools = calm and technical.
- **One claim per beat.** If the line is trying to explain three things, split it.
- **Lead with verbs.** Prefer "Track work instantly" over "The dashboard provides tracking capabilities"
- **Avoid page-tour phrasing.** Don't say "On the homepage..." or "Here on the pricing page..." unless the location itself matters

## Human-Like Delivery

The script should sound like a real narrator speaking to a real audience, not like written copy being read by a machine.

### Write for speech

- Prefer contractions when they fit the brand: "it's", "you're", "here's", "doesn't"
- Vary sentence length so the cadence rises and falls naturally
- Use commas and periods to create subtle breathing room
- Keep clauses clean enough to say in one breath
- Rewrite any line that feels stiff when read aloud

### Avoid robotic cadence

These patterns often make even a good TTS model sound artificial:

- Every sentence has the same length
- Every sentence starts with the same structure
- Multiple feature labels stacked into one line
- Copy that sounds like bullet points joined by commas
- Overly formal brochure phrasing where spoken phrasing would be simpler

Bad:
- "The platform delivers meetings, chat, docs, phone, analytics, automation, and collaboration for modern teams."

Better:
- "Bring meetings, chat, docs, and phone into one workflow. So the team spends less time switching and more time moving."

## Demo Copy Rules

- **Write demo narration like commercial copy, not product training**
- **Keep each demo section punchy:** usually 12-24 words
- **Name the user benefit or proof first, then let the visuals support it**
- **If a demo segment exceeds 24-28 words, consider splitting the message or planning caption progression within the shot**
- **Do not narrate obvious UI details** like "this button is blue" or "on the left side"

### Bad vs good demo lines

Bad:
- "Here on the homepage, you can see the dashboard and some of the platform features."
- "This page shows analytics, integrations, reports, and automation tools for teams."

Good:
- "See performance in one glance, then drill straight into the work behind it."
- "Automations remove the follow-up work, so the team can keep moving."

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
- **Natural breathing room:** The concatenation pipeline should usually add only 120-180ms of silence between segments. Write section endings that feel complete without inviting a long pause.
- **Natural spoken phrasing:** If a bridge line feels like narration glue rather than something a person would say, simplify it.

### Good example (flows naturally across sections)

```json
[
  { "sceneId": "demo-01", "beatId": "dashboard-overview", "primaryShotId": "01-dashboard", "text": "See team performance in one glance, with the signal rising above the noise." },
  { "sceneId": "demo-02", "beatId": "report-proof", "primaryShotId": "02-reports", "text": "From there, reports turn raw activity into billable clarity." },
  { "sceneId": "demo-03", "beatId": "rollout-proof", "primaryShotId": "03-integrations", "text": "And because it plugs into the stack you already use, rollout stays simple." }
]
```

### Bad example (disconnected, jarring between sections)

```json
[
  { "sceneId": "demo-01", "beatId": "dashboard-overview", "primaryShotId": "01-dashboard", "text": "This is the dashboard and it shows the dashboard information." },
  { "sceneId": "demo-02", "beatId": "report-proof", "primaryShotId": "02-reports", "text": "Here you can look at the reports page for reports." },
  { "sceneId": "demo-03", "beatId": "rollout-proof", "primaryShotId": "03-integrations", "text": "There are integrations on this integrations screen." }
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

The default target is **human-like commercial narration**. A voice that is merely understandable is not good enough for a polished product video.

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
- `speed`: 1.03–1.10 for most SaaS and product marketing videos
- Slow down only when the audience expects a calmer cadence or the vocabulary is unusually dense

### Voice audition checklist

Before generating the full narration, test the chosen voice on:

- one hook line
- one dense proof/demo line
- one CTA line

Reject the voice if:

- pauses feel mechanical
- emphasis lands in the wrong place
- the read sounds flat or sleepy
- the same cadence repeats across all three lines
- it sounds like a default assistant voice rather than a human narrator

### Consistency across sections

All sections MUST use the same `voice_id`, `stability`, `similarity_boost`, `style`, and `speed`. The text itself naturally varies the tone (problem sections feel heavier, CTAs feel upbeat) — you don't need different TTS settings per section.

### Fallback policy

- Prefer premium neural voices by default
- Do not silently downgrade to OS speech or low-expression fallback TTS
- If only fallback TTS is available, tell the user the narration will sound less human before generating it
- If fallback TTS is used, compensate by simplifying copy and tightening phrasing, then run an extra audio review pass

## Timing

**There are no hardcoded timestamps.** Scene durations are derived from measured audio:

1. Each section is generated as a separate TTS file (Phase 4b)
2. Each file's duration is measured with `ffprobe` (Phase 4c)
3. Measured durations are saved to `narration-timing.json`
4. Remotion reads `narration-timing.json` to set `durationInFrames` for each scene

This guarantees perfect audio-visual sync. The narrator can never drift ahead of or behind the visuals.

## Caption Coordination

Narration and captions should feel like one system:

- Narration carries the main claim
- Captions reinforce why the claim matters
- Interaction beats should reinforce the same claim. If you add a click, hover, or section jump, it should help the spoken idea land instead of becoming decorative motion
- If the narration segment is longer than one visual beat, let the caption progress once or twice instead of holding identical copy the whole time
- Avoid captions that merely restate the page label

Bad captions:
- "Dashboard"
- "Analytics page"

Better captions:
- "See risk before it slows the team down"
- "Turn raw activity into a decision"
