# Remotion Scene Patterns for Explainer Videos

Structural animation patterns for building scene components. These provide the **animation skeleton** — the visual skin (colors, fonts, backgrounds, layouts) comes from the [frontend-design](${CLAUDE_SKILL_DIR}/../frontend-design/SKILL.md) skill and the branding config created in Phase 2.

**CRITICAL:** Never hardcode colors, fonts, background styles, or layout aesthetics in these patterns. All visual tokens come from `branding.ts`. All design decisions come from the frontend-design skill and the user's creative direction.

**For professional quality standards**, see [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) — every scene must follow the 4-layer frame model, use distinct layout archetypes, and include decorative elements beyond text.

## Shared Component Patterns

### Multi-Layer Animated Background

Every non-demo scene needs an atmospheric background with **constant visible motion**. A static gradient is not acceptable. Build backgrounds with at least 3 layers: base gradient, animated accent glows, and texture overlay.

```tsx
import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";
import { branding } from "../lib/branding";

export const AnimatedBackground: React.FC<{ variant?: "standard" | "deep" | "glow" }> = ({
  variant = "standard",
}) => {
  const frame = useCurrentFrame();
  const { colors } = branding;

  // All positions drift continuously — never static
  const glow1X = interpolate(frame, [0, 600], [20, 50], { extrapolateRight: "extend" });
  const glow1Y = interpolate(frame, [0, 800], [30, 60], { extrapolateRight: "extend" });
  const glow2X = interpolate(frame, [0, 500], [70, 40], { extrapolateRight: "extend" });
  const glow2Y = interpolate(frame, [0, 700], [60, 25], { extrapolateRight: "extend" });
  const gradientAngle = interpolate(frame, [0, 900], [145, 165], { extrapolateRight: "extend" });
  const grainSeed = Math.floor(frame / 2);

  return (
    <AbsoluteFill>
      {/* Layer 1: Base gradient — angle shifts slowly */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: variant === "deep"
            ? `linear-gradient(${gradientAngle}deg, ${colors.bgSecondary} 0%, ${colors.bgPrimary} 50%, ${colors.bgSecondary} 100%)`
            : `linear-gradient(${gradientAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 100%)`,
        }}
      />
      {/* Layer 2: Primary accent glow — drifts across frame */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse 600px 400px at ${glow1X}% ${glow1Y}%, ${colors.accent} 0%, transparent 70%)`,
          opacity: variant === "glow" ? 0.4 : 0.2,
        }}
      />
      {/* Layer 3: Secondary accent glow — moves opposite direction */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse 500px 350px at ${glow2X}% ${glow2Y}%, ${colors.accentSecondary ?? colors.accent} 0%, transparent 70%)`,
          opacity: 0.15,
        }}
      />
      {/* Layer 4: Grain texture — changes every 2 frames */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          opacity: 0.035,
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' seed='${grainSeed}' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")`,
          backgroundSize: "200px 200px",
        }}
      />
    </AbsoluteFill>
  );
};
```

See [video-design-principles.md](${CLAUDE_SKILL_DIR}/references/video-design-principles.md) for additional background techniques: floating gradient orbs, geometric grid, aurora/wave, and parallax layered.

### Logo with Spring Entrance

```tsx
import { Img, staticFile, spring, useCurrentFrame, useVideoConfig } from "remotion";

interface LogoProps {
  height: number;
  delay?: number;
}

export const Logo: React.FC<LogoProps> = ({ height, delay = 0 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({
    frame,
    fps,
    delay,
    config: { damping: 200 },
  });

  return (
    <Img
      src={staticFile("logo.svg")}
      style={{
        height,
        width: "auto",
        transform: `scale(${scale})`,
      }}
    />
  );
};
```

### Device Frame for Screenshot Carousel

Wrap screenshot content in a device mockup only when the frame adds clarity. The frame's visual style (colors, shadows, border radius, top-bar design) should match the overall creative direction — dark chrome for dark themes, light for light, etc. For tight proof crops or high-impact result shots, a full-bleed treatment can be stronger than showing browser chrome.

The primary techniques for demo enhancement are:
1. **Caption overlays** — editorial support that explains why the viewer should care
2. **Animated URL bar** — optional; use only when it helps orient the viewer
3. **Shot-specific camera choreography** — each screenshot gets its own scale, drift, and focal direction instead of the same Ken Burns move every time
4. **Optional cursor cues** — use these only when they help the viewer understand the narrated focal point

If the demo uses interaction beats, keep the rendering contract explicit:
- `moveCursor` drives pointer motion from ordered path points
- `click` and `hover` can trigger subtle target reactions and UI SFX
- `scrollReveal` can drive intra-shot motion or a short handoff into the next shot
- `pageChange` can update the URL bar or loading strip before the visual swap
- `captionVariant` can change caption copy inside a single narration window

#### DeviceFrame

Takes `children` (the carousel) and a `tourPlan` for the animated URL bar. No video import needed. If a shot contains a `pageChange` beat, the URL bar should react during that beat rather than waiting for the next shot boundary.

```tsx
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, spring } from "remotion";
import { branding } from "../lib/branding";

interface Shot {
  file: string;
  label: string;
  url: string;
  durationInFrames: number;
}

interface DeviceFrameProps {
  children: React.ReactNode;
  delay?: number;
  tourPlan: Shot[];
}

