# Professional Video Design Principles

Concrete rules and Remotion code patterns for producing professional-grade explainer videos. Every scene you build must follow these principles. This document is the quality standard — if your scene doesn't meet these criteria, it's not ready.

**CRITICAL:** Read this entire document before writing any scene component. These are not suggestions — they are requirements.

---

## 1. The 4-Layer Frame Model

Every frame in a professional video has visual depth. A flat gradient with text on top is a PowerPoint slide, not a video frame. Build every non-demo scene with 4 distinct layers:

```
Layer 4 (top):    Overlay — grain, vignette, light leaks
Layer 3:          Content — text, device frames, cards
Layer 2:          Mid-ground — decorative shapes, blurred orbs, accent elements
Layer 1 (bottom): Background — animated gradient mesh, aurora, geometric pattern
```

### Layer 1: Animated Background

The background must have **constant visible motion**. A static gradient is dead. Animate glow positions, rotate gradient angles, drift radial accents. The viewer should always sense movement even when focused on content.

```tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";
import { branding } from "../lib/branding";

export const AnimatedBackground: React.FC = () => {
  const frame = useCurrentFrame();
  const { colors } = branding;

  // Glow positions drift continuously — never static
  const glow1X = interpolate(frame, [0, 600], [20, 50], { extrapolateRight: "extend" });
  const glow1Y = interpolate(frame, [0, 800], [30, 60], { extrapolateRight: "extend" });
  const glow2X = interpolate(frame, [0, 500], [70, 40], { extrapolateRight: "extend" });
  const glow2Y = interpolate(frame, [0, 700], [60, 25], { extrapolateRight: "extend" });
  const gradientAngle = interpolate(frame, [0, 900], [145, 165], { extrapolateRight: "extend" });

  return (
    <AbsoluteFill>
      {/* Base gradient — angle shifts slowly */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(${gradientAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 100%)`,
        }}
      />
      {/* Primary accent glow — drifts across frame */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse 600px 400px at ${glow1X}% ${glow1Y}%, ${colors.accent} 0%, transparent 70%)`,
          opacity: 0.4,
        }}
      />
      {/* Secondary accent glow — moves opposite direction */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse 500px 350px at ${glow2X}% ${glow2Y}%, ${colors.accentSecondary} 0%, transparent 70%)`,
          opacity: 0.25,
        }}
      />
    </AbsoluteFill>
  );
};
```

### Layer 2: Decorative Mid-Ground

**Every scene needs AT LEAST 2 distinct Layer 2 elements.** A single subtle glow orb is not enough — combine multiple element types for visual richness. Layer 2 is what separates professional videos from PowerPoint slides.

**Element types to combine (use at least 2 per scene):**

| Element | What it adds | Example |
|---------|-------------|---------|
| **Glow orbs** (300-600px) | Ambient color atmosphere | `radial-gradient(circle, ${accent}40 0%, transparent 70%)` with `blur(60-80px)` |
| **Geometric shapes** | Structure, modernity | Rotating squares with `border: 1.5px solid ${accent}33`, small circles as dots |
| **Floating particles** | Life, micro-motion | 6-8 tiny (2-4px) circles drifting slowly upward |
| **Conic-gradient rings** | Sophistication, depth | Concentric circles with `conic-gradient` that rotates |
| **Accent lines** | Editorial polish | SVG paths animated with `evolvePath` (straight lines, rectangles, L-shapes) |
| **Grid patterns** | Tech feel | SVG grid lines at very low opacity (0.03-0.05) |

**CRITICAL minimum:** If your scene has only 1 type of Layer 2 element (e.g., just orbs), add another type. The richest scenes combine 3+ element types.

```tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";
import { branding } from "../lib/branding";

interface FloatingOrb {
  x: number;
  y: number;
  size: number;
  speedX: number;
  speedY: number;
  opacity: number;
  color: string;
}

