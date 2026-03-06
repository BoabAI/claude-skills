# FFmpeg Assembly Patterns

Reference for building the `assemble.sh` script that composites branded slides, screen recording, narration audio, and watermark into a final marketing video.

## Critical Rules

These rules were discovered through production debugging. **Do not skip them.**

### Rule 1: ALWAYS use full audio duration for ALL loop inputs

```bash
# CORRECT: All loops use full audio duration
-loop 1 -t "$ADUR" -i "$ASSETS/01-intro.png" \
-loop 1 -t "$ADUR" -i "$ASSETS/02-title.png" \
-loop 1 -t "$ADUR" -i "$ASSETS/03-stat.png" \

# WRONG: Short durations cause frame exhaustion
-loop 1 -t 10  -i "$ASSETS/01-intro.png" \
-loop 1 -t 8   -i "$ASSETS/03-stat.png" \    # <-- consumed before overlay window!
```

**Why:** FFmpeg's overlay filter consumes frames from the input stream even when `enable='between(t,X,Y)'` is false. A short loop (e.g., `-t 8`) creates only 8 seconds of frames. If the overlay window starts at t=52, the stream is already exhausted and the slide never appears.

### Rule 2: Use ABSOLUTE timestamps for fades

Fade `st` values are positions on the **output timeline**, not relative to the input stream start.

```bash
# CORRECT: Absolute output timestamps
[3:v]scale=1280:720,setsar=1,format=rgba,
  fade=t=in:st=6:d=0.5:alpha=1,
  fade=t=out:st=13:d=0.5:alpha=1[problem];

# WRONG: Relative to input (would be st=0 for fade-in)
```

### Rule 3: Staggered crossfade for consecutive slides

When two slides are adjacent (e.g., title → problem → benefits), the incoming slide must reach full opacity BEFORE the outgoing starts fading out. Otherwise the base video bleeds through.

```
Timeline:
         6.0   6.5   7.0
Problem: |===fade-in===|========solid========|
Title:   |====solid====|===fade-out===|

At 6.0: Problem starts fading in, Title still fully opaque
At 6.5: Problem fully opaque, Title starts fading out
At 7.0: Title fully transparent
→ Base video is NEVER visible during transition
```

## Input Structure

```
Input 0:    demo.webm           (screen recording)
Input 1-N:  slide PNGs          (looped as video, -loop 1 -t "$ADUR")
Input N+1:  narration-pro.mp3   (audio)
Input N+2:  logo.png            (watermark)
```

## Complete Filter Graph Pattern

```bash
FADE=0.5

ffmpeg -y \
  -i "$VIDEO" \
  -loop 1 -t "$ADUR" -i "$ASSETS/01-intro.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/02-title.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/02a-problem.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/02b-benefits.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/03-stat.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/04-section.png" \
  -loop 1 -t "$ADUR" -i "$ASSETS/07-outro.png" \
  -i "$AUDIO" \
  -i "$LOGO" \
  -filter_complex "
    [0:v]scale=1280:720,setsar=1[base];

    # Intro: hard cut in, fade out at 2s
    [1:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=out:st=2:d=${FADE}:alpha=1[intro];

    # Title: staggered fade-in (0.5s before intro fade-out)
    [2:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=1.5:d=${FADE}:alpha=1,
      fade=t=out:st=6.5:d=${FADE}:alpha=1[title];

    # Problem: staggered fade-in (0.5s before title fade-out)
    [3:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=6:d=${FADE}:alpha=1,
      fade=t=out:st=13:d=${FADE}:alpha=1[problem];

    # Benefits: staggered fade-in (0.5s before problem fade-out)
    [4:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=12.5:d=${FADE}:alpha=1,
      fade=t=out:st=17.5:d=${FADE}:alpha=1[benefits];

    # Mid-video slides (isolated, no crossfade needed)
    [5:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=22:d=${FADE}:alpha=1,
      fade=t=out:st=26:d=${FADE}:alpha=1[stat1];

    [6:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=52:d=${FADE}:alpha=1,
      fade=t=out:st=55.5:d=${FADE}:alpha=1[scoring];

    # Outro: fade in, no fade out (holds to end)
    [7:v]scale=1280:720,setsar=1,format=rgba,
      fade=t=in:st=74:d=0.8:alpha=1[outro];

    # Watermark: 15% opacity, bottom-left, only during demo portions
    [9:v]scale=120:-1,format=rgba,colorchannelmixer=aa=0.15[watermark];

    # Chain overlays sequentially
    [base][intro]overlay=enable='between(t,0,2.5)'[v1];
    [v1][title]overlay=enable='between(t,1.5,7)'[v2];
    [v2][problem]overlay=enable='between(t,6,13.5)'[v3];
    [v3][benefits]overlay=enable='between(t,12.5,18)'[v4];
    [v4][stat1]overlay=enable='between(t,22,26.5)'[v5];
    [v5][scoring]overlay=enable='between(t,52,56)'[v6];
    [v6][outro]overlay=enable='between(t,74,${ADUR})'[v7];
    [v7][watermark]overlay=x=15:y=H-h-15:enable='between(t,18,64)'[vout];

    # Audio fade-out
    [8:a]afade=t=out:st=$(echo \"$ADUR - 0.5\" | bc):d=0.5[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset slow -crf 18 \
  -c:a aac -b:a 192k \
  -t "$ADUR" \
  -movflags +faststart \
  "$OUTPUT"
```