export const DeviceFrame: React.FC<DeviceFrameProps> = ({ children, delay = 0, tourPlan }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors } = branding;

  const entrance = spring({ frame, fps, delay, config: { damping: 15, mass: 1.2, stiffness: 60 } });
  const frameY = interpolate(entrance, [0, 1], [60, 0]);

  // Determine current URL from cumulative shot durations
  let accumulated = 0;
  let currentUrl = tourPlan[0]?.url ?? "";
  for (const shot of tourPlan) {
    if (frame < accumulated + shot.durationInFrames) {
      currentUrl = shot.url;
      break;
    }
    accumulated += shot.durationInFrames;
    currentUrl = shot.url;
  }

  const FRAME_WIDTH = 1680;
  const BAR_HEIGHT = 44;
  const CONTENT_HEIGHT = 936;
  const BORDER_RADIUS = 14;

  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <div
        style={{
          width: FRAME_WIDTH,
          borderRadius: BORDER_RADIUS,
          overflow: "hidden",
          boxShadow: "0 20px 60px rgba(0,0,0,0.4)",
          opacity: entrance,
          transform: `translateY(${frameY}px)`,
        }}
      >
        {/* Browser top bar with traffic lights and animated URL */}
        <div
          style={{
            height: BAR_HEIGHT,
            display: "flex",
            alignItems: "center",
            padding: "0 16px",
            gap: 8,
            background: colors.bgSecondary,
          }}
        >
          {["#FF5F57", "#FFBD2E", "#28CA41"].map((c, i) => (
            <div key={i} style={{ width: 10, height: 10, borderRadius: "50%", background: c, opacity: 0.8 }} />
          ))}
          <div style={{ flex: 1, textAlign: "center", fontSize: 13, fontFamily: "monospace", color: colors.textSecondary, opacity: 0.6 }}>
            {currentUrl}
          </div>
        </div>
        {/* Content area — carousel renders here */}
        <div style={{ overflow: "hidden", height: CONTENT_HEIGHT }}>
          {children}
        </div>
      </div>
    </AbsoluteFill>
  );
};
```

#### Shot archetypes

Use these as the default demo vocabulary:

1. **`establish`** — shows the overall interface or page state quickly
2. **`push-in`** — starts wider, then moves closer to the important area
3. **`detail-crop`** — drops browser framing and focuses on proof
4. **`split-proof`** — combines two supporting visuals in one beat
5. **`result-state`** — lands on the payoff, outcome, or completed action

#### ScreenshotSlide

Single screenshot with directed motion. Uses `<Img>` from `remotion`. This is the minimum viable pattern. For professional demos, prefer a shot-specific choreography component that reads camera metadata and `shotArchetype` from `tour-plan.json`.

```tsx
import { Img, staticFile, useCurrentFrame, useVideoConfig, interpolate } from "remotion";

interface ScreenshotSlideProps {
  file: string;
  shotArchetype?: "establish" | "push-in" | "detail-crop" | "split-proof" | "result-state";
}

export const ScreenshotSlide: React.FC<ScreenshotSlideProps> = ({ file, shotArchetype = "establish" }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  const motion = {
    establish: { startScale: 1.0, endScale: 1.03, startX: 0, endX: -6 },
    "push-in": { startScale: 1.01, endScale: 1.08, startX: 8, endX: -18 },
    "detail-crop": { startScale: 1.08, endScale: 1.12, startX: 0, endX: -10 },
    "split-proof": { startScale: 1.02, endScale: 1.05, startX: -4, endX: 6 },
    "result-state": { startScale: 1.04, endScale: 1.06, startX: 0, endX: 0 },
  }[shotArchetype];

  const scale = interpolate(frame, [0, durationInFrames], [motion.startScale, motion.endScale], { extrapolateRight: "clamp" });
  const driftX = interpolate(frame, [0, durationInFrames], [motion.startX, motion.endX], { extrapolateRight: "clamp" });

  return (
    <div style={{ width: "100%", height: "100%", overflow: "hidden" }}>
      <div
        style={{
          transform: `scale(${scale}) translateX(${driftX}px)`,
          transformOrigin: "center center",
        }}
      >
        <Img src={staticFile(file)} style={{ width: "100%", display: "block" }} />
      </div>
    </div>
  );
};
```

#### ScreenshotCarousel

Sequences screenshots for the demo section.

Important: if narration sync is strict, avoid letting overlapping transitions silently shorten a shot's usable time. Prefer `Series` plus shot-level entry/exit animation when exact timing matters more than fancy cross-scene overlap. Internal demo transitions should usually be fast: **6–10 frames**.

When a shot contains ordered interaction beats, the carousel should react to them:
- `scrollReveal` can add vertical motion or a section-jump handoff
- `pageChange` can trigger a flash, blur, or directional push before the next shot
- `transitionStyle` should actually affect the beat treatment instead of sitting unused in the plan
- Do not add random movement. Each authored reaction should support the narrated claim

```tsx
import { TransitionSeries } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { ScreenshotSlide } from "./ScreenshotSlide";

interface Shot {
  file: string;
  label: string;
  url: string;
  durationInFrames: number;
  shotArchetype?: "establish" | "push-in" | "detail-crop" | "split-proof" | "result-state";
}

const TRANSITION_FRAMES = 8;

const transitions = [fade(), slide({ direction: "from-right" }), fade(), slide({ direction: "from-left" })];