export const FloatingElements: React.FC<{ orbs: FloatingOrb[] }> = ({ orbs }) => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      {orbs.map((orb, i) => {
        const x = orb.x + interpolate(frame, [0, 600], [0, orb.speedX], { extrapolateRight: "extend" });
        const y = orb.y + interpolate(frame, [0, 600], [0, orb.speedY], { extrapolateRight: "extend" });

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: `${x}%`,
              top: `${y}%`,
              width: orb.size,
              height: orb.size,
              borderRadius: "50%",
              background: orb.color,
              filter: `blur(${orb.size * 0.4}px)`,
              opacity: orb.opacity,
              transform: "translate(-50%, -50%)",
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};
```

Usage — define orbs per scene with branding colors. Use large sizes (300-600px) for dramatic glow, not tiny circles:

```tsx
<FloatingElements
  orbs={[
    { x: 15, y: 25, size: 400, speedX: 8, speedY: -5, opacity: 0.25, color: colors.accent },
    { x: 80, y: 70, size: 300, speedX: -6, speedY: 4, opacity: 0.2, color: colors.accentSecondary },
    { x: 50, y: 10, size: 200, speedX: 3, speedY: 7, opacity: 0.15, color: colors.accent },
  ]}
/>
```

### Layer 3: Content

The actual text, images, device frames — positioned using the scene's layout archetype (see Section 3). Content sits on top of the mid-ground elements.

**Content must NEVER be bare text on a gradient.** Use these containers:

- **Glassmorphism cards** — `background: rgba(255,255,255,0.03-0.06)`, `backdropFilter: blur(20-40px)`, `border: 1px solid rgba(255,255,255,0.06-0.1)`, `borderRadius: 14-20px`
- **Gradient text fills** — `WebkitBackgroundClip: "text"` with accent gradient for headlines
- **Accent line accents** — animated SVG lines under headlines or beside section labels
- **Icon containers** — icons inside tinted rounded squares (`background: ${accent}15`, `borderRadius: 12px`)
- **Glow on accent text** — `textShadow: 0 0 30px ${accent}44, 0 0 60px ${accent}22` for CTAs and stats

**Entrance animations must feel weighty:** use blur-in (`filter: blur(12px)` → `blur(0px)`) or scale+translate (scale from 0.8-0.95 + translateY from 20-40px) — not just simple opacity fade.

### Layer 4: Overlay

Grain texture and optional light leaks add film-quality polish. Always include grain. Use light leaks on 2-3 scenes for extra depth.

```tsx
import { AbsoluteFill, useCurrentFrame } from "remotion";
import { LightLeak } from "@remotion/light-leaks";

export const FilmOverlay: React.FC<{ showLightLeak?: boolean; lightLeakSeed?: number }> = ({
  showLightLeak = false,
  lightLeakSeed = 0,
}) => {
  const frame = useCurrentFrame();
  const grainSeed = Math.floor(frame / 2);

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {/* Grain texture — changes every 2 frames for film feel */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          opacity: 0.035,
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' seed='${grainSeed}' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")`,
          backgroundSize: "200px 200px",
        }}
      />
      {/* Vignette — subtle darkening at edges */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse 75% 70% at 50% 50%, transparent 0%, rgba(0,0,0,0.3) 100%)",
        }}
      />
      {/* Light leak — optional, for 2-3 key scenes */}
      {showLightLeak && <LightLeak seed={lightLeakSeed} />}
    </AbsoluteFill>
  );
};
```

### Composing All 4 Layers in a Scene

```tsx
export const TitleScene: React.FC = () => {
  return (
    <AbsoluteFill>
      {/* Layer 1 */}
      <AnimatedBackground />
      {/* Layer 2 */}
      <FloatingElements orbs={[...]} />
      {/* Layer 3 — Content */}
      <AbsoluteFill style={{ justifyContent: "center", padding: "0 120px" }}>
        {/* Headlines, text, accent lines, etc. */}
      </AbsoluteFill>
      {/* Layer 4 */}
      <FilmOverlay showLightLeak />
    </AbsoluteFill>
  );
};
```

---

## 2. Animation Principles for Video

Professional motion follows principles from animation craft. Apply these to every animated element in Remotion:

### Anticipation

Before a big move, pull back slightly. Before an element scales up, scale it down 2-3% first. This makes the motion feel intentional.

```tsx
const anticipation = spring({ frame, fps, delay, config: { damping: 8, stiffness: 80 } });
const scale = interpolate(anticipation, [0, 0.3, 1], [0, 0.95, 1]);
```

### Follow-Through and Overshoot

Elements that stop abruptly feel robotic. Use springs with low damping so elements overshoot their target and settle back. This adds life.

```tsx
// Low damping = visible overshoot, element bounces past 1.0 then settles
const scale = spring({
  frame, fps, delay,
  config: { damping: 8, mass: 0.8, stiffness: 120 },
});
```

### Staging

One thing at a time. Never animate 5 elements simultaneously — the eye can't track it. Stagger entrances so each element has its moment. Clear the frame before introducing new content.

```tsx
// Stagger delay of 6-10 frames between elements
const headlineDelay = 0;
const subtitleDelay = 12;
const accentLineDelay = 20;
const ctaDelay = 30;
```

### Secondary Action

While the primary element animates (headline entering), a secondary element reacts simultaneously (accent line drawing underneath, background glow intensifying, decorative shape rotating). This adds richness without competing for attention.

```tsx
// Primary: headline fades up
const headlineProgress = spring({ frame, fps, delay: 0, config: { damping: 200 } });
// Secondary: accent line draws as headline appears
const lineWidth = interpolate(headlineProgress, [0.3, 1], [0, 200], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
```

### Timing Classes

Use consistent timing classes across the video. Mixing random durations feels chaotic.

| Class | Frames (30fps) | Use for |
|-------|----------------|---------|
| Quick | 6-10 | Small accent reveals, icon pops |
| Standard | 12-18 | Text entrances, card reveals |
| Deliberate | 20-30 | Hero headlines, device frame entrance |
| Luxurious | 35-50 | Logo reveals, scene-wide transitions |

### Easing for Different Moods

- **Snappy/energetic**: `{ damping: 12, stiffness: 200 }` — fast attack, quick settle
- **Professional/confident**: `{ damping: 200 }` — smooth, no overshoot
- **Luxurious/cinematic**: `{ damping: 15, mass: 1.2, stiffness: 60 }` — slow, weighty, overshoots
- **Playful/bouncy**: `{ damping: 6, mass: 0.6, stiffness: 150 }` — fast, visible bounce

---

## 3. Scene Layout Vocabulary

Every scene must use a distinct layout archetype. **No two consecutive scenes may share the same archetype.** This is what separates professional sequences from PowerPoint — visual variety creates rhythm.

### Centered-Stack

Content stacked vertically at frame center. Reserve for intro and outro only — overuse creates monotony.

```tsx
<AbsoluteFill style={{ justifyContent: "center", alignItems: "center", textAlign: "center", padding: "0 160px" }}>
  <Logo height={48} delay={0} />
  <div style={{ marginTop: 32 }}>
    {/* Headline */}
  </div>
  <div style={{ marginTop: 16 }}>
    {/* Subtitle */}
  </div>
</AbsoluteFill>
```

### Asymmetric-Left

Content left-aligned at ~60% width. The right side has decorative elements, accent shapes, or breathing room. Strong for headlines with personality.

```tsx
<AbsoluteFill style={{ padding: "0 100px", justifyContent: "center" }}>
  <div style={{ maxWidth: "60%" }}>
    {/* Headline, subtitle, accent line */}
  </div>
  {/* Right side: floating decorative elements, gradient orb, accent shape */}
</AbsoluteFill>
```

### Asymmetric-Right

Mirror of asymmetric-left — visual/decorative element on the left, text content on the right. Good for creating visual contrast with the previous scene.

### Split-Screen

Frame divided into two panels (50/50 or 60/40). Each side has distinct content — e.g., "before" on left, "after" on right. Or icon/illustration on one side, text on the other.

```tsx
<AbsoluteFill style={{ flexDirection: "row" }}>
  <div style={{ flex: "0 0 50%", display: "flex", alignItems: "center", justifyContent: "center" }}>
    {/* Left panel content */}
  </div>
  <div style={{ flex: "0 0 50%", display: "flex", alignItems: "center", justifyContent: "center" }}>
    {/* Right panel content */}
  </div>
</AbsoluteFill>
```

### Card-Contained

Content inside a glassmorphism or bordered card container. Breaks the "text floating on gradient" look. The card itself can animate in.

```tsx
<AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
  <div
    style={{
      background: "rgba(255,255,255,0.06)",
      backdropFilter: "blur(40px)",
      WebkitBackdropFilter: "blur(40px)",
      borderRadius: 20,
      border: "1px solid rgba(255,255,255,0.1)",
      padding: "48px 64px",
      maxWidth: 800,
      transform: `scale(${cardScale})`, // spring entrance
    }}
  >
    {/* Content inside card */}
  </div>
</AbsoluteFill>
```

### Full-Bleed Typography

One large headline filling most of the frame. Maximum impact, minimal elements. The typography IS the design.

```tsx
<AbsoluteFill style={{ justifyContent: "center", padding: "0 80px" }}>
  <div style={{ fontSize: 96, fontWeight: 700, lineHeight: 1.05 }}>
    {/* Large headline text — animated with blur-in or stagger */}
  </div>
</AbsoluteFill>
```

### Diagonal/Angled

Elements arranged on a diagonal axis. An accent stripe, angled divider, or rotated grid creates energy and forward momentum.

---

## 4. Background Techniques

Choose a technique that matches the creative direction. Implement at least one of these — never use a plain static gradient.

### Animated Gradient Mesh

Multiple overlapping radial gradients with drifting positions. Creates organic, living color fields.

```tsx
const frame = useCurrentFrame();
const { colors } = branding;

const g1x = interpolate(frame, [0, 400], [25, 45], { extrapolateRight: "extend" });
const g1y = interpolate(frame, [0, 500], [20, 50], { extrapolateRight: "extend" });
const g2x = interpolate(frame, [0, 350], [75, 55], { extrapolateRight: "extend" });
const g2y = interpolate(frame, [0, 450], [70, 35], { extrapolateRight: "extend" });
const g3x = interpolate(frame, [0, 550], [50, 30], { extrapolateRight: "extend" });
const g3y = interpolate(frame, [0, 600], [80, 50], { extrapolateRight: "extend" });

// Stack radial gradients on separate layers for blending
<div style={{ position: "absolute", inset: 0, background: `radial-gradient(ellipse 700px 500px at ${g1x}% ${g1y}%, ${colors.accent} 0%, transparent 70%)`, opacity: 0.35 }} />
<div style={{ position: "absolute", inset: 0, background: `radial-gradient(ellipse 600px 400px at ${g2x}% ${g2y}%, ${colors.accentSecondary} 0%, transparent 70%)`, opacity: 0.25 }} />
<div style={{ position: "absolute", inset: 0, background: `radial-gradient(ellipse 500px 500px at ${g3x}% ${g3y}%, ${colors.bgSecondary} 0%, transparent 60%)`, opacity: 0.4 }} />
```

### Floating Gradient Orbs

Large blurred circles drifting slowly at different depths. Creates a bokeh-like depth effect.

Use the `FloatingElements` component from Section 1 with 3-5 orbs per scene. Vary sizes (60px-180px), speeds, and opacity (0.05-0.2).

### Geometric Grid Pattern

Subtle grid lines or dot grid with animated accent at intersections. Matches technical/dev-tool aesthetics.

```tsx
// Render as SVG with animated opacity on selected grid nodes
<svg width={1920} height={1080} style={{ position: "absolute", inset: 0, opacity: 0.06 }}>
  {Array.from({ length: 20 }).map((_, col) =>
    Array.from({ length: 12 }).map((_, row) => (
      <circle
        key={`${col}-${row}`}
        cx={col * 100 + 50}
        cy={row * 100 + 40}
        r={1.5}
        fill={colors.textSecondary}
      />
    ))
  )}
</svg>
```

### Aurora / Wave

Layered blurred shapes with slow rotation. Ethereal, premium feel.

```tsx
const rotation = interpolate(frame, [0, 900], [0, 15], { extrapolateRight: "extend" });

<div
  style={{
    position: "absolute",
    top: "-20%",
    left: "-10%",
    width: "120%",
    height: "80%",
    background: `linear-gradient(${90 + rotation}deg, ${colors.accent}33 0%, transparent 40%, ${colors.accentSecondary}22 70%, transparent 100%)`,
    filter: "blur(80px)",
    transform: `rotate(${rotation * 0.5}deg)`,
  }}
/>
```

### Parallax Layered

Multiple layers moving at different speeds. Foreground elements move faster than background. Creates perceived depth.

```tsx
const slowDrift = interpolate(frame, [0, 600], [0, 15], { extrapolateRight: "extend" });
const mediumDrift = interpolate(frame, [0, 600], [0, 30], { extrapolateRight: "extend" });
const fastDrift = interpolate(frame, [0, 600], [0, 50], { extrapolateRight: "extend" });

// Apply different translateX to each layer
// Layer 1 (back): transform: translateX(${slowDrift}px)
// Layer 2 (mid): transform: translateX(${mediumDrift}px)
// Layer 3 (front): transform: translateX(${fastDrift}px)
```

---

## 5. Typography in Motion

Text animation is the most visible quality signal. Basic fadeUp on everything looks amateur. Vary techniques across scenes.

### Blur-In Reveal

Text starts blurred and invisible, then sharpens into focus. Premium, cinematic feel.

```tsx
const progress = spring({ frame, fps, delay, config: { damping: 200 } });
const blur = interpolate(progress, [0, 1], [20, 0]);
const opacity = interpolate(progress, [0, 0.5, 1], [0, 0.8, 1]);

<div style={{ fontSize, fontWeight, color: textColor, opacity, filter: `blur(${blur}px)` }}>
  {text}
</div>
```

### Masked Reveal

Text revealed by an animated clip-path sweeping left to right. Clean, editorial feel.

```tsx
const progress = spring({ frame, fps, delay, config: { damping: 200 } });
const clipX = interpolate(progress, [0, 1], [0, 100]);

<div style={{ fontSize, fontWeight, color: textColor, clipPath: `inset(0 ${100 - clipX}% 0 0)` }}>
  {text}
</div>
```

### Letter-by-Letter Stagger

Each character enters individually with slight rotation and offset. Kinetic, energetic feel.

```tsx
const chars = text.split("");

<div style={{ fontSize, fontWeight, color: textColor, display: "flex" }}>
  {chars.map((char, i) => {
    const charDelay = delay + i * 2;
    const p = spring({ frame, fps, delay: charDelay, config: { damping: 12, stiffness: 200 } });
    const y = interpolate(p, [0, 1], [30, 0]);
    const rotate = interpolate(p, [0, 1], [8, 0]);

    return (
      <span key={i} style={{ display: "inline-block", opacity: p, transform: `translateY(${y}px) rotate(${rotate}deg)` }}>
        {char === " " ? "\u00A0" : char}
      </span>
    );
  })}
</div>
```

### Gradient Shimmer Text

Animated gradient that sweeps across text. Attention-grabbing for hero headlines.

```tsx
const shimmerX = interpolate(frame, [delay, delay + 40], [-100, 200], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

<div
  style={{
    fontSize,
    fontWeight,
    background: `linear-gradient(90deg, ${colors.textPrimary} 0%, ${colors.accent} 45%, ${colors.textPrimary} 55%, ${colors.textPrimary} 100%)`,
    backgroundSize: "200% 100%",
    backgroundPosition: `${shimmerX}% 0`,
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
    backgroundClip: "text",
  }}
>
  {text}
</div>
```

### Scale-Bounce Entrance

Element scales in with elastic overshoot. Playful, confident energy.

```tsx
const scale = spring({ frame, fps, delay, config: { damping: 8, mass: 0.8, stiffness: 120 } });
const opacity = interpolate(scale, [0, 0.5], [0, 1], { extrapolateRight: "clamp" });

<div style={{ fontSize, fontWeight, color: textColor, opacity, transform: `scale(${scale})` }}>
  {text}
</div>
```

### Split-Line Entrance

Words enter from opposite sides of the frame and meet in the middle.

```tsx
const words = text.split(" ");
const midpoint = Math.ceil(words.length / 2);
const leftWords = words.slice(0, midpoint).join(" ");
const rightWords = words.slice(midpoint).join(" ");

const progress = spring({ frame, fps, delay, config: { damping: 200 } });
const leftX = interpolate(progress, [0, 1], [-60, 0]);
const rightX = interpolate(progress, [0, 1], [60, 0]);

<div style={{ fontSize, fontWeight, color: textColor }}>
  <span style={{ display: "inline-block", opacity: progress, transform: `translateX(${leftX}px)` }}>
    {leftWords}{" "}
  </span>
  <span style={{ display: "inline-block", opacity: progress, transform: `translateX(${rightX}px)` }}>
    {rightWords}
  </span>
</div>
```

### Readability Rules

- **Minimum on-screen time**: text must be visible for at least 2 seconds (60 frames at 30fps) before transitioning out
- **Minimum body size**: 32px for body text, 64px+ for headlines at 1920x1080
- **Contrast**: text over backgrounds must have sufficient contrast — use semi-transparent dark/light underlays if needed
- **Safe zone**: keep all text within 90% of the frame (96px margin on each side at 1920x1080)

---

## 6. Demo Scene Enhancement

The demo scene is 40-60% of the video runtime. Professional SaaS videos use **high-resolution screenshots** animated with motion graphics — NOT live screen recordings. Playwright captures pixel-perfect screenshots of each key page/feature, then Remotion handles all animation: transitions between screenshots, shot-specific camera moves, captions, and caption choreography.

**Why screenshots, not screen recordings:** Playwright's `recordVideo` produces jittery scrolling, visible loading states, and bot-like movement. Screenshots are pixel-perfect, and Remotion's animation is buttery smooth.

The architecture:
1. **Beat-driven screenshot sequence** — shots are planned around claims, proof, workflow, and outcomes, not just page coverage (REQUIRED)
2. **Narration-synced timing** — each `demo-*` timing window is derived from **measured audio** in `narration-timing.json`, NOT arbitrary values or estimates (REQUIRED)
3. **Scene Captions** — captions explain why the moment matters, not just what page is visible (REQUIRED)
4. **Optional browser framing** — URL bars and browser chrome are tools, not mandatory wrappers (OPTIONAL)
5. **Shot-specific camera choreography** — use different motion patterns for `establish`, `push-in`, `detail-crop`, `split-proof`, and `result-state` (REQUIRED)
6. **Structured interaction beats** — clicks, hovers, section jumps, page changes, and caption variants should come from ordered beat metadata, not ad-hoc animation guesses (REQUIRED when the demo is interactive)
7. **Behavior diversity across the sequence** — some beats should stay quiet, some should scroll, some should transition states, and only some should use a visible pointer (REQUIRED)

### Screenshot timing: synced to measured narration audio (CRITICAL)

The most common failure in AI-generated videos is **audio-visual desync** — the narrator talks about pricing while the homepage is still showing. This happens when screenshot durations are based on **estimated timestamps** instead of measured audio durations.

**The fix:** Narration is generated per-section (one TTS file per scene/message beat). Each segment's duration is measured with `ffprobe` and saved to `narration-timing.json`. In the DemoScene, compute the available timing window from the measured `demo-*` segments.

This approach guarantees sync because the duration of each scene is the **actual** length of its narration audio — not an estimate written before the TTS was generated. If a single narration segment needs multiple visual beats, subdivide that measured window intentionally instead of letting one shot freeze in place.

**Do NOT** use a fixed duration per screenshot. Do NOT use estimated timestamps. If the narrator's measured audio for a proof segment is 8.12 seconds, the visual sequence for that segment must fill exactly 8.12 seconds, whether that is one shot or three.

### Screenshot Carousel (REQUIRED — primary technique)

The DemoScene is a `TransitionSeries` or `Series` that sequences product screenshots inside a DeviceFrame or full-bleed crop. Each message beat's duration is derived from narration timing, with shot-specific movement and fast transitions between beats. If the plan includes interaction beats, the carousel should also react to `scrollReveal`, `pageChange`, and `transitionMode` metadata rather than treating every shot as passive drift.

```tsx
import { AbsoluteFill, Img, staticFile, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { TransitionSeries, springTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";

interface DemoShot {
  file: string;
  label: string;
  url: string;
  durationInFrames: number;
  shotArchetype: "establish" | "push-in" | "detail-crop" | "split-proof" | "result-state";
}

const ScreenshotSlide: React.FC<{ shot: DemoShot }> = ({ shot }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const motion = {
    establish: { startScale: 1.0, endScale: 1.03, startX: 0, endX: -6 },
    "push-in": { startScale: 1.01, endScale: 1.08, startX: 8, endX: -18 },
    "detail-crop": { startScale: 1.08, endScale: 1.12, startX: 0, endX: -10 },
    "split-proof": { startScale: 1.02, endScale: 1.05, startX: -4, endX: 6 },
    "result-state": { startScale: 1.04, endScale: 1.06, startX: 0, endX: 0 },
  }[shot.shotArchetype];
  const scale = interpolate(frame, [0, durationInFrames], [motion.startScale, motion.endScale], { extrapolateRight: "clamp" });
  const x = interpolate(frame, [0, durationInFrames], [motion.startX, motion.endX], { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ overflow: "hidden" }}>
      <Img
        src={staticFile(shot.file)}
        style={{
          width: "100%", height: "100%", objectFit: "cover",
          transform: `scale(${scale}) translateX(${x}px)`,
          transformOrigin: "center center",
        }}
      />
    </AbsoluteFill>
  );
};

// In DemoScene, sequence screenshots with varied, quick transitions:
<TransitionSeries>
  {shots.map((shot, i) => (
    <React.Fragment key={shot.file}>
      <TransitionSeries.Sequence durationInFrames={shot.durationInFrames}>
        <ScreenshotSlide shot={shot} />
      </TransitionSeries.Sequence>
      {i < shots.length - 1 && (
        <TransitionSeries.Transition
          presentation={i % 2 === 0 ? fade() : slide({ direction: "from-right" })}
          timing={springTiming({ durationInFrames: 8, config: { damping: 15 } })}
        />
      )}
    </React.Fragment>
  ))}
</TransitionSeries>
```

Vary transitions: fade, slide-from-right, slide-from-bottom. Don't repeat the same transition for every screenshot, and keep internal demo transitions fast unless a major structural shift justifies a longer move.

If a beat includes a click or page change:
- the cursor should arrive before the click, not on the same frame
- the UI response should land within about half a second
- the follow-up state should prove the spoken claim instead of becoming decoration

If a beat does not need a cursor:
- do not add one anyway just to keep motion on screen
- let framing, scroll motion, caption progression, or a state transition carry the beat
- quiet beats are useful for hero claims, broad proof, and result holds

### Scene Captions (REQUIRED)

Captions should tell the viewer why the moment matters. Page labels alone are not enough.

If a single narration window contains multiple interaction beats, let the caption progress with the beat sequence. For example: promise -> click target -> resulting proof. Do not hold one caption card unchanged while the interaction meaning shifts.

### Interaction-specific review

Interactive demos only work when the behavior feels authored:
- No random clicks without a story purpose
- No hover or click when there is no visible payoff
- No guessed target geometry when selectors can be measured
- No cursor movement that fights narration timing or arrives too late
- Page or section changes should support the spoken claim within about half a second
- UI SFX should be subtle support, not the loudest thing in the moment
- No repeated interaction template across most of the demo. If three or four adjacent beats use the same cursor grammar, redesign the sequence
- No fake "navigation" where the URL or cursor changes but the underlying state does not

```tsx
interface TourStep {
  label: string;
  startFrame: number;
  endFrame: number;
  url?: string;
}

interface DemoCaptionsProps {
  tourPlan: TourStep[];
  branding: { colors: { primary: string; text: string; bg: string } };
}

const DemoCaptions: React.FC<DemoCaptionsProps> = ({ tourPlan, branding }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {tourPlan.map((step, i) => {
        const localFrame = frame - step.startFrame;
        const duration = step.endFrame - step.startFrame;
        if (localFrame < 0 || localFrame > duration) return null;

        const enterProgress = spring({
          frame: localFrame,
          fps,
          config: { damping: 14, stiffness: 120 },
        });
        const exitProgress =
          localFrame > duration - 15
            ? interpolate(
                localFrame,
                [duration - 15, duration],
                [1, 0],
                { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
              )
            : 1;

        const opacity = enterProgress * exitProgress;
        const translateY = interpolate(enterProgress, [0, 1], [12, 0]);

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              bottom: 32,
              left: 140,
              display: "flex",
              alignItems: "center",
              gap: 10,
              opacity,
              transform: `translateY(${translateY}px)`,
            }}
          >
            <div
              style={{
                width: 8,
                height: 8,
                borderRadius: "50%",
                backgroundColor: branding.colors.primary,
                boxShadow: `0 0 8px ${branding.colors.primary}88`,
              }}
            />
            <div
              style={{
                padding: "8px 20px",
                borderRadius: 100,
                backgroundColor: `${branding.colors.bg}CC`,
                backdropFilter: "blur(12px)",
                border: `1px solid ${branding.colors.primary}33`,
                color: branding.colors.text,
                fontSize: 22,
                fontWeight: 600,
                fontFamily: branding.fonts?.body ?? "Inter, sans-serif",
                letterSpacing: "-0.01em",
              }}
            >
              {step.label}
            </div>
          </div>
        );
      })}
    </AbsoluteFill>
  );
};
```

**Usage in DemoScene:**

```tsx
const shots: DemoShot[] = [
  { file: "screenshots/01-homepage.png", label: "Start with the promise", url: "example.com", durationInFrames: 72, shotArchetype: "establish" },
  { file: "screenshots/02-features.png", label: "Turn the promise into proof", url: "example.com/features", durationInFrames: 54, shotArchetype: "detail-crop" },
  { file: "screenshots/03-product.png", label: "Show the workflow in motion", url: "example.com/product", durationInFrames: 96, shotArchetype: "push-in" },
  { file: "screenshots/04-pricing.png", label: "Land on the outcome", url: "example.com/pricing", durationInFrames: 60, shotArchetype: "result-state" },
];

