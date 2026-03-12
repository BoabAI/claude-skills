# Audio Mixing Patterns for Explainer Videos

Patterns for layering narration, background music, and sound effects in a Remotion explainer video composition.

## Audio Architecture

An explainer video has three audio layers:

1. **Narration** — the primary voice track, full volume
2. **Background music** — looped, low volume (~10%), creates energy
3. **Sound effects** — whoosh/click sounds at transition points

All audio uses the `<Audio>` component from `@remotion/media`. See the [audio rule](../../remotion-best-practices/rules/audio.md) for full API reference.

## Layer 1: Narration

The narration drives the video's total duration. Place it at the composition root:

```tsx
import { Audio } from "@remotion/media";
import { staticFile } from "remotion";

<Audio src={staticFile("narration.mp3")} />
```

No volume adjustment needed — narration plays at full volume.

### Source quality comes first

Mixing cannot rescue bad narration. If the voice sounds robotic, flat, or obviously synthetic at full volume, do not try to hide it with music or effects — regenerate the narration instead.

Before final render, ask:

- Does the voice sound human and brand-appropriate?
- Are pauses natural rather than mechanical?
- Is emphasis landing on the right words?
- Does the CTA still sound alive after the rest of the script?

If the answer is "no", fix the voice choice or the copy before touching the mix.

## Layer 2: Background Music

Loop a music track at low volume. The `volume` callback enables dynamic ducking if needed:

```tsx
<Audio
  src={staticFile("music.mp3")}
  volume={0.10}
  loop
/>
```

For a fade-in at the start and fade-out at the end:

```tsx
import { interpolate, useVideoConfig } from "remotion";

const { fps, durationInFrames } = useVideoConfig();

<Audio
  src={staticFile("music.mp3")}
  volume={(f) => {
    const fadeIn = interpolate(f, [0, fps], [0, 0.10], { extrapolateRight: "clamp" });
    const fadeOut = interpolate(f, [durationInFrames - fps, durationInFrames], [0.10, 0], { extrapolateLeft: "clamp" });
    return Math.min(fadeIn, fadeOut);
  }}
  loop
/>
```

### Music sourcing

Use royalty-free music. Good sources:
- Place an MP3 in `public/music.mp3`
- Ask the user to provide their preferred track
- For a quick default, a simple ambient electronic loop works well

## Layer 3: Sound Effects

Remotion provides built-in SFX URLs. Place them in `<Sequence>` components at transition points:

```tsx
import { Audio } from "@remotion/sfx";
import { Sequence } from "remotion";

const TRANSITION_FRAMES = [60, 180, 300, 450]; // Frame numbers where transitions occur

{TRANSITION_FRAMES.map((f, i) => (
  <Sequence key={i} from={f} durationInFrames={30}>
    <Audio src="https://remotion.media/whoosh.wav" volume={0.25} />
  </Sequence>
))}
```

### Available built-in SFX

| Sound | URL | Best for |
|-------|-----|----------|
| Whoosh | `https://remotion.media/whoosh.wav` | Slide/wipe transitions |
| Whip | `https://remotion.media/whip.wav` | Fast cuts |
| Page turn | `https://remotion.media/page-turn.wav` | Scene changes |
| Switch | `https://remotion.media/switch.wav` | UI toggle moments |
| Mouse click | `https://remotion.media/mouse-click.wav` | Click interactions in demo |
| Shutter | `https://remotion.media/shutter-modern.wav` | Screenshot/stat reveals |

## Complete Audio Layer Example

```tsx
import { AbsoluteFill, Sequence, useVideoConfig } from "remotion";
import { Audio } from "@remotion/media";
import { Audio as SfxAudio } from "@remotion/sfx";
import { staticFile, interpolate } from "remotion";

export const AudioLayers: React.FC<{ transitionFrames: number[] }> = ({ transitionFrames }) => {
  const { fps, durationInFrames } = useVideoConfig();

  return (
    <>
      {/* Layer 1: Narration */}
      <Audio src={staticFile("narration.mp3")} />

      {/* Layer 2: Background music with fade in/out */}
      <Audio
        src={staticFile("music.mp3")}
        volume={(f) => {
          const fadeIn = interpolate(f, [0, fps], [0, 0.10], { extrapolateRight: "clamp" });
          const fadeOut = interpolate(
            f,
            [durationInFrames - fps, durationInFrames],
            [0.10, 0],
            { extrapolateLeft: "clamp" }
          );
          return Math.min(fadeIn, fadeOut);
        }}
        loop
      />

      {/* Layer 3: Transition SFX */}
      {transitionFrames.map((f, i) => (
        <Sequence key={i} from={Math.max(0, f - 5)} durationInFrames={30}>
          <SfxAudio src="https://remotion.media/whoosh.wav" volume={0.25} />
        </Sequence>
      ))}
    </>
  );
};
```

## Tips

- **Never use more than 3 audio layers** — it creates a muddy mix
- **Music at 10% volume max** — the narration must dominate
- **SFX at 25% volume max** — they should accent, not distract
- **Fade music in/out** — abrupt starts/stops sound unprofessional
- **One whoosh per transition** — don't double up on SFX
- **Never use music to mask robotic narration** — if the voice is the problem, regenerate the voice