export const ScreenshotCarousel: React.FC<{ shots: Shot[] }> = ({ shots }) => (
  <TransitionSeries>
    {shots.map((shot, i) => (
      <>
        {i > 0 && (
          <TransitionSeries.Transition
            presentation={transitions[i % transitions.length]}
            timing={{ type: "in-out", inDuration: TRANSITION_FRAMES, outDuration: TRANSITION_FRAMES }}
          />
        )}
        <TransitionSeries.Sequence key={i} durationInFrames={shot.durationInFrames}>
          <ScreenshotSlide file={shot.file} shotArchetype={shot.shotArchetype} />
        </TransitionSeries.Sequence>
      </>
    ))}
  </TransitionSeries>
);
```

### Demo Captions

Animated caption labels that appear at the bottom-left of the device frame area. Each caption corresponds to a beat and uses spring animation for entrance, holds for the step duration, then fades out. This is the **primary** technique for guiding the viewer through a demo.
Good captions do more than repeat the section name. They should explain what the viewer is supposed to notice and why it matters.

If a shot contains `captionVariant` beats, update the caption copy inside the same narration window instead of freezing one caption card for the entire shot. This is especially useful after a click, hover, or section jump changes what the viewer should notice.

```tsx
// No callout overlay component. Use captions, camera movement, and cleaner capture framing instead.
```

Bad captions:
- `Dashboard`
- `Reporting page`
- `Automation features`

Better captions:
- `Spot delivery risk before it spreads`
- `Turn raw activity into a decision`
- `Automate the follow-up work away`

If a narration segment lasts longer than one visual beat, let the caption progress once or twice rather than holding identical copy for the full duration.

### Accent Line Draw

Animated line that draws itself — use below headlines, as dividers, or as decorative accents.

```tsx
import { evolvePath } from "@remotion/paths";

const progress = spring({ frame, fps, delay, config: { damping: 200 } });
const pathD = "M 0 0 L 200 0";
const { strokeDasharray, strokeDashoffset } = evolvePath(progress, pathD);

<svg width={200} height={4}>
  <path d={pathD} stroke={colors.accent} strokeWidth={2} fill="none"
    strokeDasharray={strokeDasharray} strokeDashoffset={strokeDashoffset} />
</svg>
```

### Animated Gradient Orb

Large blurred circle as a decorative accent behind content. Breathes and drifts slowly.

```tsx
const breathe = interpolate(frame % 120, [0, 60, 120], [0.8, 1.0, 0.8]);
const drift = interpolate(frame, [0, 300], [0, 20], { extrapolateRight: "extend" });

<div
  style={{
    position: "absolute",
    right: -40, top: "20%",
    width: 300, height: 300,
    borderRadius: "50%",
    background: `radial-gradient(circle, ${colors.accent}55 0%, transparent 70%)`,
    filter: "blur(60px)",
    opacity: breathe * 0.6,
    transform: `translateY(${drift}px)`,
  }}
/>
```

---

## Complete Scene Composition Reference

**CRITICAL: Every scene MUST be built from one of these templates.** The building blocks above are components — they're never used alone. These compositions show how to combine all 4 layers into scenes that look professionally produced. Adapt colors, fonts, and content per project — but the structural richness is non-negotiable.

A scene that's just "text on a gradient" is a PowerPoint slide. These templates prevent that.

### IntroScene — Logo Reveal with Atmospheric Depth

The intro is the first impression. It must feel cinematic, not like a title card. The logo floats in a field of ambient light with multiple glow sources and geometric accents.

```tsx
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig, spring, interpolate, Easing } from "remotion";
import { branding } from "../lib/branding";
import { evolvePath } from "@remotion/paths";

