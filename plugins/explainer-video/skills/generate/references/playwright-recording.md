# Playwright Screenshot Capture Patterns

Reference for building `capture-demo.ts` — a Playwright script that captures high-resolution screenshots of the product for the explainer video. Screenshots are used as `<Img>` sources inside Remotion DeviceFrame components, animated with Ken Burns drift and smooth transitions.

**Why screenshots instead of screen recordings:**
- Screenshots are pixel-perfect — no frame drops, no jitter, no rendering artifacts
- Remotion handles all animation (transitions between screenshots, Ken Burns panning, cursor paths) which looks far smoother than Playwright's `recordVideo`
- Page load states, cookie banners, and content pop-in are eliminated — you capture only the fully-rendered state
- Professional SaaS explainer videos almost never use live screen recordings

## Setup

```typescript
import { chromium, type Page } from "playwright";
import { join } from "path";
import { writeFileSync, mkdirSync, existsSync } from "fs";

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";
const SCREENSHOTS_DIR = join(import.meta.dir, "remotion/public/screenshots");
const TOUR_PLAN_PATH = join(import.meta.dir, "tour-plan.json");

if (!existsSync(SCREENSHOTS_DIR)) mkdirSync(SCREENSHOTS_DIR, { recursive: true });
```

## Browser Context

```typescript
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
  deviceScaleFactor: 2, // 2x for crisp retina screenshots
});
const page = await context.newPage();
```

No `recordVideo`. We're taking screenshots, not recording video. Use `deviceScaleFactor: 2` for sharp text on 1080p output.

---

## Three-Phase Capture Approach

Every capture script follows three phases. Do NOT skip Phase A — blindly scripting a tour without discovering the site first produces broken selectors and missed pages.

### Phase A: Site Discovery

Before writing any capture code, explore the site programmatically to understand its structure.

```typescript
const discoveryContext = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
});
const discoveryPage = await discoveryContext.newPage();
await discoveryPage.goto(BASE_URL, { waitUntil: "domcontentloaded" });
```

Extract the site map:

```typescript
const siteMap = await discoveryPage.evaluate((baseUrl: string) => {
  const navLinks = Array.from(
    document.querySelectorAll("nav a, header a, a[href^='/']")
  ).map((a) => ({
    text: (a as HTMLAnchorElement).textContent?.trim() || "",
    href: (a as HTMLAnchorElement).href,
  }));

  const ctaButtons = Array.from(
    document.querySelectorAll(
      "a[href]:not(nav a):not(header a), button"
    )
  )
    .filter((el) => {
      const text = el.textContent?.trim().toLowerCase() || "";
      return (
        text.includes("get started") ||
        text.includes("try") ||
        text.includes("sign up") ||
        text.includes("demo") ||
        text.includes("learn more")
      );
    })
    .map((el) => ({
      text: el.textContent?.trim() || "",
      href: (el as HTMLAnchorElement).href || null,
      tag: el.tagName.toLowerCase(),
    }));

  const headings = Array.from(document.querySelectorAll("h1, h2")).map(
    (h) => ({
      level: h.tagName,
      text: h.textContent?.trim() || "",
    })
  );

  const interactiveElements = {
    tabs: document.querySelectorAll('[role="tab"], [data-tab]').length,
    toggles: document.querySelectorAll(
      '[role="switch"], input[type="checkbox"]'
    ).length,
    carousels: document.querySelectorAll(
      '[role="tabpanel"], .carousel, .swiper'
    ).length,
    dropdowns: document.querySelectorAll("select, [role='listbox']").length,
  };

  return { navLinks, ctaButtons, headings, interactiveElements };
}, BASE_URL);

console.log("Discovered site map:", JSON.stringify(siteMap, null, 2));
await discoveryContext.close();
```

For **local apps** where you have source code access, supplement or replace scraping with codebase inspection:
- Read the router config (Next.js `app/` directory, React Router routes, etc.)
- Identify the primary user flow from the route structure
- Check for auth requirements that need seed data

### Dismiss Cookie Banners and Overlays

Run this before any discovery or capture:

```typescript
async function dismissOverlays(page: Page) {
  const dismissSelectors = [
    'button:has-text("Accept")',
    'button:has-text("Got it")',
    'button:has-text("Close")',
    'button:has-text("Dismiss")',
    '[aria-label="Close"]',
    ".cookie-banner button",
    "#onetrust-accept-btn-handler",
  ];
  for (const selector of dismissSelectors) {
    const btn = page.locator(selector).first();
    if ((await btn.count()) > 0) {
      await btn.click().catch(() => {});
      await page.waitForTimeout(500);
    }
  }
}
```

