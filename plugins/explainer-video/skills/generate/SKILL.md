---
name: generate
description: Produce a professional branded marketing explainer video for any web application using Remotion. Orchestrates Playwright-powered product capture, animated Remotion scenes, human-like ElevenLabs narration, background music, sound effects, and Remotion rendering. All visual design is driven by the bundled frontend-design skill — never hardcode aesthetics.
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Explainer Video Pipeline (Remotion)

Generate a professional branded marketing video for any web application. The pipeline captures high-resolution product screenshots with Playwright, builds animated scene components in Remotion (React for video), layers narration with background music and sound effects, and renders a polished final video. This skill works across any project repo — it creates the `scripts/video/` directory in the target project.

**For professional video quality standards**, read [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) — the 4-layer frame model, scene layout vocabulary, animation principles, demo scene enhancement, and anti-patterns. This is the quality bar every scene must meet.

**For Remotion-specific patterns**, consult the [remotion-best-practices](${CLAUDE_SKILL_DIR}/../remotion-best-practices/SKILL.md) skill and its rule files.

**For ALL visual design decisions**, consult the [frontend-design](${CLAUDE_SKILL_DIR}/../frontend-design/SKILL.md) skill. Never invent colors, fonts, layouts, or aesthetic choices yourself — always derive them from the frontend-design skill's guidelines and the user's creative direction.

## Prerequisites

- **Node.js** (v18+) and **npm** or **bun**
- **Playwright** (`npm add -D playwright && npx playwright install chromium`)
- **ElevenLabs MCP** for narration quality by default. Use `edge-tts` only as an explicit fallback when the user accepts lower voice quality.
- A running web app (or public URL) to record

Remotion and its packages are installed during the scaffold phase — no global install needed.

## Pipeline Phases

Execute each phase in order. All output goes to `scripts/video/` in the target project.

```
Pipeline Progress:
- [ ] Phase 1: Analyze the app
- [ ] Phase 2: Creative direction & branding
- [ ] Phase 3: Write narration
- [ ] Phase 4: Generate audio
- [ ] Phase 5: Record demo
- [ ] Phase 6: Scaffold Remotion project
- [ ] Phase 7: Build scene components
- [ ] Phase 8: Compose the scene timeline
- [ ] Phase 9: Render video
```

---

### Phase 1: Analyze the App & Extract Brand

1. Read `package.json`, `README.md`, and the main page component (or browse the public URL)
2. Identify the app's primary user flow (the "happy path")
3. Note key CSS selectors, form fields, buttons, and navigation
4. Determine timing: how long does the full flow take?

#### Auto Theme Extraction (if URL is available)

If the user provides a URL or the app is running, use Playwright to automatically extract the product's visual identity before asking creative direction questions:

```ts
// In a Playwright script or inline extraction:
const page = await browser.newPage();
await page.goto(url);

// Extract CSS custom properties from :root
const cssVars = await page.evaluate(() => {
  const root = getComputedStyle(document.documentElement);
  return {
    // Try common CSS variable naming conventions
    vars: Array.from(document.styleSheets)
      .flatMap(s => { try { return Array.from(s.cssRules); } catch { return []; } })
      .filter(r => r.cssText?.includes('--'))
      .map(r => r.cssText)
  };
});

// Extract computed styles from key elements
const theme = await page.evaluate(() => ({
  bodyBg: getComputedStyle(document.body).backgroundColor,
  bodyColor: getComputedStyle(document.body).color,
  bodyFont: getComputedStyle(document.body).fontFamily,
  h1Font: document.querySelector('h1') ? getComputedStyle(document.querySelector('h1')).fontFamily : null,
  h1Color: document.querySelector('h1') ? getComputedStyle(document.querySelector('h1')).color : null,
  linkColor: document.querySelector('a') ? getComputedStyle(document.querySelector('a')).color : null,
  buttonBg: document.querySelector('button') ? getComputedStyle(document.querySelector('button')).backgroundColor : null,
}));

// Detect dark vs light theme
const isDark = await page.evaluate(() => {
  const bg = getComputedStyle(document.body).backgroundColor;
  const match = bg.match(/\d+/g);
  if (match) {
    const [r, g, b] = match.map(Number);
    return (r + g + b) / 3 < 128;
  }
  return false;
});

// Grab logo — try favicon, og:image, or SVG from page
const logo = await page.evaluate(() => {
  const ogImage = document.querySelector('meta[property="og:image"]')?.getAttribute('content');
  const favicon = document.querySelector('link[rel="icon"]')?.getAttribute('href');
  const svgLogo = document.querySelector('header svg, nav svg, [class*="logo"] svg');
  return { ogImage, favicon, hasSvgLogo: !!svgLogo };
});
```

Use the extracted data to auto-generate a draft `branding.json` in Phase 2 Step 3, instead of designing from scratch. The product's existing brand identity is the best starting point.

### Phase 2: Creative Direction & Branding

This is the most important phase for video quality. **Do NOT skip or rush it.**

#### Step 1: Read the frontend-design skill

Read the [frontend-design](${CLAUDE_SKILL_DIR}/../frontend-design/SKILL.md) skill in full. Internalize its principles — bold aesthetic direction, distinctive typography, cohesive color systems, spatial composition, atmospheric backgrounds, motion philosophy. Every visual decision in the video flows from this skill.

#### Step 2: Present extracted brand & ask for direction

If Phase 1 extracted theme data from the URL, present a summary to the user:

> "I've extracted your product's brand identity:
> - **Theme**: [dark/light]
> - **Colors**: [primary bg, text color, accent/button color]
> - **Fonts**: [detected font families]
> - **Logo**: [found/not found]
>
> I'll match the video to your product's existing look. Want to adjust anything, or pick a different direction?
> - **Tone options**: Dark & cinematic, light & editorial, retro-futuristic, organic/natural, luxury/refined, playful, brutalist, art deco, soft/pastel, industrial
> - **References**: Any SaaS videos or brands whose style you admire?
> - Or just confirm and I'll proceed with your product's brand."

If no URL was available, fall back to the full creative direction interview:

> "What visual style do you want for this video? Some directions to consider:
> - **Tone**: Dark & cinematic, light & editorial, retro-futuristic, organic/natural, luxury/refined, playful, brutalist, art deco, soft/pastel, industrial?
> - **Mood**: Energetic, calm, dramatic, playful, professional, rebellious?
> - **References**: Any SaaS videos or brands whose style you admire?
> - **Specific ideas**: Any particular visual elements, color palettes, or effects you have in mind?
> - Or should I design something that matches the app's existing brand identity?"

Wait for the user's response. Their input drives everything.

#### Step 3: Design the visual system

Using the frontend-design skill's guidelines and the user's direction, design a complete visual system. Follow the frontend-design skill's approach:

1. **Choose a bold aesthetic direction** — commit to it fully. No safe/generic choices.
2. **Typography** — pick distinctive fonts from Google Fonts. NEVER default to Inter, Roboto, Arial, Space Grotesk, or system fonts. Pair a characterful display font with a refined body font.
3. **Color palette** — design a cohesive palette using CSS variables. Dominant colors with sharp accents. The palette should have: background tones, primary accent, secondary accent, text colors, a "problem/negative" color, and a "positive/success" color.
4. **Background treatment** — design atmospheric backgrounds (gradient meshes, noise textures, geometric patterns, layered transparencies, grain overlays) — NOT plain solid colors or generic linear gradients.
5. **Spatial composition** — plan the layout philosophy: asymmetric? centered? grid-breaking? Generous negative space or controlled density?
6. **Motion philosophy** — what kind of animations match the tone? Snappy and energetic? Slow and luxurious? Bouncy and playful?

#### Step 4: Collect branding info

Gather from the user:
- **Company/product name**
- **Logo** — ask for their logo SVG path, or find it in the project. Copy to `scripts/video/remotion/public/logo.svg`.
- **Website URL**
- **Tagline**

#### Step 4b: Select Voice

Do NOT default to a hardcoded voice. Analyze the platform's audience and tone, then find a matching voice. The default goal is **human-sounding marketing narration**, not merely intelligible TTS.

**Voice matching heuristic:**

| Platform Type           | Voice Style                  | Search Terms                                   |
| ----------------------- | ---------------------------- | ---------------------------------------------- |
| B2B SaaS / Enterprise   | Confident, clear, mid-age    | "corporate narrator", "professional explainer" |
| Creative / Design tools | Energetic, modern, younger   | "modern narration", "dynamic explainer"        |
| Developer tools         | Calm, technical, articulate  | "technical narrator", "developer"              |
| Consumer / Lifestyle    | Warm, friendly, approachable | "friendly narrator", "conversational"          |
| Healthcare / Finance    | Trustworthy, authoritative   | "authoritative narrator", "documentary"        |

**Workflow:**
1. Determine which row best fits the platform
2. Use `mcp__elevenlabs__search_voice_library` with matching search terms
3. Narrow to 3-5 plausible voices instead of taking the first match
4. Audition them on a short real line from the script hook or demo copy
5. Pick the voice that sounds active, modern, and human under real narration text — avoid flat announcer reads, over-polished radio reads, and generic "old narrator" voices
6. Save the chosen `voice_id` and `voice_name` in `branding.json` (see Step 5)

**Reject a voice if any of these are true:**
- It sounds like a default assistant or system TTS voice
- Every sentence lands with the same cadence
- Pauses feel mechanical or over-even
- The delivery feels stiff, sleepy, or overly theatrical for the brand
- The voice sounds good on one sentence but collapses on a longer demo line

**Voice parameters** — tune these for professional explainer quality:
- `stability`: 0.55–0.65 (enough consistency without sounding robotic)
- `similarity_boost`: 0.75–0.85 (maintain voice character)
- `style`: 0.1–0.2 (subtle expressiveness)
- `speed`: 1.03–1.10 for most SaaS, product, and creative marketing videos. Only drop to `0.95–1.0` for intentionally calm, technical, financial, or healthcare brands.

**Human-like narration policy:**
- Premium neural narration is the default, not a luxury add-on
- Never silently downgrade to OS speech, browser speech, or low-expression TTS
- If only fallback TTS is available, tell the user it will sound less human and ask before proceeding
- If the chosen voice sounds robotic on the actual script, change the voice or rewrite the line before moving on

#### Step 5: Create branding.json

Create `scripts/video/branding.json` that captures the brand identity, creative direction, AND voice selection. All color values, font choices, background styles, motion parameters, and voice settings come from your design work in Steps 3–4b — never use placeholder or default values.

```json
{
  "company": "<from user>",
  "logoPath": "logo.svg",
  "url": "<from user>",
  "tagline": "<from user>",
  "colors": {
    "bgPrimary": "<designed in Step 3>",
    "bgSecondary": "<designed in Step 3>",
    "accent": "<designed in Step 3>",
    "accentSolid": "<designed in Step 3>",
    "accentSecondary": "<designed in Step 3>",
    "negative": "<designed in Step 3>",
    "negativeAccent": "<designed in Step 3>",
    "textPrimary": "<designed in Step 3>",
    "textSecondary": "<designed in Step 3>"
  },
  "font": {
    "display": "<distinctive Google Font chosen in Step 3>",
    "body": "<complementary Google Font chosen in Step 3>"
  },
  "style": {
    "tone": "<user's chosen tone>",
    "backgroundType": "<gradient-mesh | geometric | noise-texture | layered | minimal | etc.>",
    "motionStyle": "<snappy | luxurious | bouncy | cinematic | etc.>",
    "layoutStyle": "<asymmetric | centered | grid-breaking | editorial | etc.>"
  },
  "voice": {
    "id": "<ElevenLabs voice_id from Step 4b>",
    "name": "<voice name for reference>",
    "stability": 0.6,
    "similarityBoost": 0.8,
    "style": 0.15,
    "speed": 1.05
  }
}
```

**CRITICAL:** Every field must reflect a deliberate design decision. If you find yourself reaching for purple/violet gradients on dark backgrounds, STOP — you're falling into generic AI aesthetics. Consult the frontend-design skill and the user's direction again.

### Phase 3: Write Narration (Per-Section)

Write a professional default script in the **45–70 second** range (~130–175 words). Only extend beyond that if the user explicitly asks for a slower or more comprehensive video. See [narration-guide.md](${CLAUDE_SKILL_DIR}/references/narration-guide.md).

#### Default pacing map for professional product videos

Use this as the default editorial rhythm unless the user asks for a slower, calmer, or more documentary-style cut:

1. **Hook lands in the first 2 seconds**
2. **Product or interface appears by 6–8 seconds**
3. **Demo begins by 8–12 seconds**
4. **Intro + title + problem combined should stay under 12–15 seconds**
5. **A new idea, cut, or visual beat should happen every 2–4 seconds**
6. **Never place more than two non-product exposition scenes before showing the interface**

#### CRITICAL: Write narration as separate named sections

Do NOT write one continuous script with estimated timestamps. Instead, write each scene's narration as a separate section in a JSON array. Each section is generated as a separate TTS audio file in Phase 4, and the **measured audio duration** of each segment drives that scene's `durationInFrames`. This guarantees perfect audio-visual sync.

Save to `scripts/video/narration-sections.json`:

```json
[
  { "sceneId": "title", "text": "Hubstaff. Time tracking and productivity monitoring for the modern hybrid workforce." },
  { "sceneId": "problem", "text": "Managing remote teams shouldn't mean endless check-ins, manual timesheets, and guessing who's doing what." },
  { "sceneId": "transition", "text": "Here's how Hubstaff changes that." },
  { "sceneId": "demo-01", "screenshotId": "01-homepage-hero", "text": "Track work, productivity, and payroll from one operating view." },
  { "sceneId": "demo-02", "screenshotId": "02-productivity", "text": "See performance fast, then drill into the work behind it." },
  { "sceneId": "demo-03", "screenshotId": "03-workforce", "text": "Keep schedules, attendance, and approvals moving without extra follow-up." },
  { "sceneId": "demo-04", "screenshotId": "04-integrations", "text": "Plug into the tools your team already runs on." },
  { "sceneId": "demo-05", "screenshotId": "05-pricing", "text": "Scale up with a plan that fits how your team operates." },
  { "sceneId": "stats", "text": "Half a million active users. Twenty-one million hours tracked. Four million tasks completed." },
  { "sceneId": "cta", "text": "Start your free trial today at hubstaff dot com." }
]
```

Each `sceneId` maps to a video scene. Demo sections include a `screenshotId` that links to the **primary** visual beat in `tour-plan.json`, but a strong demo may still use multiple visual beats inside that measured narration window.

#### CRITICAL: Write for a human voice, not for text on a page

The narration must sound like a human brand narrator speaking naturally:

- Prefer contractions where appropriate: "you're", "it's", "here's", "doesn't"
- Vary sentence length so the read does not become metronomic
- Use punctuation to shape breath and emphasis, but keep it subtle
- Favor spoken phrasing over brochure phrasing
- Break dense product claims into two cleaner lines instead of one overloaded sentence
- If a line sounds stiff when read aloud, rewrite it before generating audio

**Section structure:**
1. **title** — Hook: What is this tool? (1-2 sentences)
2. **problem** — Pain point it solves (1-2 sentences)
3. **transition** — Bridge to demo (1 short sentence)
4. **demo-01 through demo-05** (or more) — One section per product claim or proof beat, not one static screenshot hold
5. **stats** — Key metrics or social proof
6. **cta** — Call to action

**Writing guidelines for natural cross-section flow:**
- Each section's last sentence should trail off naturally (no abrupt stops)
- Each section's first sentence should continue the narrative thread
- Use connective phrases at section starts: "And with...", "From here...", "What's more..."
- Keep punctuation consistent — end with periods, not exclamation marks
- Avoid starting two consecutive sections the same way
- The TTS model maintains consistent style when text flows naturally
- Keep demo sections to one claim per beat. If the line starts stacking multiple features, split it

**Robotic script red flags:**
- Every sentence has the same length and structure
- The copy reads like bullet points turned into prose
- Too many noun piles: "AI automation workflow productivity collaboration platform"
- Overuse of labels like "homepage", "dashboard page", "pricing page"
- Long comma chains with no natural landing point

**Pronunciation gotchas for TTS (IMPORTANT):**
- Spell out abbreviations TTS might mangle: ".docx" → "dot docx"
- Avoid "analyses" (verb) — TTS reads it as the noun. Use "reviews" or "examines"
- Numbers: spell out for consistent pronunciation ("thirty-five" not "35", "a hundred thousand" not "100,000")
- URLs: use "dot" instead of "." ("hubstaff dot com")

### Phase 4: Generate Audio (Per-Section TTS)

Generate narration as **separate TTS files per section**, measure each segment's actual duration, then concatenate into a single narration file. This guarantees perfect audio-visual sync — scene durations are derived from measured audio, not estimates.

#### Phase 4a: Select Voice

Use the voice settings from `branding.json` (chosen in Phase 2). All segments MUST use the same `voice_id`, `model_id`, `stability`, `similarity_boost`, `style`, and `speed` — this ensures consistent voice character across sections.

Before generating the full set, audition 2-3 representative lines:
- one hook line
- one dense demo/proof line
- one CTA line

If the chosen voice sounds robotic, flat, or unnatural on those lines, change the voice or rewrite the lines before batch generation.

#### Phase 4b: Generate TTS Per Section

Read `scripts/video/narration-sections.json`. For each section, call `mcp__elevenlabs__text_to_speech`:

```
For each section in narration-sections.json:
  Call text_to_speech with:
    text: section.text
    voice_id: branding.voice.id
    stability: branding.voice.stability
    similarity_boost: branding.voice.similarityBoost
    style: branding.voice.style
    speed: branding.voice.speed
    output_directory: scripts/video/remotion/public/narration-segments/
  Save as: {index}-{sceneId}.mp3  (e.g., 01-title.mp3, 04-demo-01.mp3)
```

After generation, spot-check the first few segments before continuing:
- Does the hook sound like a person, not a machine?
- Are the pauses natural?
- Does the energy match the brand?
- Are pronunciations clean?

If not, do not continue into final render. Fix the voice choice or the copy first.

#### Phase 4c: Measure Segment Durations

Run `ffprobe` on each segment to get its exact duration:

```bash
ffprobe -v quiet -show_entries format=duration -of csv=p=0 scripts/video/remotion/public/narration-segments/01-title.mp3
```

Create `scripts/video/narration-timing.json`:

```json
{
  "segments": [
    { "sceneId": "title", "file": "narration-segments/01-title.mp3", "duration": 5.23 },
    { "sceneId": "problem", "file": "narration-segments/02-problem.mp3", "duration": 7.81 },
    { "sceneId": "transition", "file": "narration-segments/03-transition.mp3", "duration": 2.14 },
    { "sceneId": "demo-01", "screenshotId": "01-homepage-hero", "file": "narration-segments/04-demo-01.mp3", "duration": 8.12 },
    { "sceneId": "demo-02", "screenshotId": "02-productivity", "file": "narration-segments/05-demo-02.mp3", "duration": 7.45 },
    { "sceneId": "stats", "file": "narration-segments/08-stats.mp3", "duration": 5.92 },
    { "sceneId": "cta", "file": "narration-segments/09-cta.mp3", "duration": 3.41 }
  ],
  "paddingSeconds": 0.15,
  "totalDuration": 0
}
```

Compute `totalDuration` as: `sum(all segment durations) + (segment_count - 1) * paddingSeconds`.

#### Phase 4d: Concatenate Into Final Narration

Use ffmpeg to concatenate all segments with **120–180ms** silence padding by default. Reserve **220–300ms** only for major structural breaks such as `problem -> demo` or `stats -> cta`. The goal is continuity with energy, not dead air between every sentence.

```bash
# Generate a 150ms silence file
ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t 0.15 -q:a 9 -acodec libmp3lame /tmp/silence.mp3

# Build a concat list file
echo "file 'narration-segments/01-title.mp3'" > /tmp/concat.txt
echo "file '/tmp/silence.mp3'" >> /tmp/concat.txt
echo "file 'narration-segments/02-problem.mp3'" >> /tmp/concat.txt
echo "file '/tmp/silence.mp3'" >> /tmp/concat.txt
# ... repeat for all segments ...
echo "file 'narration-segments/09-cta.mp3'" >> /tmp/concat.txt

# Concatenate
ffmpeg -y -f concat -safe 0 -i /tmp/concat.txt -c copy scripts/video/remotion/public/narration.mp3
```