<AbsoluteFill>
  <DeviceFrame tourPlan={shots}>
    <ScreenshotCarousel shots={shots} />
  </DeviceFrame>
  <DemoCaptions tourPlan={shots} />
</AbsoluteFill>
```

### Animated URL Bar (OPTIONAL)

The DeviceFrame top bar can display a URL that updates as the recording navigates between pages. Use it when it helps the viewer orient themselves. Omit it for tight proof crops, split-proof compositions, and any beat where browser chrome makes the video feel like passive browsing.

```tsx
interface AnimatedUrlBarProps {
  tourPlan: TourStep[];
  branding: { colors: { primary: string; text: string; bg: string } };
}

const AnimatedUrlBar: React.FC<AnimatedUrlBarProps> = ({ tourPlan, branding }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const currentStep = tourPlan.findLast((step) => frame >= step.startFrame);
  const currentUrl = currentStep?.url ?? tourPlan[0]?.url ?? "example.com";

  const prevStep = tourPlan.findLast((step) => frame >= step.startFrame + 8);
  const isTransitioning = currentStep && prevStep !== currentStep;

  const fadeIn = isTransitioning
    ? spring({
        frame: frame - currentStep.startFrame,
        fps,
        config: { damping: 20, stiffness: 80 },
      })
    : 1;

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        height: 40,
        padding: "0 16px",
        backgroundColor: `${branding.colors.bg}EE`,
        borderBottom: `1px solid ${branding.colors.primary}22`,
        fontFamily: "SF Mono, Menlo, monospace",
        fontSize: 13,
        color: branding.colors.text,
        opacity: 0.8,
      }}
    >
      <div style={{ display: "flex", gap: 6, marginRight: 14 }}>
        <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#ff5f57" }} />
        <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#febc2e" }} />
        <div style={{ width: 12, height: 12, borderRadius: "50%", backgroundColor: "#28c840" }} />
      </div>
      <div
        style={{
          flex: 1,
          padding: "4px 12px",
          borderRadius: 6,
          backgroundColor: `${branding.colors.bg}88`,
          border: `1px solid ${branding.colors.primary}15`,
          opacity: interpolate(fadeIn, [0, 1], [0.4, 1]),
        }}
      >
        <span style={{ opacity: 0.5 }}>https://</span>
        {currentUrl}
      </div>
    </div>
  );
};
```

Pass `tourPlan` to your `DeviceFrame` component and render the `AnimatedUrlBar` as the top bar instead of a static URL string.

### Camera Choreography

Each screenshot gets a deliberate move based on its job in the story. This prevents static frames from feeling frozen while keeping motion purposeful.

**Do NOT zoom in/out aggressively. Do NOT pan mechanically across every screenshot.** Motion should match the shot archetype.

```tsx
const { width, height } = useVideoConfig();
const frame = useCurrentFrame();
const { durationInFrames } = useVideoConfig();