### Phase B: Beat Planning

Based on discovery results, plan a **message-driven demo**, not a page tour. Build around the moments that sell the product story:

1. **Hero claim** — what promise should land first?
2. **Proof moment** — what screen proves that promise quickly?
3. **Workflow moment** — what product state shows the work actually happening?
4. **Outcome moment** — what result, visibility, or speedup does the user get?
5. **CTA moment** — what closes the story?

Most strong demos use **4–8 message moments** captured as **8–14 visual beats**. A single narration segment can justify multiple visual beats if the spoken idea is longer than one shot can carry.

The plan specifies what **screenshots or crops** to take, plus the metadata Remotion will need to animate those screenshots in a more directed way:

```typescript
interface MessageMoment {
  beatId: string;
  message: string;
  url: string;
  shots: {
    id: string;               // filename: "01-hero-establish", "02-proof-crop"
    shotArchetype: "establish" | "push-in" | "detail-crop" | "split-proof" | "result-state";
    action?: string;          // what to do before capturing: "scroll:600", "click:.tab-2", "hover:.card"
    description: string;
    eyebrow?: string;
    headline?: string;
    subheadline?: string;
    selector?: string;        // primary area the shot should focus on
    browserFrame?: boolean;   // set false for full-bleed crops or proof composites
  }[];
}

const tourPlan: MessageMoment[] = [
  {
    beatId: "hero-claim",
    message: "Show the core promise immediately",
    url: "https://example.com",
    shots: [
      {
        id: "01-hero-establish",
        shotArchetype: "establish",
        description: "Landing hero section",
        eyebrow: "Overview",
        headline: "Show the product promise first",
        subheadline: "Use the real hero state, not a blank loading shell",
        selector: "main h1",
        browserFrame: true,
      },
      {
        id: "02-hero-proof",
        shotArchetype: "detail-crop",
        action: "scroll:800",
        description: "Feature proof close-up",
        eyebrow: "Proof",
        headline: "Move from promise into evidence",
        subheadline: "Crop tighter if the page layout wastes space",
        selector: "section.features",
        browserFrame: false,
      },
    ],
  },
  {
    beatId: "workflow-moment",
    message: "Show the product in motion",
    url: "https://example.com/features",
    shots: [
      { id: "03-workflow-establish", shotArchetype: "push-in", description: "Workflow overview", browserFrame: true },
      { id: "04-workflow-result", shotArchetype: "result-state", action: "click:[role='tab']:nth-child(2)", description: "Resulting state after interaction", browserFrame: false },
    ],
  },
  // ... 4-8 message moments
];
```

### Phase C: Capture Screenshots

```typescript
interface CapturedShot {
  id: string;
  file: string;
  beatId: string;
  url: string;
  description: string;
  shotArchetype: "establish" | "push-in" | "detail-crop" | "split-proof" | "result-state";
  eyebrow?: string;
  headline?: string;
  subheadline?: string;
  browserFrame?: boolean;
}

const captured: CapturedShot[] = [];

async function captureScreenshot(
  page: Page,
  shot: MessageMoment["shots"][number],
  beatId: string,
) {
  const { id, description } = shot;
  const file = `${id}.png`;
  const filePath = join(SCREENSHOTS_DIR, file);

  // Verify page has visible content before capturing
  const hasContent = await page.evaluate(() => {
    const body = document.body;
    if (!body) return false;
    const rect = body.getBoundingClientRect();
    if (rect.height < 100) return false;
    // Check that the page isn't blank — at least one visible element with content
    const visible = document.querySelectorAll("h1, h2, h3, p, img, svg, canvas, video");
    return visible.length > 0;
  });

  if (!hasContent) {
    console.warn(`⚠ Page appears blank for ${id}, waiting 5s more...`);
    await page.waitForTimeout(5000);
  }

  await page.screenshot({ path: filePath, type: "png" });

  // Verify file size — blank pages produce very small PNGs (< 50KB)
  const { statSync } = await import("fs");
  const fileSize = statSync(filePath).size;
  if (fileSize < 50_000) {
    console.warn(`⚠ Screenshot ${id} is only ${(fileSize / 1024).toFixed(0)}KB — likely blank. Retrying after 5s...`);
    await page.waitForTimeout(5000);
    await page.screenshot({ path: filePath, type: "png" });
  }

  captured.push({
    id,
    file: `screenshots/${file}`,
    beatId,
    url: page.url().replace(/^https?:\/\//, "").replace(/\/$/, ""),
    description,
    shotArchetype: shot.shotArchetype,
    eyebrow: shot.eyebrow,
    headline: shot.headline,
    subheadline: shot.subheadline,
    browserFrame: shot.browserFrame,
  });
  console.log(`Captured: ${id} — ${description} (${(statSync(filePath).size / 1024).toFixed(0)}KB)`);
}

await dismissOverlays(page);

for (const moment of tourPlan) {
  // Use domcontentloaded + manual settle — networkidle can timeout on sites with
  // persistent connections (analytics, websockets, streaming). Fall back gracefully.
  await page.goto(moment.url, { waitUntil: "domcontentloaded", timeout: 30000 });
  // Wait for the page to have at least one heading or image visible
  await page.waitForSelector("h1, h2, img, svg, [class*='hero']", { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(2000); // let fonts, images, and animations settle

  for (const shot of moment.shots) {
    if (shot.action) {
      await executeAction(page, shot.action);
      await page.waitForTimeout(800);
    }
    await captureScreenshot(page, shot, moment.beatId);
  }
}

// Save capture plan for Remotion
writeFileSync(TOUR_PLAN_PATH, JSON.stringify(captured, null, 2));
console.log(`Tour plan saved with ${captured.length} screenshots`);

await context.close();
await browser.close();
```

