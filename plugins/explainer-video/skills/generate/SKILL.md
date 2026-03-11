---
name: generate
description: Produce a professional branded marketing explainer video for any web application using Remotion. Orchestrates Playwright-powered product capture, animated Remotion scenes, ElevenLabs narration, background music, sound effects, and Remotion rendering. All visual design is driven by the bundled frontend-design skill — never hardcode aesthetics.
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
- **ElevenLabs MCP** or **edge-tts** for narration
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

Do NOT default to a hardcoded voice. Analyze the platform's audience and tone, then find a matching voice.

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
3. Pick a voice that sounds active, modern, and fits the brand — avoid generic "old narrator" voices
4. Save the chosen `voice_id` and `voice_name` in `branding.json` (see Step 5)

**Voice parameters** — tune these for professional explainer quality:
- `stability`: 0.55–0.65 (enough consistency without sounding robotic)
- `similarity_boost`: 0.75–0.85 (maintain voice character)
- `style`: 0.1–0.2 (subtle expressiveness)
- `speed`: 0.9–1.0 (slightly slower for clarity)

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
    "speed": 0.95
  }
}
```

**CRITICAL:** Every field must reflect a deliberate design decision. If you find yourself reaching for purple/violet gradients on dark backgrounds, STOP — you're falling into generic AI aesthetics. Consult the frontend-design skill and the user's direction again.

### Phase 3: Write Narration (Per-Section)

Write a 60–90 second script (~150–200 words). See [narration-guide.md](${CLAUDE_SKILL_DIR}/references/narration-guide.md).

#### CRITICAL: Write narration as separate named sections

Do NOT write one continuous script with estimated timestamps. Instead, write each scene's narration as a separate section in a JSON array. Each section is generated as a separate TTS audio file in Phase 4, and the **measured audio duration** of each segment drives that scene's `durationInFrames`. This guarantees perfect audio-visual sync.

Save to `scripts/video/narration-sections.json`:

```json
[
  { "sceneId": "title", "text": "Hubstaff. Time tracking and productivity monitoring for the modern hybrid workforce." },
  { "sceneId": "problem", "text": "Managing remote teams shouldn't mean endless check-ins, manual timesheets, and guessing who's doing what." },
  { "sceneId": "transition", "text": "Here's how Hubstaff changes that." },
  { "sceneId": "demo-01", "screenshotId": "01-homepage-hero", "text": "Hubstaff brings time tracking, productivity insights, and payroll into one powerful platform — trusted by over a hundred thousand businesses worldwide." },
  { "sceneId": "demo-02", "screenshotId": "02-productivity", "text": "See exactly how your team spends their time with actionable productivity metrics — no micromanagement required." },
  { "sceneId": "demo-03", "screenshotId": "03-workforce", "text": "Manage schedules, attendance, and time-off requests from a single intuitive dashboard." },
  { "sceneId": "demo-04", "screenshotId": "04-integrations", "text": "Connect with over thirty-five tools your team already uses — from Jira and Slack to QuickBooks and Salesforce." },
  { "sceneId": "demo-05", "screenshotId": "05-pricing", "text": "Choose from flexible plans that scale with your team, starting with a free fourteen-day trial." },
  { "sceneId": "stats", "text": "Half a million active users. Twenty-one million hours tracked. Four million tasks completed." },
  { "sceneId": "cta", "text": "Start your free trial today at hubstaff dot com." }
]
```

Each `sceneId` maps to a video scene. Demo sections include a `screenshotId` that links to the corresponding screenshot in `tour-plan.json`.

**Section structure:**
1. **title** — Hook: What is this tool? (1-2 sentences)
2. **problem** — Pain point it solves (1-2 sentences)
3. **transition** — Bridge to demo (1 short sentence)
4. **demo-01 through demo-05** (or more) — One section per screenshot, narrate what's on screen
5. **stats** — Key metrics or social proof
6. **cta** — Call to action

**Writing guidelines for natural cross-section flow:**
- Each section's last sentence should trail off naturally (no abrupt stops)
- Each section's first sentence should continue the narrative thread
- Use connective phrases at section starts: "And with...", "From here...", "What's more..."
- Keep punctuation consistent — end with periods, not exclamation marks
- Avoid starting two consecutive sections the same way
- The TTS model maintains consistent style when text flows naturally

**Pronunciation gotchas for TTS (IMPORTANT):**
- Spell out abbreviations TTS might mangle: ".docx" → "dot docx"
- Avoid "analyses" (verb) — TTS reads it as the noun. Use "reviews" or "examines"
- Numbers: spell out for consistent pronunciation ("thirty-five" not "35", "a hundred thousand" not "100,000")
- URLs: use "dot" instead of "." ("hubstaff dot com")

### Phase 4: Generate Audio (Per-Section TTS)

Generate narration as **separate TTS files per section**, measure each segment's actual duration, then concatenate into a single narration file. This guarantees perfect audio-visual sync — scene durations are derived from measured audio, not estimates.

#### Phase 4a: Select Voice

Use the voice settings from `branding.json` (chosen in Phase 2). All segments MUST use the same `voice_id`, `model_id`, `stability`, `similarity_boost`, `style`, and `speed` — this ensures consistent voice character across sections.

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
  "paddingSeconds": 0.3,
  "totalDuration": 0
}
```