const kenBurnsScale = interpolate(
  frame,
  [0, durationInFrames],
  [1.0, 1.03],
  { extrapolateRight: "clamp" }
);
const kenBurnsX = interpolate(
  frame,
  [0, durationInFrames],
  [0, -6],
  { extrapolateRight: "clamp" }
);
const kenBurnsY = interpolate(
  frame,
  [0, durationInFrames],
  [0, -3],
  { extrapolateRight: "clamp" }
);

<div
  style={{
    transform: `scale(${kenBurnsScale}) translate(${kenBurnsX}px, ${kenBurnsY}px)`,
    transformOrigin: "center center",
  }}
>
  {/* DeviceFrame content here */}
</div>
```

**Parameters:**
- Scale: `1.0 → 1.03` max (3% zoom over entire demo — barely noticeable)
- X drift: `0 → -6px` (slight leftward pan)
- Y drift: `0 → -3px` (slight upward pan)
- No easing jumps, no keyframes — one smooth linear interpolation

### Screenshot Emphasis

Do not place highlight boxes or callout rectangles over the product UI. Most of the time, scene captions, better framing, camera motion, and shot sequencing are sufficient. If a screenshot feels unclear, recapture or reframe it instead of drawing boxes on top of it.

```tsx
// No callout overlay component. If the viewer needs more guidance, improve the shot and caption instead of drawing rectangles over the UI.
```

### Device Frame Dimensions at 1080p

At 1920x1080 resolution, the device frame should be:
- Frame width: **1680px** (88% of canvas)
- Visible content area: ~936px tall
- Top bar: 44px (traffic lights + animated URL bar)
- Border radius: 14px
- Shadow: `0 24px 80px rgba(0,0,0,0.5)`

### Anti-patterns

| Anti-pattern | Why it's bad |
|---|---|
| Using `recordVideo` for the demo | Screen recordings look jittery and amateur — screenshots + Remotion animation is superior |
| Aggressive zoom in/out on screenshots | Robotic zoom-in/zoom-out looks mechanical and distracting |
| No captions on the demo | Viewer has no idea why the current moment matters |
| Static URL bar while screenshots change | Breaks the illusion of real navigation |
| Highlight boxes drawn over the UI | Usually feel inaccurate, arbitrary, and distracting |
| Fewer than 4 screenshots | Demo feels static and empty |
| Same transition for every screenshot | Monotonous — vary between fade and slide |
| Capturing loading states or cookie banners | Wait for full render before capturing |
| Holding one unchanged screen for too long | The video feels dead even if sync is technically correct |

---

## 7. Decorative Elements

Every non-demo scene should have at least one decorative element besides text. These are the visual "seasoning" that separates professional work from amateur.

### Accent Line Draw

An animated line that draws itself — use below headlines, as dividers, or as decorative accents.

```tsx
import { evolvePath } from "@remotion/paths";

