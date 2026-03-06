# Playwright Recording Patterns

Reference for building the `record-demo.ts` script that records a browser demo for the explainer video.

## Setup

```typescript
import { chromium, type Page, type Locator } from "playwright";
import { mkdir } from "fs/promises";
import { join } from "path";

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";
const RECORDINGS_DIR = join(import.meta.dir, "../../output");
```

## Recording Context

```typescript
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
  recordVideo: { dir: RECORDINGS_DIR, size: { width: 1280, height: 720 } },
  acceptDownloads: true,
});
const page = await context.newPage();
```

**Important:** The video gets a random filename. After recording, rename it:

```typescript
await context.close(); // Finalize video
await browser.close();

const { readdirSync, renameSync, unlinkSync, existsSync } = await import("fs");
const dest = join(RECORDINGS_DIR, "demo.webm");
const files = readdirSync(RECORDINGS_DIR).filter(
  (f: string) => f.endsWith(".webm") && f !== "demo.webm"
);
if (files.length > 0) {
  const latest = files.sort().pop()!;
  const src = join(RECORDINGS_DIR, latest);
  if (existsSync(dest)) unlinkSync(dest);
  renameSync(src, dest);
}
```

## Typing Patterns

### Visible typing (for text fields)
```typescript
async function typeField(input: Locator, text: string) {
  await input.click();
  await input.pressSequentially(text, { delay: 50 });
}
```

### Date fields (use fill, not typing)
```typescript
await dateInput.fill("1965-05-15");
```

Date pickers behave inconsistently with `pressSequentially`. Always use `.fill()`.

## Timing and Pacing

### Pause between actions
```typescript
await page.waitForTimeout(400);  // Brief pause between form fields
await page.waitForTimeout(800);  // Pause at domain/section transitions
await page.waitForTimeout(3000); // Hold for slide overlay windows
```

### Hold periods for slide overlays
The recording needs "idle" periods where slide overlays will be composited on top. During these windows, the demo should show something relevant but not require the viewer's full attention.

```typescript
// 0-10s: Hold on landing page (intro + title slides overlay)
await page.goto(BASE_URL, { waitUntil: "networkidle" });
await page.waitForTimeout(10000);

// 22-26s: Hold (stat card overlays this region)
await page.waitForTimeout(4000);
```

### Smooth scrolling
```typescript
await page.evaluate(() =>
  window.scrollBy({ top: 300, behavior: "smooth" })
);
await page.waitForTimeout(2500);
```

## Flow Structure

```typescript
async function main() {
  // 1. Load page + hold for intro slides
  await page.goto(BASE_URL, { waitUntil: "networkidle" });
  await page.waitForTimeout(10000);

  // 2. Fill form fields (visible demo)
  await fillForm(page);

  // 3. Hold for stat slide
  await page.waitForTimeout(4000);

  // 4. Continue interaction
  await completeFlow(page);

  // 5. Hold for outro slides
  await page.waitForTimeout(10000);
}
```

## Selector Strategies

Prefer stable selectors:
- `page.locator('#element-id')` — best
- `page.locator('button:has-text("Submit")')` — good for buttons
- `page.locator('[data-testid="field"]')` — good if available
- `page.locator('div').filter({ hasText: /^Section Title/ })` — for containers

## Tips

- **Always use headless mode** for recording — headed mode can have rendering artifacts
- **1280x720 is standard** — matches the slide dimensions and FFmpeg assembly
- **Test timing manually first** — run the script and check the webm before full assembly
- **Keep the flow natural** — real users don't fill forms at machine speed
- **acceptDownloads: true** — if the demo involves file downloads