Compute `totalDuration` as: `sum(all segment durations) + (segment_count - 1) * paddingSeconds`.

#### Phase 4d: Concatenate Into Final Narration

Use ffmpeg to concatenate all segments with 300ms silence padding between them. The padding creates natural breathing room and eliminates tonal jarring between separately-generated segments.

```bash
# Generate a 300ms silence file
ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t 0.3 -q:a 9 -acodec libmp3lame /tmp/silence.mp3

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

**Fallback (if ElevenLabs is unavailable):** Use `edge-tts` per section:
```bash
edge-tts --text "<section text>" --voice en-AU-WilliamNeural --write-media scripts/video/remotion/public/narration-segments/01-title.mp3
```

### Phase 5: Capture Demo Screenshots

The demo section uses **high-resolution screenshots** animated in Remotion — NOT live screen recordings. Playwright captures pixel-perfect screenshots of each key page/feature, then Remotion handles transitions, Ken Burns drift, and captions. This produces far smoother results than `recordVideo`.

See [playwright-recording.md](${CLAUDE_SKILL_DIR}/references/playwright-recording.md) for setup, discovery patterns, and capture techniques.

**Phase 5a: Discover the Platform**

Before capturing anything, explore the site to understand its structure:

- For PUBLIC URLs: Use Playwright to navigate to the site, extract nav links, read page headings, identify interactive elements. Build a map of available pages and features.
- For LOCAL APPS: Read the project's router config, page components, and route definitions. Start the app and verify key routes.

**Phase 5b: Plan the Capture Tour**

Plan 5-8 screenshots across 3-5 pages. **Each screenshot must correspond to a `demo-*` section in `narration-sections.json`** — the `screenshotId` field links them.

1. Map each `demo-*` section from `narration-sections.json` to a specific screenshot capture
2. The narration sections define which pages/features to capture — don't capture pages that aren't mentioned in the narration
3. Prefer stateful product moments over generic full-page holds. If a richer feature section, selected tab, expanded accordion, or toggled pricing state better matches the narration, capture that instead of the default top-of-page view.
4. For each page, decide what view to capture (hero, scrolled to features, specific tab selected, hovered card, expanded accordion, toggled pricing mode)
5. Multiple captures per page are encouraged — e.g., homepage hero + homepage features section
6. Treat `tour-plan.json` as a shot script, not just an asset manifest. Include motion intent, caption copy, and any overlay geometry the Remotion layer will need.
7. If you intend to place a highlight box, cursor target, or callout over a UI element, derive its geometry from the page during capture time whenever possible. Do not guess box positions by eye after the screenshot is already taken.
8. Create a `tour-plan.json` at `scripts/video/` describing each screenshot. **Do NOT include narration timestamps** — screenshot durations come from `narration-timing.json` (measured audio):

```json
[
  {
    "id": "01-homepage-hero",
    "file": "screenshots/01-homepage-hero.png",
    "label": "Homepage",
    "url": "example.com",
    "description": "Landing hero",
    "eyebrow": "Unified workspace",
    "headline": "Projects, docs, and AI in one system.",
    "subheadline": "Guide the viewer from the promise to the primary CTA.",
    "transitionStyle": "focus",
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
    "emphasis": [
      {
        "x": 12,
        "y": 16,
        "width": 44,
        "height": 18,
        "label": "Core message",
        "startProgress": 0.12,
        "endProgress": 0.42
      }
    ],
    "interaction": {
      "path": [
        { "x": 78, "y": 18, "progress": 0 },
        { "x": 38, "y": 34, "progress": 0.36 },
        { "x": 26, "y": 52, "progress": 0.72 }
      ],
      "clicks": [{ "x": 26, "y": 52, "progress": 0.76 }]
    },
    "sourceSelectors": {
      "primary": "section.hero",
      "highlight": [
        { "selector": "h1", "label": "Core message" },
        { "selector": "a[href*='signup'], button", "label": "Primary CTA" }
      ]
    }
  }
]
```

Each screenshot's display duration in the video is determined by the corresponding `demo-*` segment in `narration-timing.json` (measured in Phase 4c), NOT by estimated timestamps.
The tour plan should be rich enough that Remotion can animate each shot with camera choreography, richer captions, cursor cues, and selector-derived highlights instead of generic one-size-fits-all motion.

**Phase 5c: Capture Screenshots**

Write `scripts/video/capture-demo.ts` that executes the planned capture tour:

- Viewport: 1920x1080 with `deviceScaleFactor: 2` for retina-sharp text
- Navigate to each page using `waitUntil: "domcontentloaded"` (NOT `networkidle` — many sites have persistent connections that prevent it from resolving)
- After navigation, wait for a visible content selector (`h1, h2, img, svg`) with 8s timeout, then add 2000ms settle time for fonts/animations
- **Verify content before capturing:** Check that the page has visible headings/images (not blank). If blank, wait 5s more and retry.
- **Verify file size after capturing:** A blank page produces a PNG < 50KB. If file is too small, log a warning and retry with longer wait.
- Perform any pre-capture actions (scroll to section, click tab, hover element, toggle pricing, expand accordion)
- Take `page.screenshot({ type: "png" })` — viewport only, not full-page
- Dismiss cookie banners before capturing
- When a shot needs a highlight, cursor, or callout, collect the target element's bounding box during capture and normalize it to percentages so the overlay matches the screenshot
- Store motion metadata in `tour-plan.json`: camera, emphasis, interaction, caption copy, and any selector-derived geometry
- Output: PNG files in `scripts/video/remotion/public/screenshots/`
- Output: `scripts/video/tour-plan.json` (no narration timestamps — timing comes from `narration-timing.json`)

CRITICAL — what NOT to do:
- Don't use `recordVideo` — screen recordings look amateur with jittery scrolling and loading states
- Don't capture loading/blank states — verify visible content before every capture
- Don't rely solely on `networkidle` — use `domcontentloaded` + `waitForSelector` + settle time
- Don't capture more than 8 screenshots (transitions feel rushed)
- Don't capture fewer than 4 (demo feels static)
- Don't capture full-page screenshots — viewport-only matches the Remotion frame
- Don't skip PNG verification — always visually inspect all screenshots before proceeding to Phase 6
- Don't guess overlay coordinates by eye if a DOM selector can be measured during capture
- Don't use generic top-of-page screenshots when a more product-specific state is available
- Don't let a screenshot progress to Remotion if the focal content is weak, cropped badly, or visually ambiguous

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

Before writing ANY scene, read the **"Complete Scene Composition Reference"** section at the bottom of [remotion-scenes.md](${CLAUDE_SKILL_DIR}/references/remotion-scenes.md). These are production-ready scene implementations that combine all 4 layers into visually rich output. **Every scene MUST be based on one of these templates** — adapt the content, colors, and layout but keep the structural richness (glow orbs, geometric accents, glassmorphism cards, gradient text, blur-in entrances).

A scene that's just text on a gradient is a PowerPoint slide. If your scene doesn't have at least 2 Layer-2 decorative elements, glassmorphism containers for content, and blur-in or scale+translate entrances — it's not done.

Also read [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) for the quality standard. Every scene MUST follow:

1. **The 4-Layer Frame Model** — every scene needs: animated background (Layer 1), decorative mid-ground elements with AT LEAST 2 distinct elements (Layer 2), content in containers/cards not bare text (Layer 3), and film overlay with grain + vignette (Layer 4).
2. **Scene Layout Variety** — no two consecutive scenes may share the same layout archetype. Use the vocabulary: centered-stack, asymmetric-left, asymmetric-right, split-screen, card-contained, full-bleed, diagonal.
3. **Typography Animation Variety** — vary text animations across scenes. Don't use fadeUp everywhere. Choose from: blur-in, masked reveal, letter stagger, gradient shimmer, scale-bounce, split-line, typewriter, stagger.
4. **Demo Screenshot Carousel** — the demo scene MUST use a screenshot carousel with shot-specific camera choreography, caption overlays, and animated URL bar — NOT a screen recording.
5. **Light Leaks** — use `@remotion/light-leaks` `<LightLeak>` overlay in at least 2-3 scenes for cinematic depth.
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

See [remotion-scenes.md](${CLAUDE_SKILL_DIR}/references/remotion-scenes.md) for structural animation patterns (multi-layer backgrounds, floating elements, glassmorphism cards, staggered lists, counting numbers, Ken Burns zoom, gradient text, blur-in reveals, demo callouts). These patterns provide the animation skeleton — you apply the creative direction's visual skin on top.

#### Typical scene types

A standard explainer video includes these scene categories. **Base each scene on the corresponding template from the "Complete Scene Composition Reference" in remotion-scenes.md.** Adapt names, count, content, and design per the creative direction — but keep the structural richness. **Each scene must use a different layout archetype from its neighbors:**

- **Opening** (2–3s) — logo with glow halo, floating particles, geometric border, blur-in entrance — see IntroScene template — **centered-stack** layout
- **Title** (4–6s) — gradient shimmer headline, accent line drawing, decorative orbs, staggered entrance — see TitleScene template — **asymmetric-left** or **full-bleed** layout
- **Problem** (5–7s) — glassmorphism cards in 2x2 grid with icons, negative-tinted glow, staggered card entrance — see ProblemScene template — **card-contained** or **split-screen** layout. **NEVER a bullet list.**
- **Demo** (35–45s) — screenshot carousel in a device frame with shot-specific camera motion, captions, animated URL bar, and optional cursor/highlight overlays. **Each screenshot's duration is derived from `narration-timing.json`** — filter for `demo-*` segments and use measured timing windows for each screenshot's `durationInFrames`
- **Benefits** (4–6s) — feature cards with accent bars, asymmetric layout with decorative ring elements — see BenefitsScene template — **must use different layout than Problem** (e.g., if Problem is card-contained, Benefits should be asymmetric-right)
- **Stats** (3–4s) — animated number counting with glow effects, numbers in glassmorphism cards — see StatsScene template — **full-bleed** or **centered** layout
- **Section dividers** (3–4s) — heading + description transitions with gradient text and accent elements
- **Closing** (4–6s) — logo, tagline, pulsing CTA with glow, light leak — see OutroScene template — **centered-stack** layout

#### Key rules

- All colors come from `branding.ts` — zero hardcoded hex/rgb values in scene files
- All fonts loaded via `@remotion/google-fonts` — the specific fonts chosen in Phase 2
- Background components designed to match `style.backgroundType` — could be gradient mesh, geometric patterns, noise texture, layered transparencies, or anything the creative direction demands
- Backgrounds must have **constant visible motion** — never static gradients
- Device frame styling matches the overall aesthetic (dark chrome for dark themes, light for light, etc.)
- Device frame uses **1680px width** at 1920x1080 resolution
- Animation spring configs and timing match `style.motionStyle`
- Demo highlights, cursor targets, and callouts should come from capture-time geometry whenever possible, not guessed percentages authored after the screenshot is taken

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
- [ ] Any highlight boxes or callouts align with the actual captured UI, preferably from selector-derived geometry
- [ ] Every non-demo scene has at least one decorative element besides text
- [ ] @remotion/light-leaks <LightLeak> used in at least 2 scenes
- [ ] Background music is present with fade in/out
- [ ] Transition SFX are present and varied
- [ ] All colors come from branding.ts (zero hardcoded hex values in scenes)
- [ ] Text respects safe zones (within 90% of frame, ~96px margins)
- [ ] Body text is at least 32px, headlines at least 64px
- [ ] All text is on screen for at least 2 seconds before transitioning
```

If the checklist reveals issues, fix them now. Re-read [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) for the specific patterns and code to apply.

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
- **Audio out of sync:** Re-run Phase 4c to re-measure segment durations and recompute scene durationInFrames
- **Music too loud:** Lower the volume prop on the background music `<Audio>`
- **Transition too abrupt:** Increase transition `durationInFrames`
- **TTS mispronunciation:** Edit the section text in `narration-sections.json` and regenerate that segment's TTS, then re-concatenate
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