const progress = spring({ frame, fps, delay, config: { damping: 200 } });
const pathD = `M 0 0 L 200 0`; // Horizontal line
const { strokeDasharray, strokeDashoffset } = evolvePath(progress, pathD);

<svg width={200} height={2}>
  <path
    d={pathD}
    stroke={colors.accent}
    strokeWidth={2}
    fill="none"
    strokeDasharray={strokeDasharray}
    strokeDashoffset={strokeDashoffset}
  />
</svg>
```

### Animated Gradient Orb

A large blurred circle that serves as a decorative background accent behind content.

```tsx
const breathe = interpolate(frame % 120, [0, 60, 120], [0.8, 1.0, 0.8]);
const drift = interpolate(frame, [0, 300], [0, 20], { extrapolateRight: "extend" });

<div
  style={{
    position: "absolute",
    right: -40,
    top: "20%",
    width: 300,
    height: 300,
    borderRadius: "50%",
    background: `radial-gradient(circle, ${colors.accent}55 0%, transparent 70%)`,
    filter: "blur(60px)",
    opacity: breathe * 0.6,
    transform: `translateY(${drift}px)`,
  }}
/>
```

### Geometric Shape Accents

Triangles, circles, or rectangles as decorative elements. Animate rotation and opacity.

```tsx
const rotation = interpolate(frame, [0, 600], [0, 45], { extrapolateRight: "extend" });
const enterOpacity = spring({ frame, fps, delay: 15, config: { damping: 200 } });