Also compute cumulative offsets for each segment (used by Remotion to know when each segment starts in the final audio):

```
offset[0] = 0
offset[n] = offset[n-1] + duration[n-1] + paddingSeconds
```

Update `narration-timing.json` to include the `offset` field per segment.

**Fallback (if ElevenLabs is unavailable):** `edge-tts` is acceptable only with explicit user approval, because the result is usually less human and less marketable. Never silently downgrade. If the user approves the fallback, use `edge-tts` per section:
```bash
edge-tts --text "<section text>" --voice en-AU-WilliamNeural --write-media scripts/video/remotion/public/narration-segments/01-title.mp3
```

If `edge-tts` is used:
- warn the user that narration quality will likely be lower
- slow down slightly if needed to reduce robotic cadence
- rewrite lines even more aggressively for spoken rhythm
- plan an audio review pass before calling the video complete

### Phase 5: Capture Demo Screenshots

The demo section uses **high-resolution screenshots** animated in Remotion — NOT live screen recordings. Playwright captures pixel-perfect screenshots of each key page/feature, then Remotion handles transitions, Ken Burns drift, and captions. This produces far smoother results than `recordVideo`.

See [playwright-recording.md](${CLAUDE_SKILL_DIR}/references/playwright-recording.md) for setup, discovery patterns, and capture techniques.

**Phase 5a: Discover the Platform**

Before capturing anything, explore the site to understand its structure:

- For PUBLIC URLs: Use Playwright to navigate to the site, extract nav links, read page headings, identify interactive elements. Save a `site-map.json` that lists pages, nav items, key selectors, and candidate proof moments.
- For LOCAL APPS: Read the project's router config, page components, and route definitions. Start the app and verify key routes.

Use a hybrid rule:
- AI chooses where to go and why
- deterministic Playwright captures the exact states
- Remotion authors the interaction illusion cleanly

The discovery artifact should be first-class, not throwaway notes. At minimum, `site-map.json` should be rich enough to answer:
- Which pages can the video intentionally navigate to?
- Which selectors are safe click, hover, tab, accordion, or section-jump targets?
- Which proof moments actually support the narration instead of generic browsing?
- What site fingerprint best describes the product? Use categories such as `long-scroll-marketing`, `multi-page-marketing`, `dashboard-app`, `workflow-tool`, `docs-search`, or `data-heavy-ui`

**Phase 5b: Plan the Capture Tour**

Plan **4-8 message moments** across the product story, usually captured as **8-14 visual beats**. Do not treat the demo like a website tour. Treat it like an editorial sequence built around claims, proof, and outcomes.

1. Map each `demo-*` section from `narration-sections.json` to a **message beat** first, then decide whether that beat needs one visual, two visuals, or a micro-sequence inside the same measured timing window
2. The narration sections define which product claims must be visualized — don't capture pages that are not in service of those claims
3. Prefer strong product states over generic page coverage. If a tighter crop, a scrolled state, a selected tab, or a before/after framing proves the claim better, use that instead of the default page top. But when capturing a section, frame it intentionally from the section start — do not let the viewport land halfway through the content block.
4. Use approved shot archetypes: `establish`, `push-in`, `detail-crop`, `split-proof`, `result-state`
5. Browser chrome and animated URL bars are optional tools, not mandatory framing for every beat. Use them when orientation helps. Remove them when they make the sequence feel like browsing
6. Write an `interaction-plan.json` before capture. It should map each narration beat to one or more structured interaction beats such as `clickToPage`, `scrollToSection`, `hoverReveal`, `switchTab`, `expandAccordion`, or `resultReveal`
7. Treat `tour-plan.json` as a shot script, not just an asset manifest. Include motion intent, caption copy, camera direction, and ordered interaction beat metadata the Remotion layer will need
8. Split pre-capture actions from in-video authored beats. Capture-time steps create the screenshot state. Authored beats describe how the cursor, caption, URL bar, and UI SFX should behave in the video
9. When a click or hover matters, target a measured selector whenever possible. Do not guess geometry by eye if Playwright can resolve it
10. Choose the interaction type intentionally:
   - marketing sites: nav click + section jump
   - multi-page product sites: click-to-page
   - dense product UIs: tab switch, panel reveal, accordion open
   - simple landing pages: scroll-to-section, not fake over-clicking
11. For each demo beat, write down three things before planning motion: `intent`, `evidence`, and `behavior`
   - `intent`: what the narration needs to prove
   - `evidence`: what visible state proves it
   - `behavior`: how the viewer should be guided there, if at all
12. Not every beat needs the cursor. Deliberately mix:
   - quiet beats with no pointer
   - scroll-only beats
   - true click-to-page beats with a destination state
   - state-change beats such as tab switches or result reveals
13. Plan state changes, not just screenshots. A strong beat may need `before`, `during`, and `after` states rather than one still with decorative cursor motion
14. Enforce diversity across the whole demo:
   - do not repeat the same interaction type more than twice in a row without a story reason
   - do not let one interaction type dominate most of the sequence unless the site genuinely only supports it
   - require at least one true page or state change when the product supports it
15. Do not add highlight boxes or callout rectangles over the product UI. If a moment needs emphasis, solve it through stronger shot selection, better scroll position, clearer captions, state changes, or more deliberate camera choreography
16. Create a `tour-plan.json` at `scripts/video/` describing each screenshot or sub-beat. **Do NOT include narration timestamps** — screenshot durations come from `narration-timing.json` (measured audio):

Plan artifacts should follow this shape:

```json
{
  "site-map.json": {
    "siteFingerprint": "multi-page-marketing",
    "pages": [
      {
        "id": "homepage",
        "url": "https://example.com",
        "navItems": [{ "label": "Pricing", "selector": "a[href='/pricing']" }],
        "candidateProofMoments": [{ "id": "hero", "selector": "main h1" }]
      }
    ]
  },
  "interaction-plan.json": {
    "moments": [
      {
        "beatId": "hero-claim",
        "sceneId": "demo-01",
        "pageId": "homepage",
        "shot": {
          "id": "01-homepage-hero",
          "interactionPattern": "quiet-establish",
          "pointerMode": "hidden",
          "states": [{ "id": "hero", "stateRole": "base" }]
        },
        "beats": [
          { "type": "swapState", "startProgress": 0.56, "toStateId": "hero-detail", "transitionMode": "focus" }
        ]
      }
    ]
  }
}
```

The flattened capture output should look like this:

```json
[
  {
    "id": "01-homepage-hero",
    "beatId": "hero-claim",
    "file": "screenshots/01-homepage-hero.png",
    "label": "Homepage",
    "url": "example.com",
    "description": "Landing hero",
    "eyebrow": "Unified workspace",
    "headline": "Projects, docs, and AI in one system.",
    "subheadline": "Guide the viewer from the promise to the primary CTA.",
    "shotArchetype": "establish",
    "interactionPattern": "follow-nav",
    "pointerMode": "guided",
    "transitionStyle": "focus",
    "states": [
      { "id": "hero", "file": "screenshots/01-homepage-hero.png", "stateRole": "base", "url": "example.com" },
      { "id": "pricing", "file": "screenshots/01-homepage-hero--pricing.png", "stateRole": "destination", "url": "example.com/pricing" }
    ],
    "camera": {
      "startScale": 1.02,
      "endScale": 1.1,
      "startX": 12,
      "endX": -40,
      "startY": 4,
      "endY": -18,
      "focusX": 36,
      "focusY": 34
    },
    "interaction": {
      "beats": [
        {
          "type": "moveCursor",
          "startProgress": 0,
          "endProgress": 0.72,
          "cursorPath": [
            { "x": 78, "y": 18, "progress": 0 },
            { "x": 38, "y": 34, "progress": 0.36 },
            { "x": 26, "y": 52, "progress": 0.72 }
          ]
        },
        {
          "type": "click",
          "startProgress": 0.76,
          "target": { "x": 22, "y": 48, "width": 12, "height": 6, "label": "Pricing" },
          "soundCue": "mouse-click"
        },
        {
          "type": "pageChange",
          "startProgress": 0.8,
          "endProgress": 0.94,
          "toUrl": "example.com/pricing",
          "toStateId": "pricing",
          "transitionMode": "push",
          "soundCue": "page-turn"
        }
      ],
    }
  }
]
```

Each screenshot's display duration in the video is determined by the corresponding `demo-*` segment in `narration-timing.json` (measured in Phase 4c), NOT by estimated timestamps.
The tour plan should be rich enough that Remotion can animate each shot with camera choreography, richer captions, cursor cues, and multiple visual beats inside a narration segment instead of generic one-size-fits-all motion.

**Phase 5c: Capture Screenshots**

Write `scripts/video/capture-demo.ts` that executes the planned capture tour:

- Viewport: 1920x1080 with `deviceScaleFactor: 2` for retina-sharp text
- Navigate to each page using `waitUntil: "domcontentloaded"` (NOT `networkidle` — many sites have persistent connections that prevent it from resolving)
- After navigation, wait for a visible content selector (`h1, h2, img, svg`) with 8s timeout, then add 2000ms settle time for fonts/animations
- When capturing a section, measure its heading/container geometry and align the viewport to the **top of the section** with safe padding. Do not rely on `scrollIntoViewIfNeeded()` or arbitrary `scrollBy(...)` values as the final framing step.
- Compensate for sticky headers or fixed nav bars when computing the scroll target so the heading is not tucked under browser or site chrome.
- **Verify content before capturing:** Check that the page has visible headings/images (not blank). If blank, wait 5s more and retry.
- **Verify file size after capturing:** A blank page produces a PNG < 50KB. If file is too small, log a warning and retry with longer wait.
- Read `site-map.json` and `interaction-plan.json`, then execute only the planned pre-capture steps needed to create each screenshot state
- If a beat needs a true destination or result state, capture additional named states for that same moment instead of faking the change with one screenshot
- Measure selector geometry for click, hover, nav, tab, and accordion targets when those beats need a visible target reaction in Remotion
- Take `page.screenshot({ type: "png" })` — viewport only, not full-page
- Dismiss cookie banners and overlays before discovery, after every navigation, after every section-alignment scroll, and again immediately before each screenshot
- Store motion metadata in `tour-plan.json`: camera, ordered interaction beats, caption copy, transition mode, target geometry, URL changes, UI sound cues, and any additional captured states
- Output: PNG files in `scripts/video/remotion/public/screenshots/`
- Output: `scripts/video/site-map.json`
- Output: `scripts/video/interaction-plan.json`
- Output: `scripts/video/tour-plan.json` (no narration timestamps — timing comes from `narration-timing.json`)
- If one narration section runs longer than 4–6 seconds, plan additional visual beats inside that same section instead of letting a single screenshot sit unchanged
- Prefer a mix of interaction behaviors across the demo: some quiet, some scroll-led, some click-led, some state-led. Repetition should be justified by the product, not by the template
- Reject a screenshot and recapture if any of these are true:
  - the section heading is clipped or sits too low in the viewport
  - the frame begins mid-section or mid-card-row
  - a cookie banner, consent modal, chat launcher, or sticky announcement obscures the content
  - the screenshot shows only a partial proof module with awkward whitespace above it

#### CRITICAL — Screenshot Brightness & Contrast Verification

Many websites (especially developer tools, creative platforms, and modern SaaS) use dark-themed hero sections or entire dark-themed pages. When the video itself uses a dark background (`bgPrimary`), dark screenshots become invisible — they blend into the video background and appear as blank/black frames.

**Before proceeding to Phase 6, verify EVERY screenshot for contrast against the video background:**

1. **Visual inspection** — open each PNG and check: does the screenshot have clearly visible content with sufficient contrast? A screenshot that is mostly dark navy, black, or deep purple will disappear against a dark video background.

2. **Dark-theme detection** — if the website's hero section or captured page has a dark background (navy, black, charcoal), either:
   - Scroll past the dark hero to lighter content sections below
   - Use a different page that has a light/white background
   - Capture a specific product UI section that has its own light internal background (e.g., an embedded app preview, card grid, or content area)

3. **Reject and recapture** if:
   - The screenshot's dominant background color is within ~60 luminance units of the video's `bgPrimary`
   - The screenshot would be hard to distinguish from the dark device frame and video background
   - The page has a dark hero that takes up >50% of the viewport — scroll past it or use a different page

4. **Prefer light-background pages** for demo screenshots when the video uses a dark theme. Good candidates: product feature pages, documentation, templates/marketplace, pricing pages with light backgrounds, integrations pages. Bad candidates: homepage dark heroes, dark-themed landing sections, pages dominated by video/animation backgrounds.

CRITICAL — what NOT to do:
- Don't use `recordVideo` — screen recordings look amateur with jittery scrolling and loading states
- Don't capture loading/blank states — verify visible content before every capture
- Don't rely solely on `networkidle` — use `domcontentloaded` + `waitForSelector` + settle time
- Don't capture more than 14 screenshots or visual beats (transitions feel rushed)
- Don't capture fewer than 4 (demo feels static)
- Don't capture full-page screenshots — viewport-only matches the Remotion frame
- Don't skip PNG verification — always visually inspect all screenshots before proceeding to Phase 6
- Don't add highlight boxes or callout rectangles over screenshots
- Don't use generic top-of-page screenshots when a more product-specific state is available
- Don't let a screenshot progress to Remotion if the focal content is weak, cropped badly, or visually ambiguous
- Don't let one unchanged visual state sit for longer than 4–6 seconds unless there is a compelling reason
- Don't use dark-themed page screenshots when the video has a dark background — they will blend together and appear blank

Run:
```bash
bun scripts/video/capture-demo.ts
```

### Phase 6: Scaffold Remotion Project

Create the Remotion project structure at `scripts/video/remotion/`:

```
scripts/video/remotion/
  package.json
  tsconfig.json
  remotion.config.ts
  src/
    Root.tsx
    ExplainerVideo.tsx
    scenes/          (scene components — names/count vary per video)
    components/      (reusable components — designed per creative direction)
    lib/
      branding.ts    (reads branding.json — all colors, fonts, style tokens)
      timing.ts      (timing utilities)
  public/
    screenshots/       (captured product screenshots)
    narration-segments/ (individual TTS files per section)
    narration.mp3      (concatenated final narration)
    logo.svg
```

The exact scene names and component names are NOT fixed. Design them to match the creative direction from Phase 2. A cinematic video might have different scene types than a playful one.

#### package.json

```json
{
  "name": "explainer-video",
  "private": true,
  "scripts": {
    "studio": "npx remotion studio",
    "render": "npx remotion render ExplainerVideo --output ../../output/explainer-video.mp4"
  },
  "dependencies": {
    "remotion": "^4.0.0",
    "@remotion/cli": "^4.0.0",
    "@remotion/media": "^4.0.0",
    "@remotion/transitions": "^4.0.0",
    "@remotion/light-leaks": "^4.0.0",
    "@remotion/google-fonts": "^4.0.0",
    "@remotion/paths": "^4.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "typescript": "^5.0.0"
  }
}
```

#### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

#### remotion.config.ts

```ts
import { Config } from "@remotion/cli/config";

Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
```

Install dependencies:
```bash
cd scripts/video/remotion && npm install
```

### Phase 7: Build Scene Components

Build each scene as a React component. **All animations MUST be driven by `useCurrentFrame()`** — CSS transitions and animations are forbidden in Remotion.

#### CRITICAL: Use the Complete Scene Composition Templates

Before writing ANY scene, read the **"Complete Scene Composition Reference"** section at the bottom of [remotion-scenes.md](${CLAUDE_SKILL_DIR}/references/remotion-scenes.md). These are production-ready scene implementations that combine all 4 layers into visually rich output. **Every scene MUST be based on one of these templates** — adapt the content, colors, and layout but keep the structural richness (glow orbs, geometric accents, glassmorphism cards, solid readable headlines with decorative sweeps, blur-in entrances).

A scene that's just text on a gradient is a PowerPoint slide. If your scene doesn't have at least 2 Layer-2 decorative elements, glassmorphism containers for content, and blur-in or scale+translate entrances — it's not done.

Also read [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) for the quality standard. Every scene MUST follow:

1. **The 4-Layer Frame Model** — every scene needs: animated background (Layer 1), decorative mid-ground elements with AT LEAST 2 distinct elements (Layer 2), content in containers/cards not bare text (Layer 3), and film overlay with grain + vignette (Layer 4).
2. **Scene Layout Variety** — no two consecutive scenes may share the same layout archetype. Use the vocabulary: centered-stack, asymmetric-left, asymmetric-right, split-screen, card-contained, full-bleed, diagonal.
3. **Typography Animation Variety** — vary text animations across scenes. Don't use fadeUp everywhere. Choose from: blur-in, masked reveal, letter stagger, decorative headline sweeps, scale-bounce, split-line, typewriter, stagger. Keep critical copy on solid fills rather than transparent clipped text.
4. **Demo Screenshot Carousel** — the demo scene MUST use a screenshot carousel with shot-specific camera choreography, caption overlays, and animated URL bar — NOT a screen recording.
5. **Light Leaks** — use `@remotion/light-leaks` `<LightLeak>` overlay in **at most 1 scene**, as a brief flash (10–18 frames, opacity 0.12–0.20). It must feel like a quick camera flare — never a slow glow crawling across the frame. Wrap it in an opacity interpolation so it flashes in and out. If it reads as slow or heavy, remove it entirely.
6. **Decorative Elements** — every non-demo scene needs AT LEAST TWO visual elements besides text (floating gradient orbs, accent lines, geometric shapes, conic-gradient rings, floating particles, bokeh circles).
7. **Content Containers** — problem/benefits/stats scenes MUST use glassmorphism cards (backdrop-blur + semi-transparent bg + subtle border) — NEVER bare text or bullet lists on a gradient.
8. **Glow Effects** — at least 2 scenes should have `textShadow` glow on accent text or numbers.

#### Design source: frontend-design skill

Also re-read the [frontend-design](${CLAUDE_SKILL_DIR}/../frontend-design/SKILL.md) skill. Every visual decision — backgrounds, typography styling, color usage, spatial layout, motion character — must follow its guidelines and the creative direction established in Phase 2.

**DO NOT** hardcode any of the following:
- Color values (read from `branding.ts`)
- Font families (load via `@remotion/google-fonts` using the fonts from `branding.json`)
- Background styles (design per the `style.backgroundType` from branding config)
- Layout patterns (follow the `style.layoutStyle` from branding config)
- Motion timing (match the `style.motionStyle` from branding config)

#### Remotion API reference

Consult the remotion-best-practices skill for Remotion-specific patterns:
- [animations.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/animations.md) — `useCurrentFrame()`, `interpolate()`
- [timing.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/timing.md) — `spring()`, easing curves
- [sequencing.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/sequencing.md) — `<Sequence>`, `<Series>`, premounting
- [text-animations.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/text-animations.md) — typewriter, word highlight
- [images.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/images.md) — `<Img>` component (MUST use, not `<img>`)
- [videos.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/videos.md) — `<Video>` for screen recording
- [audio.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/audio.md) — `<Audio>` for narration/music/SFX
- [fonts.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/fonts.md) — `@remotion/google-fonts`
- [sfx.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/sfx.md) — sound effect URLs
- [light-leaks.md](${CLAUDE_SKILL_DIR}/../remotion-best-practices/rules/light-leaks.md) — `<LightLeak>` overlays

See [remotion-scenes.md](${CLAUDE_SKILL_DIR}/references/remotion-scenes.md) for structural animation patterns (multi-layer backgrounds, floating elements, glassmorphism cards, staggered lists, counting numbers, Ken Burns zoom, safe headline sweeps, blur-in reveals, demo captions). These patterns provide the animation skeleton — you apply the creative direction's visual skin on top.

#### Typical scene types

A standard explainer video includes these scene categories. **Base each scene on the corresponding template from the "Complete Scene Composition Reference" in remotion-scenes.md.** Adapt names, count, content, and design per the creative direction — but keep the structural richness. **Each scene must use a different layout archetype from its neighbors:**