---

## Action Executor

Helper to perform actions before each screenshot:

```typescript
async function executeAction(page: Page, action: string) {
  const [type, ...args] = action.split(":");
  const target = args.join(":");

  switch (type) {
    case "scroll":
      await page.evaluate((px) => window.scrollBy({ top: Number(px), behavior: "instant" }), target);
      await page.waitForTimeout(500);
      break;
    case "scrollTo":
      await page.evaluate((sel) => document.querySelector(sel)?.scrollIntoView({ block: "center" }), target);
      await page.waitForTimeout(500);
      break;
    case "click":
      await page.locator(target).first().click();
      await page.waitForTimeout(800);
      break;
    case "hover":
      await page.locator(target).first().hover();
      await page.waitForTimeout(500);
      break;
    case "type":
      const [selector, text] = target.split("|");
      await page.locator(selector).first().pressSequentially(text, { delay: 0 });
      await page.waitForTimeout(300);
      break;
  }
}
```

Scrolling uses `behavior: "instant"` not `"smooth"` — since we're taking screenshots, there's no one watching the scroll animation. Just jump to the position and capture.

---

## Screenshot Quality

- Use `type: "png"` (not jpeg) for crisp text rendering
- `deviceScaleFactor: 2` gives 3840×2160 screenshots that Remotion downscales to 1920×1080 — much sharper than 1x
- **Wait strategy:** Use `domcontentloaded` + `waitForSelector("h1, h2, img")` + `waitForTimeout(2000)`. Don't rely on `networkidle` alone — many sites have persistent connections (analytics, websockets) that prevent it from resolving.
- **Verify content before capturing:** Check that the page has visible headings, images, or content. Blank pages produce PNGs under 50KB — detect and retry.
- For pages with lazy-loaded content, scroll to trigger loading then scroll back before capturing
- **Always check the PNGs visually** before proceeding to the Remotion render. A blank screenshot wastes an entire render cycle.
- Do not plan highlight boxes or callout rectangles over the screenshot. Use stronger framing, captions, and shot choreography instead.
- Reject screenshots that are technically valid but compositionally weak: cropped focal content, poor spacing, confusing scroll position, or no clear subject.
- If a narration beat lasts more than 4–6 seconds, capture a second visual beat for that same message moment.

---

## Beat Structure by Site Type

### Public Marketing Sites

| # | Message moment | What to capture |
|---|-----------|----------------|
| 1 | Hero claim | Strong first impression, ideally above the fold |
| 2 | Proof moment | Tight crop or feature section that validates the claim |
| 3 | Workflow moment | A real product state, not just marketing copy |
| 4 | Outcome moment | Result, speed, visibility, automation, or collaboration payoff |
| 5 | CTA moment | Sign-up, conversion, or brand close |

### Local Apps