<div
  style={{
    position: "absolute",
    right: 120,
    bottom: 200,
    width: 60,
    height: 60,
    border: `1.5px solid ${colors.accent}44`,
    transform: `rotate(${rotation}deg)`,
    opacity: enterOpacity * 0.4,
  }}
/>
```

---

## 8. Anti-Patterns — What NOT to Do

These are the hallmarks of amateur video. If your scene matches any of these descriptions, redesign it.

### "PowerPoint Slide"
**Symptom:** Centered text on a gradient background with no other visual elements. Just a logo or headline floating in empty space.
**Fix:** This is the #1 most common failure. Every scene needs AT LEAST: 2 glow orbs drifting, 1 geometric accent element, glassmorphism card containers for content, and a blur-in entrance animation. See the "Complete Scene Composition Reference" in remotion-scenes.md for the minimum standard.

### "Bullet List"
**Symptom:** A vertical list with markers (X, checkmarks, dots) and bare text items directly on the background.
**Fix:** NEVER use bullet lists. Use glassmorphism cards in a 2x2 grid layout with icon containers. Each pain point gets its own card with: semi-transparent background, backdrop blur, subtle border, icon in a tinted rounded square, and a staggered entrance animation. See the ProblemScene template in remotion-scenes.md.

### "Bare Text on Gradient"
**Symptom:** Any text element that sits directly on the gradient background without a container, glow, or decorative context.
**Fix:** Wrap content in glassmorphism cards. Add accent lines below headlines. Use gradient text fills for headlines. Add textShadow glow on accent-colored text. Content should always feel "contained" in a visual space.

### "Copy-Paste Scenes"
**Symptom:** Problem scene and Benefits scene use the same layout (both are staggered lists, both are centered).
**Fix:** If Problem is a 2x2 card grid (card-contained), Benefits must use a different archetype — asymmetric-right with horizontal bars, or split-screen with a decorative element on one side.

### "Dead Demo"
**Symptom:** Device frame shows the same screenshot for 30-40 seconds with no transitions, or shows screenshots that don't match what the narrator is saying.
**Fix:** Use the screenshot carousel with shot-specific choreography rather than the same generic drift on every frame. Derive each narration beat from measured audio in `narration-timing.json`, then split long beats into additional visual beats. Add camera intent and richer captions when the narration references a specific product area.

### "Desync Demo"
**Symptom:** Narrator says "and here's the pricing" while the homepage screenshot is still visible.
**Fix:** Generate TTS per section (one `demo-*` segment per message beat), measure each segment's duration with `ffprobe`, and map the visual sequence to that exact timing window. This guarantees sync because durations are measured, not estimated. This is NOT optional — audio-visual sync is the difference between professional and amateur.

### "Blank Screenshot"
**Symptom:** A demo section shows a white/blank page because the screenshot captured a loading state or an empty page.
**Fix:** In the capture script, verify content is visible before capturing (check for headings, images). Verify file size (< 50KB = likely blank). Always visually inspect all PNGs before rendering, and reject screenshots that are technically non-blank but compositionally weak or missing the intended focal element.

### "Static Background"
**Symptom:** Background doesn't visibly move during the scene's duration.
**Fix:** Animate glow positions, rotate gradient angles, drift floating elements. The viewer should sense motion even subconsciously.

### "Animation Soup"
**Symptom:** 5+ elements animate simultaneously, competing for attention.
**Fix:** Stagger entrances. Each element gets its moment. Primary action first, secondary actions follow.

### "One-Note Motion"
**Symptom:** Every element uses the same animation (all fadeUp, all spring scale-in).
**Fix:** Mix techniques within a scene — headline uses blur-in, subtitle uses fadeUp, accent line draws, stat counts up. Variety creates visual rhythm.

---

## Quality Verification

Before considering any scene complete, verify:

1. Does it follow the 4-layer frame model? (animated background, mid-ground decoration, content, overlay)
2. Is the layout archetype different from the previous and next scenes?
3. Is there constant visible motion in the background?
4. Are text animations varied (not all the same type)?
5. Is there at least one decorative element besides text?
6. Is text on screen for at least 2 seconds before transitioning?
7. Does the text respect safe zones (90% of frame)?
8. For demo scenes: do screenshot durations match measured narration segments in `narration-timing.json`? (audio-visual sync)
9. For demo scenes: are all screenshots non-blank? (visually verified PNGs)
10. For demo scenes: does the visual beat change when the narration topic changes, or when the current beat has run too long?

## Post-Render Review Gate

Do not approve a render just because it is technically synced. Run these three review passes after export:

1. **Uninterrupted watch** — judge energy, clarity, and whether it feels like a professional product ad
2. **Scene-by-scene watch** — inspect legibility, visual support for each spoken claim, weak crops, and dead holds
3. **Audio-only pass** — listen for narration clarity, music masking, SFX harshness, and dead air

### Final acceptance checklist

Approve only if all are true:

1. The first 3 seconds feel intentional and brand-specific
2. The product is visible by 6–8 seconds unless the brief calls for a slower structure
3. No unchanged visual state lingers more than 4–6 seconds without a strong reason
4. Captions add meaning instead of repeating page labels
5. Spoken claims and visual proof stay aligned throughout
6. Music supports momentum without masking narration
7. The CTA lands clearly and holds long enough to read
8. The whole piece feels distinctive rather than generic
9. Cursor intent is obvious before every click, hover, or section jump
10. Page and section changes feel believable rather than like random browsing
11. Interaction SFX support the beat without sounding harsh, repetitive, or cartoonish

### Rework triggers

Reject and revise the render if any of these show up:

- The video is technically correct but still feels dead, slow, or generic
- A feature is named before the supporting visual appears
- Two or more transitions feel mushy, overly long, or stylistically repetitive
- Any screenshot is compositionally weak even if it is not blank
- Captions state only where the viewer is instead of why the moment matters
- A click or hover happens but the viewer cannot tell what payoff it created
- The cursor path looks robotic, frantic, or disconnected from the spoken beat
- UI sounds feel louder than the narration, too frequent, or disconnected from the interaction