export const IntroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors } = branding;

  // Logo entrance: blur-in + scale (NOT just a basic spring scale)
  const logoProgress = spring({ frame, fps, delay: 10, config: { damping: 14, mass: 1.2, stiffness: 80 } });
  const logoScale = interpolate(logoProgress, [0, 1], [0.6, 1]);
  const logoBlur = interpolate(logoProgress, [0, 1], [24, 0]);
  const logoOpacity = interpolate(logoProgress, [0, 0.3, 1], [0, 0.8, 1]);

  // Ambient glow behind logo — pulses gently
  const glowPulse = interpolate(frame % 90, [0, 45, 90], [0.5, 0.8, 0.5]);
  const glowScale = interpolate(frame, [0, 200], [0.9, 1.1], { extrapolateRight: "extend" });

  // Background accent orbs — 3 large glows drifting at different speeds
  const orb1X = interpolate(frame, [0, 400], [15, 35], { extrapolateRight: "extend" });
  const orb1Y = interpolate(frame, [0, 500], [20, 45], { extrapolateRight: "extend" });
  const orb2X = interpolate(frame, [0, 350], [75, 55], { extrapolateRight: "extend" });
  const orb2Y = interpolate(frame, [0, 450], [70, 40], { extrapolateRight: "extend" });
  const orb3X = interpolate(frame, [0, 600], [50, 60], { extrapolateRight: "extend" });
  const orb3Y = interpolate(frame, [0, 300], [80, 65], { extrapolateRight: "extend" });

  // Geometric accent — animated border rectangle that draws itself
  const borderProgress = spring({ frame, fps, delay: 5, config: { damping: 200 } });
  const rectPath = "M 160 80 L 1760 80 L 1760 1000 L 160 1000 Z";
  const { strokeDasharray, strokeDashoffset } = evolvePath(borderProgress, rectPath);

  // Gradient angle rotation
  const gradAngle = interpolate(frame, [0, 600], [140, 170], { extrapolateRight: "extend" });

  // Small floating particles (6-8 tiny dots drifting)
  const particles = Array.from({ length: 8 }, (_, i) => ({
    x: (i * 137.5 + 50) % 100,
    y: (i * 89.3 + 20) % 100,
    speed: 0.02 + (i % 3) * 0.01,
    size: 2 + (i % 3),
    delay: i * 3,
  }));

  return (
    <AbsoluteFill>
      {/* LAYER 1: Animated gradient base */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(${gradAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 40%, ${colors.bgPrimary} 100%)`,
      }} />

      {/* LAYER 2a: Large ambient glow orbs */}
      <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
        <div style={{ position: "absolute", left: `${orb1X}%`, top: `${orb1Y}%`,
          width: 500, height: 500, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accent}40 0%, transparent 70%)`,
          filter: "blur(80px)", transform: "translate(-50%,-50%)",
        }} />
        <div style={{ position: "absolute", left: `${orb2X}%`, top: `${orb2Y}%`,
          width: 400, height: 400, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accentSecondary ?? colors.accent}30 0%, transparent 70%)`,
          filter: "blur(70px)", transform: "translate(-50%,-50%)",
        }} />
        <div style={{ position: "absolute", left: `${orb3X}%`, top: `${orb3Y}%`,
          width: 300, height: 300, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accent}20 0%, transparent 70%)`,
          filter: "blur(60px)", transform: "translate(-50%,-50%)",
        }} />
      </div>

      {/* LAYER 2b: Floating micro-particles */}
      <div style={{ position: "absolute", inset: 0, overflow: "hidden" }}>
        {particles.map((p, i) => {
          const pProgress = spring({ frame, fps, delay: p.delay + 15, config: { damping: 200 } });
          const py = p.y + frame * p.speed;
          return (
            <div key={i} style={{
              position: "absolute", left: `${p.x}%`, top: `${py % 110}%`,
              width: p.size, height: p.size, borderRadius: "50%",
              background: colors.accent, opacity: pProgress * 0.3,
            }} />
          );
        })}
      </div>

      {/* LAYER 2c: Geometric border accent — draws itself in */}
      <svg width={1920} height={1080} style={{ position: "absolute", inset: 0 }}>
        <path d={rectPath} fill="none" stroke={`${colors.accent}22`} strokeWidth={1}
          strokeDasharray={strokeDasharray} strokeDashoffset={strokeDashoffset} />
      </svg>

      {/* LAYER 3: Logo with glow halo */}
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        {/* Glow halo behind logo */}
        <div style={{
          position: "absolute",
          width: 300, height: 300, borderRadius: "50%",
          background: `radial-gradient(circle, ${colors.accent}50 0%, transparent 70%)`,
          filter: "blur(50px)",
          opacity: glowPulse,
          transform: `scale(${glowScale})`,
        }} />
        {/* Logo */}
        <Img src={staticFile("logo.svg")} style={{
          height: 80, width: "auto",
          transform: `scale(${logoScale})`,
          filter: `blur(${logoBlur}px)`,
          opacity: logoOpacity,
        }} />
      </AbsoluteFill>

      {/* LAYER 4: Film overlay */}
      <FilmOverlay showLightLeak lightLeakSeed={42} />
    </AbsoluteFill>
  );
};
```

Notice: 3 glow orbs, floating particles, geometric border drawing, logo with glow halo + blur-in entrance, light leak overlay. This is the minimum richness for an intro.

### TitleScene — Bold Typography with Decorative Depth

The title establishes the product. Asymmetric layout, gradient headline, accent elements — never just "centered text on dark."

```tsx
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { evolvePath } from "@remotion/paths";
import { branding } from "../lib/branding";