## Alpha Fades

```
fade=t=in:st=6:d=0.5:alpha=1      # Fade in at t=6 over 0.5s
fade=t=out:st=13:d=0.5:alpha=1    # Fade out at t=13 over 0.5s
```

The `alpha=1` flag makes the fade affect transparency rather than brightness. This is critical for overlays.

## Overlay Timing

```
overlay=enable='between(t,START,END)'
```

`t` is the timestamp in the output video. Overlays are chained: `[base][slide1]overlay...[v1]; [v1][slide2]overlay...[v2];`

The overlay window must encompass the full fade-in and fade-out range for the slide.

## Watermark

```
[N:v]scale=120:-1,format=rgba,colorchannelmixer=aa=0.15[watermark];
[vN][watermark]overlay=x=15:y=H-h-15:enable='between(t,18,64)'[vout];
```

- Scale to 120px wide, auto height
- `colorchannelmixer=aa=0.15` sets 15% opacity
- Position: bottom-left with 15px margin
- Only visible during demo portions (not during slide overlays)

## Audio Fade

```
[N:a]afade=t=out:st=$(echo "$ADUR - 0.5" | bc):d=0.5[aout]
```

Fade out the last 0.5 seconds of audio for a clean ending.

## Encoding

- `libx264 -preset slow -crf 18` — high quality H.264
- `aac -b:a 192k` — good audio quality
- `-movflags +faststart` — optimize for web streaming

## Duration Calculation

```bash
ADUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$AUDIO")
ADUR_INT=${ADUR%.*}
```

The audio duration drives the total video length. Use `-t "$ADUR"` to trim to exact audio length.

## Debugging with Frame Extraction

```bash
# Extract frames at 4fps to verify specific transitions
ffmpeg -ss 0 -t 20 -i output/explainer-video.mp4 -vf "fps=4" /tmp/frames/f_%03d.png

# Check a specific timestamp
ffmpeg -ss 6.5 -i output/explainer-video.mp4 -frames:v 1 /tmp/check.png
```

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Slide doesn't appear at all | Short `-loop 1 -t` duration exhausted | Use `-loop 1 -t "$ADUR"` for ALL inputs |
| Form bleeds through between slides | Simultaneous crossfade | Stagger: incoming fade-in starts 0.5s before outgoing fade-out |
| Ghost/double content during transition | Both slides semi-transparent | Same stagger fix as above |
| Fade timestamps wrong | Using relative times | Use absolute output timeline timestamps |
| Grainy logo | PNG scaled up | Use inline SVG instead |