- **Opening** (2–3s) — logo with glow halo, floating particles, geometric border, blur-in entrance — see IntroScene template — **centered-stack** layout
- **Title** (4–6s) — solid headline with decorative sweep, accent line drawing, decorative orbs, staggered entrance — see TitleScene template — **asymmetric-left** or **full-bleed** layout
- **Problem** (5–7s) — glassmorphism cards in 2x2 grid with icons, negative-tinted glow, staggered card entrance — see ProblemScene template — **card-contained** or **split-screen** layout. **NEVER a bullet list.**
- **Demo** (35–45s) — screenshot carousel or micro-sequence in a device frame, full-bleed crop, or split-proof layout with shot-specific camera motion, captions, optional URL framing, and optional cursor cues. **Each narration section's window is derived from `narration-timing.json`**, but that window may contain multiple visual beats
- **Benefits** (4–6s) — feature cards with accent bars, asymmetric layout with decorative ring elements — see BenefitsScene template — **must use different layout than Problem** (e.g., if Problem is card-contained, Benefits should be asymmetric-right)
- **Stats** (3–4s) — animated number counting with glow effects, numbers in glassmorphism cards — see StatsScene template — **full-bleed** or **centered** layout
- **Section dividers** (3–4s) — heading + description transitions with solid readable text plus accent elements
- **Closing** (4–6s) — logo, tagline, pulsing CTA with glow, optional brief light leak flash — see OutroScene template — **centered-stack** layout

#### Key rules

- All colors come from `branding.ts` — zero hardcoded hex/rgb values in scene files
- All fonts loaded via `@remotion/google-fonts` — the specific fonts chosen in Phase 2
- Background components designed to match `style.backgroundType` — could be gradient mesh, geometric patterns, noise texture, layered transparencies, or anything the creative direction demands
- Backgrounds must have **constant visible motion** — never static gradients
- Device frame styling matches the overall aesthetic (dark chrome for dark themes, light for light, etc.)
- Device frame content area (where screenshots render) MUST have `backgroundColor: "#FFFFFF"` — this prevents dark screenshots from blending with the video's dark background and ensures visibility regardless of the screenshot's theme
- Device frame uses **1680px width** at 1920x1080 resolution
- Animation spring configs and timing match `style.motionStyle`
- Do not place highlight boxes or callout rectangles over screenshots; emphasis should come from shot selection, camera intent, and captions
- Internal demo transitions should usually be **6–10 frames**. Only use 12+ frame transitions for major structural breaks
- Do not use the same transition type more than twice in a row
- Every 2–4 seconds, the viewer should receive a new visual beat, claim, or proof point

### Phase 8: Compose the Scene Timeline

Build `ExplainerVideo.tsx` — the main composition that arranges all scenes.

See [audio-mixing.md](${CLAUDE_SKILL_DIR}/references/audio-mixing.md) for narration + music + SFX patterns.

#### Timeline layout

```tsx
import { TransitionSeries, linearTiming, springTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { wipe } from "@remotion/transitions/wipe";
```

Arrange scenes with the sequencing primitive that best preserves sync.

- Prefer `<Series>` when exact narration sync is the priority.
- Use `<TransitionSeries>` only if you intentionally account for overlap and have verified that the overlap does not shorten a narrated scene window.
- Choose transitions that match the creative direction's motion style, but never at the expense of timing accuracy.

**Important:** Transitions overlap adjacent scenes, so total duration = sum of sequence durations minus sum of transition durations.

#### CRITICAL — TransitionSeries Overlap Compensation

When using `TransitionSeries` for the demo screenshot carousel, transitions eat frames from the total duration. For N shots with T-frame transitions, the effective visual duration is:

```
effective_duration = sum(shot_durations) - (N - 1) * T
```

If the parent `<Sequence>` gives the DemoScene more frames than the TransitionSeries fills, the leftover frames show the raw background (usually dark) — creating a visible blank/black gap at the end of the demo.

**The fix:** Extend the LAST shot's `durationInFrames` by the total overlap amount so the TransitionSeries fills the full parent Sequence:

```tsx
const TRANS_FRAMES = 8;
const NUM_TRANSITIONS = shots.length - 1;
const OVERLAP_COMPENSATION = NUM_TRANSITIONS * TRANS_FRAMES;

// In the shots array, add OVERLAP_COMPENSATION to the last shot's duration:
{ ...lastShot, durationInFrames: lastShot.durationInFrames + OVERLAP_COMPENSATION }
```

This ensures `effective_duration = sum(adjusted_durations) - overlap = DEMO_TOTAL`. Always verify this formula when using `TransitionSeries` — a timing mismatch of even 40 frames (1.3s) produces a visible dark gap.

**CRITICAL — Audio-visual sync via narration-timing.json:**

Scene durations come from **measured audio durations** in `narration-timing.json`, NOT from estimates. In `ExplainerVideo.tsx`:

1. Import `narration-timing.json`
2. For each scene, find its segment by `sceneId` and compute `durationInFrames` from the measured timing window in `narration-timing.json`
3. The intro scene (logo reveal) has no narration — use a fixed 3s
4. If `narration-timing.json` includes cumulative `offset` values, derive each scene's usable window from adjacent offsets so silence padding is preserved correctly
5. The DemoScene's total duration = the full `demo-*` timing window, including any between-shot padding
6. Individual screenshot durations within DemoScene: filter `narration-timing.json` for `demo-*` segments and use the measured timing windows, not rough estimates

If a screenshot transitions while the narrator is still talking about that feature, the sync is broken. Measured timing only solves this if your sequencing model honors the full narrated window and does not accidentally shorten it with overlapping transitions.

#### Audio layers (ALL THREE ARE REQUIRED)

Place these in `ExplainerVideo.tsx` alongside the scene timeline. A professional video without background music feels empty and amateur — all three layers are mandatory:

1. **Narration** — `<Audio src={staticFile("narration.mp3")} />` (the concatenated file from Phase 4d)
2. **Background music (REQUIRED)** — `<Audio src={staticFile("music.mp3")} volume={(f) => { ... }} loop />` with fade in/out. Volume at 8-12% under narration, loop for full duration. Ask the user for their preferred track, or source a royalty-free ambient/electronic loop. See [audio-mixing.md](${CLAUDE_SKILL_DIR}/references/audio-mixing.md) for the fade in/out volume callback pattern.
3. **Transition SFX** — `<Audio>` in `<Sequence>` at each transition point, volume 0.25. Vary SFX types — don't use the same whoosh for every transition. See the available SFX in audio-mixing.md.

#### Root.tsx and calculateMetadata

`Root.tsx` defines the composition with `calculateMetadata` that:
1. Reads narration audio duration using `getAudioDuration()`
2. Converts to frames: `Math.ceil(durationInSeconds * fps)`
3. Returns `{ durationInFrames }` so the composition matches the audio

```tsx
import { Composition } from "remotion";
import { ExplainerVideo } from "./ExplainerVideo";

export const RemotionRoot = () => {
  return (
    <Composition
      id="ExplainerVideo"
      component={ExplainerVideo}
      durationInFrames={30 * 80}
      fps={30}
      width={1920}
      height={1080}
      calculateMetadata={calculateMetadata}
    />
  );
};
```

### Phase 9: Quality Check & Render

#### Pre-Render Quality Checklist

Before rendering, verify every item. If any check fails, fix it before proceeding:

```
Quality Checklist:
- [ ] Resolution is 1920x1080 (check Root.tsx width/height)
- [ ] Every scene follows the 4-layer frame model (background, mid-ground, content, overlay)
- [ ] Every scene background has constant visible motion (no static gradients)
- [ ] No two consecutive scenes share the same layout archetype
- [ ] Text animations vary across scenes (not all fadeUp or all stagger)
- [ ] Demo scene uses screenshot carousel with shot-specific camera choreography (no screen recordings)
- [ ] Each scene's durationInFrames matches its measured narration segment in narration-timing.json
- [ ] Each demo screenshot's durationInFrames matches its demo-* segment in narration-timing.json
- [ ] No blank/empty screenshots — verify every PNG has visible content before rendering
- [ ] No dark-on-dark screenshots — every screenshot has sufficient contrast against the video's bgPrimary color
- [ ] Device frame content area has a white (#FFFFFF) background behind screenshots
- [ ] TransitionSeries overlap is compensated — last shot duration includes (N-1)*TRANS_FRAMES extra frames
- [ ] Demo emphasis comes from shot choice, camera movement, and captions rather than highlight boxes over the UI
- [ ] Every non-demo scene has at least one decorative element besides text
- [ ] Light leaks are either absent or used in at most 1 scene as a brief flash (10–18 frames, opacity ≤ 0.20) — never a sustained glow across the full scene
- [ ] Background music is present with fade in/out
- [ ] Transition SFX are present and varied
- [ ] Narration sounds human-like, emotionally appropriate, and not machine-flat
- [ ] All colors come from branding.ts (zero hardcoded hex values in scenes)
- [ ] Text respects safe zones (within 90% of frame, ~96px margins)
- [ ] Body text is at least 32px, headlines at least 64px
- [ ] All text is on screen for at least 2 seconds before transitioning
```

If the checklist reveals issues, fix them now. Re-read [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) for the specific patterns and code to apply.

#### Post-Render Self-Critique Loop

After rendering, do not approve the video immediately. Run all three review passes:

1. **Uninterrupted watch** — watch the full MP4 at normal speed with sound on. Judge only story clarity, energy, polish, and whether it feels like a professional product ad rather than a careful walkthrough
2. **Scene-by-scene watch** — pause on each scene change and check legibility, weak crops, dead holds, awkward transitions, and whether the visuals support the spoken line within roughly half a second
3. **Audio-focused pass** — listen for narration clarity, music masking, SFX harshness, unnatural silence gaps, loop seams, and whether the CTA lands clearly after the final spoken line

Log issues as:
- `blocking` — must fix before approval
- `major` — rerender if two or more remain
- `minor` — polish if time allows

#### Final Acceptance Checklist

Before calling the video complete, verify:

```
Final Acceptance Checklist:
- [ ] The first 3 seconds establish the brand/product and feel intentional
- [ ] The product or interface appears by 6–8 seconds unless the user asked for a slower structure
- [ ] No shot feels like filler or passive browsing
- [ ] No unchanged visual state lingers longer than 4–6 seconds without a clear reason
- [ ] Every spoken claim is visually supported within about half a second
- [ ] Captions explain why the moment matters, not just what page the viewer is on
- [ ] Cursor intent is obvious before every click, hover, page change, or section jump
- [ ] UI SFX are subtle, purposeful, and synchronized to the interaction beat
- [ ] Music supports momentum and never masks narration
- [ ] The pacing escalates cleanly from hook to demo to proof to CTA
- [ ] The final CTA holds long enough to read after the last spoken line
- [ ] The finished video feels branded and distinctive, not generic SaaS filler
```

#### Rework Triggers

Rework and rerender if any of these are true:

- The narration references a feature before it appears on screen
- Two or more scenes feel rushed, mushy, or overlong
- A screenshot is technically valid but compositionally weak, cluttered, or visually ambiguous
- A screenshot has a dark background that blends with the video's dark theme, appearing blank or invisible
- A screenshot starts in the middle of a section instead of at a clear section boundary
- A cookie banner, consent modal, or sticky widget remains visible in any captured product shot
- The demo section has a visible dark gap between the last screenshot and the next scene (TransitionSeries overlap not compensated)
- Music or SFX make any narration line harder to understand
- The voice sounds robotic, overly even, or obviously synthetic
- Sentence rhythm repeats so consistently that the delivery feels machine-generated
- A click, hover, or section jump happens without a clear visual payoff
- The cursor path feels random, robotic, or disconnected from the narration beat
- The export feels polished but low-energy or generic after the uninterrupted watch

#### Preview and Render

Preview in Remotion Studio:
```bash
cd scripts/video/remotion && npx remotion studio
```

Render final video:
```bash
cd scripts/video/remotion && npx remotion render ExplainerVideo --output ../../../output/explainer-video.mp4
```

Review the output. Common adjustments:
- **Scene too short/long:** Adjust `durationInFrames` in the scene sequence and re-check the measured timing window
- **Animation too fast/slow:** Adjust spring config or interpolation ranges
- **Demo screenshot timing off:** Check `narration-timing.json` — durations should derive from measured segments
- **Demo feels dead:** Split one narration section into multiple visual beats, tighten transitions, or shorten the spoken copy
- **Audio out of sync:** Re-run Phase 4c to re-measure segment durations and recompute scene durationInFrames
- **Music too loud:** Lower the volume prop on the background music `<Audio>`
- **Transition too abrupt or too mushy:** Rebalance toward the 6–10 frame default and align cuts with phrase endings
- **TTS mispronunciation:** Edit the section text in `narration-sections.json` and regenerate that segment's TTS, then re-concatenate
- **Narration sounds robotic:** Change the voice, lower stability slightly, rewrite lines for spoken rhythm, regenerate 2-3 test segments, then rerender
- **Design feels generic:** Re-read the video-design-principles.md, reconsider the creative direction, and redesign the scenes

## File Structure

```
scripts/video/
  branding.json              (creative direction + brand identity + voice — NO defaults)
  narration-sections.json    (per-section narration text with sceneId mapping)
  narration-timing.json      (measured durations and offsets per segment)
  capture-demo.ts
  tour-plan.json
  remotion/
    package.json
    tsconfig.json
    remotion.config.ts
    src/
      Root.tsx
      ExplainerVideo.tsx
      scenes/                (designed per creative direction — names vary)
      components/            (designed per creative direction — no hardcoded visuals)
      lib/
        branding.ts          (reads branding.json — all design tokens)
        timing.ts
    public/
      screenshots/           (captured PNG screenshots of the product)
      narration-segments/    (individual TTS files per section)
      narration.mp3          (concatenated final narration)
      music.mp3
      logo.svg
output/
  explainer-video.mp4
```

## .gitignore Additions

```
/output/
scripts/video/remotion/public/narration.mp3
scripts/video/remotion/public/narration-segments/
scripts/video/remotion/public/screenshots/
scripts/video/remotion/node_modules/
```