export const TitleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors, font } = branding;

  // Staggered content entrance
  const logoDelay = 5;
  const headlineDelay = 12;
  const subtitleDelay = 20;
  const urlDelay = 28;
  const accentDelay = 8;

  const logoProgress = spring({ frame, fps, delay: logoDelay, config: { damping: 200 } });
  const headlineProgress = spring({ frame, fps, delay: headlineDelay, config: { damping: 14, mass: 1, stiffness: 80 } });
  const subtitleProgress = spring({ frame, fps, delay: subtitleDelay, config: { damping: 200 } });
  const urlProgress = spring({ frame, fps, delay: urlDelay, config: { damping: 200 } });

  // Headline blur-in
  const headlineBlur = interpolate(headlineProgress, [0, 1], [16, 0]);
  const headlineY = interpolate(headlineProgress, [0, 1], [30, 0]);

  // Gradient shimmer on headline
  const shimmerX = interpolate(frame, [headlineDelay + 15, headlineDelay + 50], [-100, 200], {
    extrapolateLeft: "clamp", extrapolateRight: "clamp",
  });

  // Accent line drawing under headline
  const lineProgress = spring({ frame, fps, delay: accentDelay + 10, config: { damping: 200 } });
  const linePath = "M 0 0 L 180 0";
  const lineEvolve = evolvePath(lineProgress, linePath);

  // Large decorative orb — right side, drifting
  const orbY = interpolate(frame, [0, 300], [25, 35], { extrapolateRight: "extend" });
  const orbBreathe = interpolate(frame % 90, [0, 45, 90], [0.7, 1.0, 0.7]);

  // Background gradient rotation
  const gradAngle = interpolate(frame, [0, 500], [135, 155], { extrapolateRight: "extend" });

  // Small geometric shapes — top-right corner accent
  const shapeRotation = interpolate(frame, [0, 300], [0, 45], { extrapolateRight: "extend" });
  const shapeProgress = spring({ frame, fps, delay: accentDelay, config: { damping: 200 } });

  return (
    <AbsoluteFill>
      {/* LAYER 1: Animated gradient */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(${gradAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 100%)`,
      }} />

      {/* LAYER 2a: Large decorative orb — right side */}
      <div style={{
        position: "absolute", right: -60, top: `${orbY}%`,
        width: 500, height: 500, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.accent}40 0%, ${colors.accent}10 40%, transparent 70%)`,
        filter: "blur(60px)", opacity: orbBreathe * 0.7,
      }} />

      {/* LAYER 2b: Secondary orb — bottom-left */}
      <div style={{
        position: "absolute", left: -80, bottom: -100,
        width: 350, height: 350, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.accentSecondary ?? colors.accent}25 0%, transparent 70%)`,
        filter: "blur(50px)", opacity: 0.5,
      }} />

      {/* LAYER 2c: Geometric accent — top right */}
      <div style={{
        position: "absolute", right: 120, top: 100,
        width: 60, height: 60,
        border: `1.5px solid ${colors.accent}33`,
        borderRadius: 8,
        transform: `rotate(${shapeRotation}deg) scale(${shapeProgress})`,
        opacity: shapeProgress * 0.5,
      }} />
      <div style={{
        position: "absolute", right: 200, top: 160,
        width: 8, height: 8, borderRadius: "50%",
        background: colors.accent,
        opacity: shapeProgress * 0.4,
      }} />

      {/* LAYER 3: Content — asymmetric left layout */}
      <AbsoluteFill style={{ padding: "0 120px", justifyContent: "center" }}>
        {/* Logo + product name */}
        <div style={{
          display: "flex", alignItems: "center", gap: 16, marginBottom: 24,
          opacity: logoProgress,
          transform: `translateY(${interpolate(logoProgress, [0, 1], [20, 0])}px)`,
        }}>
          <Img src={staticFile("logo.svg")} style={{ height: 40, width: "auto" }} />
          <span style={{
            fontSize: 28, fontWeight: 600, color: colors.textSecondary,
            fontFamily: font.body, letterSpacing: "0.02em",
          }}>
            {branding.company}
          </span>
        </div>

        {/* Headline — gradient shimmer text, blur-in entrance */}
        <div style={{
          fontSize: 72, fontWeight: 800, lineHeight: 1.1,
          fontFamily: font.display, maxWidth: 900,
          background: `linear-gradient(90deg, ${colors.textPrimary} 0%, ${colors.accent} 45%, ${colors.textPrimary} 55%, ${colors.textPrimary} 100%)`,
          backgroundSize: "200% 100%",
          backgroundPosition: `${shimmerX}% 0`,
          WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text",
          opacity: headlineProgress,
          filter: `blur(${headlineBlur}px)`,
          transform: `translateY(${headlineY}px)`,
        }}>
          {branding.tagline}
        </div>

        {/* Accent line under headline */}
        <svg width={180} height={4} style={{ marginTop: 20, marginBottom: 20 }}>
          <path d={linePath} stroke={colors.accent} strokeWidth={3} fill="none"
            strokeDasharray={lineEvolve.strokeDasharray}
            strokeDashoffset={lineEvolve.strokeDashoffset} />
        </svg>

        {/* Subtitle */}
        <div style={{
          fontSize: 26, color: colors.textSecondary, fontFamily: font.body,
          maxWidth: 600, lineHeight: 1.5,
          opacity: subtitleProgress,
          transform: `translateY(${interpolate(subtitleProgress, [0, 1], [15, 0])}px)`,
        }}>
          Design, prototype, develop, and publish — all in one place
        </div>

        {/* URL with glow */}
        <div style={{
          marginTop: 28, fontSize: 20, fontFamily: font.body,
          color: colors.accent, fontWeight: 500, letterSpacing: "0.03em",
          opacity: urlProgress,
          textShadow: `0 0 20px ${colors.accent}44`,
        }}>
          {branding.url}
        </div>
      </AbsoluteFill>

      {/* LAYER 4: Film overlay */}
      <FilmOverlay />
    </AbsoluteFill>
  );
};
```

Key design moves: asymmetric-left layout (not centered), gradient shimmer headline, accent line drawing, decorative orbs + geometric shapes, staggered entrance timing, URL with glow.

### ProblemScene — Cards with Visual Hierarchy (NOT a Bullet List)

The problem scene must NEVER be a bullet list. Use glassmorphism cards with icons, staggered entrance, and a negative-toned header. This layout uses a 2x2 card grid.

```tsx
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { branding } from "../lib/branding";

interface PainPoint {
  icon: string;
  text: string;
}

const painPoints: PainPoint[] = [
  { icon: "📁", text: "Files scattered across multiple tools" },
  { icon: "💬", text: "Feedback lost in email threads" },
  { icon: "🔍", text: "Developers guessing at design specs" },
  { icon: "🔀", text: "Teams working in silos, not together" },
];

export const ProblemScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors, font } = branding;

  // Header entrance
  const headerProgress = spring({ frame, fps, delay: 5, config: { damping: 14, mass: 1, stiffness: 80 } });
  const headerBlur = interpolate(headerProgress, [0, 1], [12, 0]);

  // Background
  const gradAngle = interpolate(frame, [0, 600], [145, 160], { extrapolateRight: "extend" });
  const warnOrbX = interpolate(frame, [0, 400], [70, 55], { extrapolateRight: "extend" });
  const warnOrbY = interpolate(frame, [0, 500], [30, 50], { extrapolateRight: "extend" });

  return (
    <AbsoluteFill>
      {/* LAYER 1: Darker gradient for problem mood */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(${gradAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 50%, ${colors.bgPrimary} 100%)`,
      }} />

      {/* LAYER 2a: Negative-tinted glow orb — sets the "problem" mood */}
      <div style={{
        position: "absolute", left: `${warnOrbX}%`, top: `${warnOrbY}%`,
        width: 600, height: 600, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.negative}30 0%, transparent 70%)`,
        filter: "blur(80px)", transform: "translate(-50%,-50%)",
      }} />

      {/* LAYER 2b: Subtle accent orb — bottom left for depth */}
      <div style={{
        position: "absolute", left: -50, bottom: -80,
        width: 300, height: 300, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.accent}15 0%, transparent 70%)`,
        filter: "blur(60px)",
      }} />

      {/* LAYER 3: Content */}
      <AbsoluteFill style={{ padding: "80px 120px" }}>
        {/* Section header — negative color, blur-in entrance */}
        <div style={{
          fontSize: 48, fontWeight: 800, fontFamily: font.display,
          color: colors.negative ?? colors.negativeAccent ?? "#ff6b6b",
          opacity: headerProgress, filter: `blur(${headerBlur}px)`,
          transform: `translateY(${interpolate(headerProgress, [0, 1], [20, 0])}px)`,
          marginBottom: 48,
        }}>
          Design workflows are broken
        </div>

        {/* 2x2 Card grid */}
        <div style={{
          display: "grid", gridTemplateColumns: "1fr 1fr",
          gap: 24, maxWidth: 1200,
        }}>
          {painPoints.map((point, i) => {
            const cardDelay = 12 + i * 6;
            const cardProgress = spring({ frame, fps, delay: cardDelay, config: { damping: 15, mass: 1, stiffness: 80 } });
            const cardY = interpolate(cardProgress, [0, 1], [40, 0]);
            const cardScale = interpolate(cardProgress, [0, 1], [0.95, 1]);

            // Subtle glow on card entrance
            const glowOpacity = interpolate(cardProgress, [0.5, 1], [0, 0.15], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

            return (
              <div key={i} style={{
                position: "relative",
                background: `rgba(255,255,255,0.04)`,
                backdropFilter: "blur(30px)", WebkitBackdropFilter: "blur(30px)",
                borderRadius: 16,
                border: `1px solid rgba(255,255,255,0.08)`,
                padding: "36px 40px",
                display: "flex", alignItems: "flex-start", gap: 20,
                opacity: cardProgress,
                transform: `translateY(${cardY}px) scale(${cardScale})`,
              }}>
                {/* Card accent glow — top edge */}
                <div style={{
                  position: "absolute", top: -1, left: 40, right: 40, height: 2,
                  background: `linear-gradient(90deg, transparent, ${colors.negative ?? "#ff6b6b"}${Math.round(glowOpacity * 255).toString(16).padStart(2, "0")}, transparent)`,
                  borderRadius: 2,
                }} />

                {/* Icon in a tinted circle */}
                <div style={{
                  width: 52, height: 52, borderRadius: 12,
                  background: `${colors.negative ?? "#ff6b6b"}15`,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 24, flexShrink: 0,
                }}>
                  {point.icon}
                </div>

                {/* Text */}
                <div style={{
                  fontSize: 24, color: colors.textPrimary, fontFamily: font.body,
                  fontWeight: 500, lineHeight: 1.4,
                }}>
                  {point.text}
                </div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>

      {/* LAYER 4: Film overlay */}
      <FilmOverlay />
    </AbsoluteFill>
  );
};
```

Key design moves: glassmorphism cards (not bullet list), 2x2 grid layout, icon in tinted container, negative-colored glow orb for mood, staggered card entrance with scale + translate, accent glow line on each card's top edge, blur-in header.

### BenefitsScene — Asymmetric Right Layout with Feature Cards

Must use a different layout archetype than ProblemScene. This uses asymmetric-right with a decorative element on the left and content stacked on the right.

```tsx
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { branding } from "../lib/branding";

interface Benefit {
  icon: string;
  title: string;
  description: string;
}

const benefits: Benefit[] = [
  { icon: "⚡", title: "Real-Time Collaboration", description: "Everyone works in the same file, simultaneously" },
  { icon: "🔒", title: "Enterprise Security", description: "SOC 2 compliant with SSO and audit logs" },
  { icon: "🚀", title: "Ship Faster", description: "From design to production in half the time" },
];

export const BenefitsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors, font } = branding;

  // Background
  const gradAngle = interpolate(frame, [0, 500], [155, 140], { extrapolateRight: "extend" });

  // Left-side large decorative element — accent gradient ring
  const ringScale = spring({ frame, fps, delay: 5, config: { damping: 200 } });
  const ringRotation = interpolate(frame, [0, 600], [0, 90], { extrapolateRight: "extend" });
  const ringBreathe = interpolate(frame % 120, [0, 60, 120], [0.85, 1.0, 0.85]);

  // Section label
  const labelProgress = spring({ frame, fps, delay: 8, config: { damping: 200 } });

  // Header
  const headerProgress = spring({ frame, fps, delay: 12, config: { damping: 14, mass: 1, stiffness: 80 } });

  return (
    <AbsoluteFill>
      {/* LAYER 1: Animated gradient */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(${gradAngle}deg, ${colors.bgSecondary} 0%, ${colors.bgPrimary} 50%, ${colors.bgSecondary} 100%)`,
      }} />

      {/* LAYER 2a: Positive-tinted glow */}
      <div style={{
        position: "absolute", left: "10%", top: "30%",
        width: 500, height: 500, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.accent}25 0%, transparent 70%)`,
        filter: "blur(80px)",
      }} />

      {/* LAYER 2b: Decorative gradient ring — left side */}
      <div style={{
        position: "absolute", left: 60, top: "50%",
        width: 320, height: 320,
        borderRadius: "50%",
        border: `2px solid ${colors.accent}30`,
        background: `conic-gradient(from ${ringRotation}deg, ${colors.accent}20, transparent, ${colors.accent}10, transparent)`,
        transform: `translateY(-50%) scale(${ringScale * ringBreathe})`,
        opacity: ringScale * 0.6,
      }} />
      {/* Inner ring */}
      <div style={{
        position: "absolute", left: 120, top: "50%",
        width: 200, height: 200, borderRadius: "50%",
        border: `1px solid ${colors.accent}20`,
        transform: `translateY(-50%) scale(${ringScale}) rotate(${-ringRotation}deg)`,
        opacity: ringScale * 0.4,
      }} />

      {/* LAYER 3: Content — right-aligned */}
      <AbsoluteFill style={{ padding: "80px 120px", justifyContent: "center", alignItems: "flex-end" }}>
        <div style={{ maxWidth: 780 }}>
          {/* Section label */}
          <div style={{
            fontSize: 16, fontWeight: 600, fontFamily: font.body,
            color: colors.accent, textTransform: "uppercase" as const,
            letterSpacing: "0.15em", marginBottom: 12,
            opacity: labelProgress,
            transform: `translateX(${interpolate(labelProgress, [0, 1], [20, 0])}px)`,
          }}>
            Why teams choose us
          </div>

          {/* Header */}
          <div style={{
            fontSize: 44, fontWeight: 800, fontFamily: font.display,
            color: colors.textPrimary, lineHeight: 1.2, marginBottom: 40,
            opacity: headerProgress,
            filter: `blur(${interpolate(headerProgress, [0, 1], [10, 0])}px)`,
            transform: `translateY(${interpolate(headerProgress, [0, 1], [20, 0])}px)`,
          }}>
            Built for modern design teams
          </div>

          {/* Benefit cards — horizontal bar style */}
          {benefits.map((benefit, i) => {
            const cardDelay = 18 + i * 7;
            const cardProgress = spring({ frame, fps, delay: cardDelay, config: { damping: 15, mass: 1, stiffness: 80 } });
            const cardX = interpolate(cardProgress, [0, 1], [60, 0]);

            return (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 24,
                marginBottom: 20,
                background: `rgba(255,255,255,0.03)`,
                backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)",
                borderRadius: 14,
                border: `1px solid rgba(255,255,255,0.06)`,
                padding: "24px 32px",
                opacity: cardProgress,
                transform: `translateX(${cardX}px)`,
              }}>
                {/* Accent bar — left edge */}
                <div style={{
                  position: "absolute" as const, left: 0, top: 8, bottom: 8, width: 3,
                  background: colors.accent, borderRadius: 3,
                  opacity: interpolate(cardProgress, [0.5, 1], [0, 0.8], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
                }} />

                <div style={{
                  width: 48, height: 48, borderRadius: 12,
                  background: `${colors.accent}15`,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 22, flexShrink: 0,
                }}>
                  {benefit.icon}
                </div>

                <div>
                  <div style={{
                    fontSize: 22, fontWeight: 700, color: colors.textPrimary,
                    fontFamily: font.display, marginBottom: 4,
                  }}>
                    {benefit.title}
                  </div>
                  <div style={{
                    fontSize: 18, color: colors.textSecondary,
                    fontFamily: font.body,
                  }}>
                    {benefit.description}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>

      {/* LAYER 4: Film overlay */}
      <FilmOverlay />
    </AbsoluteFill>
  );
};
```

Key design moves: asymmetric-right layout (opposite of title's asymmetric-left), decorative conic-gradient rings on the left, section label in accent color, horizontal benefit cards with left-edge accent bars, slide-in from right entrance, blur-in header.

### StatsScene — Full-Bleed with Animated Numbers and Glow Accents

Stats need drama. Large animated numbers with glow effects, not just plain text counting up.

```tsx
import { AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate, Easing } from "remotion";
import { branding } from "../lib/branding";

interface Stat {
  number: number;
  suffix: string;
  label: string;
}

const stats: Stat[] = [
  { number: 4, suffix: "M+", label: "Designers worldwide" },
  { number: 150, suffix: "K+", label: "Companies trust Figma" },
  { number: 99.9, suffix: "%", label: "Uptime SLA" },
];

export const StatsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors, font } = branding;

  const gradAngle = interpolate(frame, [0, 400], [160, 145], { extrapolateRight: "extend" });

  return (
    <AbsoluteFill>
      {/* LAYER 1 */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(${gradAngle}deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 100%)`,
      }} />

      {/* LAYER 2: Glow behind each stat */}
      <AbsoluteFill style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 80 }}>
        {stats.map((_, i) => {
          const delay = 8 + i * 5;
          const progress = spring({ frame, fps, delay, config: { damping: 200 } });
          return (
            <div key={i} style={{
              width: 250, height: 250, borderRadius: "50%",
              background: `radial-gradient(circle, ${colors.accent}20 0%, transparent 70%)`,
              filter: "blur(50px)", opacity: progress * 0.6,
            }} />
          );
        })}
      </AbsoluteFill>

      {/* LAYER 3: Stat cards */}
      <AbsoluteFill style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 60 }}>
        {stats.map((stat, i) => {
          const delay = 8 + i * 5;
          const cardProgress = spring({ frame, fps, delay, config: { damping: 15, mass: 1, stiffness: 80 } });
          const countProgress = interpolate(frame - delay, [0, 2 * fps], [0, 1], {
            extrapolateLeft: "clamp", extrapolateRight: "clamp",
            easing: Easing.out(Easing.quad),
          });
          const displayNum = stat.number % 1 === 0
            ? Math.round(countProgress * stat.number).toLocaleString()
            : (countProgress * stat.number).toFixed(1);

          return (
            <div key={i} style={{
              textAlign: "center" as const,
              background: `rgba(255,255,255,0.03)`,
              backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)",
              border: `1px solid rgba(255,255,255,0.06)`,
              borderRadius: 20, padding: "48px 56px",
              opacity: cardProgress,
              transform: `scale(${interpolate(cardProgress, [0, 1], [0.8, 1])}) translateY(${interpolate(cardProgress, [0, 1], [30, 0])}px)`,
            }}>
              {/* Number with glow */}
              <div style={{
                fontSize: 64, fontWeight: 800, fontFamily: font.display,
                color: colors.accent,
                textShadow: `0 0 40px ${colors.accent}44, 0 0 80px ${colors.accent}22`,
                lineHeight: 1,
              }}>
                {displayNum}{stat.suffix}
              </div>
              {/* Label */}
              <div style={{
                fontSize: 18, color: colors.textSecondary, fontFamily: font.body,
                marginTop: 12, fontWeight: 500,
              }}>
                {stat.label}
              </div>
            </div>
          );
        })}
      </AbsoluteFill>

      {/* LAYER 4 */}
      <FilmOverlay />
    </AbsoluteFill>
  );
};
```

### OutroScene — CTA with Pulsing Glow and Atmospheric Close

```tsx
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";
import { branding } from "../lib/branding";

export const OutroScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const { colors, font } = branding;

  const logoProgress = spring({ frame, fps, delay: 5, config: { damping: 200 } });
  const taglineProgress = spring({ frame, fps, delay: 12, config: { damping: 14, mass: 1, stiffness: 80 } });
  const ctaProgress = spring({ frame, fps, delay: 20, config: { damping: 200 } });

  // Pulsing URL glow
  const pulse = interpolate(frame % 60, [0, 30, 60], [0.6, 1, 0.6]);

  // Background orb drifting
  const orbX = interpolate(frame, [0, 400], [45, 55], { extrapolateRight: "extend" });
  const orbY = interpolate(frame, [0, 300], [40, 50], { extrapolateRight: "extend" });

  return (
    <AbsoluteFill>
      {/* LAYER 1 */}
      <div style={{ position: "absolute", inset: 0,
        background: `linear-gradient(155deg, ${colors.bgPrimary} 0%, ${colors.bgSecondary} 100%)`,
      }} />

      {/* LAYER 2: Central glow */}
      <div style={{
        position: "absolute", left: `${orbX}%`, top: `${orbY}%`,
        width: 600, height: 600, borderRadius: "50%",
        background: `radial-gradient(circle, ${colors.accent}35 0%, transparent 70%)`,
        filter: "blur(80px)", transform: "translate(-50%,-50%)",
      }} />

      {/* LAYER 3: Content — centered stack */}
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
        <Img src={staticFile("logo.svg")} style={{
          height: 56, width: "auto", marginBottom: 32,
          opacity: logoProgress,
          transform: `scale(${interpolate(logoProgress, [0, 1], [0.8, 1])})`,
        }} />

        <div style={{
          fontSize: 52, fontWeight: 800, fontFamily: font.display,
          color: colors.textPrimary, textAlign: "center" as const,
          maxWidth: 700, lineHeight: 1.2, marginBottom: 16,
          opacity: taglineProgress,
          filter: `blur(${interpolate(taglineProgress, [0, 1], [10, 0])}px)`,
        }}>
          {branding.tagline}
        </div>

        <div style={{
          fontSize: 20, color: colors.textSecondary, fontFamily: font.body,
          textAlign: "center" as const, marginBottom: 40,
          opacity: taglineProgress,
        }}>
          Start designing for free today
        </div>

        {/* CTA URL with pulsing glow */}
        <div style={{
          fontSize: 28, fontWeight: 600, fontFamily: font.display,
          color: colors.accent, letterSpacing: "0.05em",
          opacity: ctaProgress * pulse,
          textShadow: `0 0 30px ${colors.accent}66, 0 0 60px ${colors.accent}33`,
        }}>
          {branding.url}
        </div>
      </AbsoluteFill>

      {/* LAYER 4 */}
      <FilmOverlay showLightLeak lightLeakSeed={99} />
    </AbsoluteFill>
  );
};
```

---

**Minimum requirements for any scene composition:**
1. At least 2 distinct Layer 2 elements (glow orbs, geometric shapes, particles, rings, accent lines)
2. Content entrances must use blur-in OR scale+translate — not just opacity fade
3. At least one element with `textShadow` or accent glow
4. Background gradient angle must animate (never static)
5. Cards/containers must use glassmorphism with backdrop blur and subtle borders — never bare text on gradient
