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

### Phase B: Tour Planning

Based on discovery results, plan a **3–5 page tour** with a narrative arc. Prefer states that feel like a guided product walkthrough, not passive top-of-page screenshots:

1. **Landing / Hero** — the first impression, headline, hero section
2. **Primary feature page** — the core value proposition
3. **Secondary feature or interactive demo** — depth, interactivity
4. **Social proof / Pricing** — testimonials, pricing table, logos
5. **(Optional) CTA / Sign-up** — final call to action

The plan specifies what **screenshots** to take per page, plus the metadata Remotion will need to animate those screenshots in a more directed way:

```typescript
interface TourStop {
  label: string;
  url: string;
  screenshots: {
    id: string;        // filename: "01-homepage-hero", "02-homepage-features"
    action?: string;   // what to do before capturing: "scroll:600", "click:.tab-2", "hover:.card"
    description: string;
    eyebrow?: string;
    headline?: string;
    subheadline?: string;
    selector?: string; // primary area the shot should focus on
    highlightSelectors?: { selector: string; label?: string }[];
  }[];
}

const tourPlan: TourStop[] = [
  {
    label: "Homepage",
    url: "https://example.com",
    screenshots: [
      {
        id: "01-homepage-hero",
        description: "Landing hero section",
        eyebrow: "Overview",
        headline: "Show the product promise first",
        subheadline: "Use the real hero state, not a blank loading shell",
        selector: "main h1",
        highlightSelectors: [{ selector: "main h1", label: "Core message" }],
      },
      {
        id: "02-homepage-features",
        action: "scroll:800",
        description: "Feature grid",
        selector: "section.features",
        highlightSelectors: [{ selector: "section.features [data-feature-card], section.features article", label: "Feature area" }],
      },
    ],
  },
  {
    label: "Features",
    url: "https://example.com/features",
    screenshots: [
      { id: "03-features-overview", description: "Features overview" },
      { id: "04-features-detail", action: "click:[role='tab']:nth-child(2)", description: "Feature detail tab" },
    ],
  },
  // ... 3-5 stops
];
```

### Phase C: Capture Screenshots

```typescript
interface CapturedShot {
  id: string;
  file: string;
  label: string;
  url: string;
  description: string;
  eyebrow?: string;
  headline?: string;
  subheadline?: string;
  emphasis?: {
    x: number;
    y: number;
    width: number;
    height: number;
    label?: string;
  }[];
}

const captured: CapturedShot[] = [];

async function getNormalizedRect(page: Page, selector: string) {
  return page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    const width = window.innerWidth;
    const height = window.innerHeight;
    if (rect.width <= 0 || rect.height <= 0 || width <= 0 || height <= 0) return null;
    return {
      x: Number(((rect.left / width) * 100).toFixed(2)),
      y: Number(((rect.top / height) * 100).toFixed(2)),
      width: Number(((rect.width / width) * 100).toFixed(2)),
      height: Number(((rect.height / height) * 100).toFixed(2)),
    };
  }, selector);
}

async function captureScreenshot(
  page: Page,
  shot: TourStop["screenshots"][number],
  label: string,
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

  const emphasis = [];
  for (const target of shot.highlightSelectors ?? []) {
    const rect = await getNormalizedRect(page, target.selector);
    if (rect) {
      emphasis.push({
        ...rect,
        label: target.label,
      });
    }
  }

  captured.push({
    id,
    file: `screenshots/${file}`,
    label,
    url: page.url().replace(/^https?:\/\//, "").replace(/\/$/, ""),
    description,
    eyebrow: shot.eyebrow,
    headline: shot.headline,
    subheadline: shot.subheadline,
    emphasis,
  });
  console.log(`Captured: ${id} — ${description} (${(statSync(filePath).size / 1024).toFixed(0)}KB)`);
}

await dismissOverlays(page);

for (const stop of tourPlan) {
  // Use domcontentloaded + manual settle — networkidle can timeout on sites with
  // persistent connections (analytics, websockets, streaming). Fall back gracefully.
  await page.goto(stop.url, { waitUntil: "domcontentloaded", timeout: 30000 });
  // Wait for the page to have at least one heading or image visible
  await page.waitForSelector("h1, h2, img, svg, [class*='hero']", { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(2000); // let fonts, images, and animations settle

  for (const shot of stop.screenshots) {
    if (shot.action) {
      await executeAction(page, shot.action);
      await page.waitForTimeout(800);
    }
    await captureScreenshot(page, shot, stop.label);
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
- If a highlight or callout will be shown later, prefer measuring the element during capture instead of manually inventing box coordinates after the screenshot exists.
- Reject screenshots that are technically valid but compositionally weak: cropped focal content, poor spacing, confusing scroll position, or no clear subject.

---

## Tour Structure by Site Type

### Public Marketing Sites

| # | Screenshot | What to capture |
|---|-----------|----------------|
| 1 | Homepage hero | Full viewport after page load |
| 2 | Homepage features | Scroll to feature section |
| 3 | Product page | Navigate to main product |
| 4 | Product detail | Click a tab or scroll to details |
| 5 | Pricing table | Navigate to pricing |
| 6 | (Optional) Pricing toggled | Click annual/monthly toggle |

### Local Apps

| # | Screenshot | What to capture |
|---|-----------|----------------|
| 1 | Landing/Login | Show entry point |
| 2 | Dashboard | After login, main view |
| 3 | Core feature | Navigate to main feature |
| 4 | Feature in action | After an interaction |
| 5 | Results/Output | The outcome |

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
    "label": "Homepage",
    "url": "example.com",
    "description": "Landing hero section",
    "eyebrow": "Overview",
    "headline": "Lead with the main promise",
    "subheadline": "Use captions and focus guidance, not a passive hold",
    "emphasis": [
      {
        "x": 12,
        "y": 16,
        "width": 44,
        "height": 18,
        "label": "Core message"
      }
    ]
  },
  {
    "id": "02-homepage-features",
    "file": "screenshots/02-homepage-features.png",
    "label": "Features",
    "url": "example.com",
    "description": "Feature grid",
    "eyebrow": "Capabilities",
    "headline": "Shift attention into the feature area"
  }
]
```