| # | Message moment | What to capture |
|---|-----------|----------------|
| 1 | Entry | The first meaningful in-product state |
| 2 | Core workflow | The main action a user takes |
| 3 | Proof | Detail crop of the feature doing the work |
| 4 | Result | The output, decision, or saved time |
| 5 | CTA/extension | Next action, automation, or expansion path |

---

## Output Format

The script outputs:
1. PNG files in `scripts/video/remotion/public/screenshots/` (e.g., `01-homepage-hero.png`, `02-homepage-features.png`)
2. A `tour-plan.json` at `scripts/video/` that Remotion reads:

```json
[
  {
    "id": "01-homepage-hero",
    "file": "screenshots/01-homepage-hero.png",
    "beatId": "hero-claim",
    "url": "example.com",
    "description": "Landing hero section",
    "shotArchetype": "establish",
    "eyebrow": "Overview",
    "headline": "Lead with the main promise",
    "subheadline": "Use captions and camera guidance, not a passive hold",
    "browserFrame": true
  },
  {
    "id": "02-homepage-features",
    "file": "screenshots/02-homepage-features.png",
    "beatId": "proof-moment",
    "url": "example.com",
    "description": "Feature grid",
    "shotArchetype": "detail-crop",
    "eyebrow": "Capabilities",
    "headline": "Shift attention into the feature area",
    "browserFrame": false
  }
]
```

The `tour-plan.json` does NOT include narration timestamps. Screenshot durations are derived from `narration-timing.json` (measured audio), not from estimates.
It should contain enough metadata for guided motion: caption copy, cursor cues, camera intent, and any source selectors that informed the shot.

---

## Timing in Remotion (synced to narration via narration-timing.json)

Since screenshots are static, all timing is controlled in Remotion and **must match the measured narration audio**:
- Each message moment's base timing comes from `narration-timing.json`: filter for `demo-*` segments and use `Math.ceil(segment.duration * fps)`
- The `narration-timing.json` file is generated in Phase 4 by running `ffprobe` on each individually-generated TTS segment — these are **measured** durations, not estimates
- **Do NOT use arbitrary durations** (e.g., "5 seconds per screenshot"). If the narrator talks about a feature for 8.12 seconds, that visual sequence must fill that exact 8.12-second window
- If one narration segment contains multiple visual beats, split that measured window across those beats intentionally
- Transitions between screenshots: usually 6–10 frames, with longer transitions reserved for major structural shifts
- Camera choreography should vary by shot archetype, not default to the same Ken Burns move every time
- Total demo section: 35–45 seconds across 4–8 message moments

---

## Anti-Patterns

- **Don't use `recordVideo`** — screen recordings look amateur. Screenshots + Remotion animation is superior.
- **Don't capture full-page screenshots** — viewport-only (1920×1080) matches the Remotion frame. Full-page screenshots create letterboxing issues.
- **Don't capture blank/loading pages** — verify content is visible before capturing. Check file size (< 50KB = likely blank). Retry with longer wait if needed.
- **Don't rely solely on `networkidle`** — many sites have persistent connections that prevent it from resolving. Use `domcontentloaded` + `waitForSelector` + settle time instead.
- **Don't use arbitrary or estimated screenshot durations** — derive each screenshot's display time from `narration-timing.json` (measured audio). If narration and visuals are out of sync, the video feels broken.
- **Don't put narration timestamps in tour-plan.json** — timestamps belong in `narration-timing.json`, which is generated from measured audio. The tour plan only contains screenshot metadata.
- **Don't capture more than 14 screenshots** — too many makes transitions feel rushed. 8–14 beats is ideal.
- **Don't capture fewer than 4 screenshots** — too few and the demo section feels static. Minimum 4 captures.
- **Don't skip discovery** — always run Phase A to understand the site before planning captures.
- **Don't skip PNG verification** — always open and visually check screenshots before rendering. One blank screenshot wastes the entire render.
- **Don't let one unchanged visual state linger for more than 4–6 seconds** unless the moment absolutely earns it.
- **Don't settle for generic hero-only tours** when the platform has stronger product states to show.

## Tips

- **Test screenshots first** — open the PNGs and verify they look clean before running the Remotion render
- **Check for cookie banners** — they ruin screenshots. Always dismiss overlays before capturing.
- **Multiple captures per message moment** — take extra beats when the spoken idea needs progression or proof
- **Name files with sequence numbers** — `01-`, `02-`, etc. so they sort correctly
- **Use optional browser framing intentionally** — keep the chrome when orientation helps, drop it when a tighter crop tells the story better
- Run: `bun scripts/video/capture-demo.ts`