The `tour-plan.json` does NOT include narration timestamps. Screenshot durations are derived from `narration-timing.json` (measured audio), not from estimates.
It should contain enough metadata for guided motion: caption copy, selector-derived emphasis boxes, and any source selectors that informed the shot.

---

## Timing in Remotion (synced to narration via narration-timing.json)

Since screenshots are static, all timing is controlled in Remotion and **must match the measured narration audio**:
- Each screenshot's `durationInFrames` is derived from `narration-timing.json`: filter for `demo-*` segments and use `Math.ceil(segment.duration * fps)`
- The `narration-timing.json` file is generated in Phase 4 by running `ffprobe` on each individually-generated TTS segment — these are **measured** durations, not estimates
- **Do NOT use arbitrary durations** (e.g., "5 seconds per screenshot"). If the narrator talks about a feature for 8.12 seconds, that screenshot must display for exactly 8.12 seconds
- Transitions between screenshots: 0.5–1s crossfade, slide, or scale (these overlap, so account for them in timing)
- Ken Burns drift: applied per-screenshot by Remotion
- Total demo section: 35–45 seconds across 5–8 screenshots

---

## Anti-Patterns

- **Don't use `recordVideo`** — screen recordings look amateur. Screenshots + Remotion animation is superior.
- **Don't capture full-page screenshots** — viewport-only (1920×1080) matches the Remotion frame. Full-page screenshots create letterboxing issues.
- **Don't capture blank/loading pages** — verify content is visible before capturing. Check file size (< 50KB = likely blank). Retry with longer wait if needed.
- **Don't rely solely on `networkidle`** — many sites have persistent connections that prevent it from resolving. Use `domcontentloaded` + `waitForSelector` + settle time instead.
- **Don't use arbitrary or estimated screenshot durations** — derive each screenshot's display time from `narration-timing.json` (measured audio). If narration and visuals are out of sync, the video feels broken.
- **Don't put narration timestamps in tour-plan.json** — timestamps belong in `narration-timing.json`, which is generated from measured audio. The tour plan only contains screenshot metadata.
- **Don't capture more than 8 screenshots** — too many makes transitions feel rushed. 5–8 is ideal.
- **Don't capture fewer than 4 screenshots** — too few and the demo section feels static. Minimum 4 captures.
- **Don't skip discovery** — always run Phase A to understand the site before planning captures.
- **Don't skip PNG verification** — always open and visually check screenshots before rendering. One blank screenshot wastes the entire render.
- **Don't guess overlay coordinates by eye** if a selector can be measured at capture time.
- **Don't settle for generic hero-only tours** when the platform has stronger product states to show.

## Tips

- **Test screenshots first** — open the PNGs and verify they look clean before running the Remotion render
- **Check for cookie banners** — they ruin screenshots. Always dismiss overlays before capturing.
- **Multiple captures per page** — take 1–2 screenshots per page at different scroll positions or tab states for variety
- **Name files with sequence numbers** — `01-`, `02-`, etc. so they sort correctly
- **Measure targets while the DOM is present** — once the shot becomes a PNG, alignment can only rely on whatever metadata you saved during capture
- Run: `bun scripts/video/capture-demo.ts`
