# Design guidelines

Barry Launcher apps share one small screen under a thumb, below a game. These
guidelines keep them comfortable to use and make them feel like part of
Barry Launcher. They're advice, not rules.

## The screen

- **1240 × 1080 pixels** on the Thor, about 3.9 inches across: roughly
  **420 pixels per inch**, so text that looks big on a monitor is small
  here.
- **Landscape**, held in both hands below the top screen. Thumbs reach the
  sides and the bottom most easily; the top centre is the stretch.
- **AMOLED:** black pixels are off. A black background saves battery and
  looks like part of the device.

## Sizes

All at `barry.scale` = 1:

| | |
| --- | --- |
| Smallest button | **90 × 90** (a fingertip). Give buttons people press a lot 120+. |
| Space between buttons | 14–20 |
| Margins at the screen's edges | 40 |
| Body text | 28–34 |
| Labels on buttons | 32–40, demibold |
| Titles | 56–72, bold |
| Corner radius | 24 for buttons, 36–40 for big panels |

## Colours

Barry Launcher's own palette:

| | | |
| --- | --- | --- |
| Background | `black` | ![#000000](https://placehold.co/24x24/000000/000000.png) |
| Panels, buttons | `#1b1d24` | ![#1b1d24](https://placehold.co/24x24/1b1d24/1b1d24.png) |
| Borders | `#3a3e4d` | ![#3a3e4d](https://placehold.co/24x24/3a3e4d/3a3e4d.png) |
| Pressed | `#4a4f60` | ![#4a4f60](https://placehold.co/24x24/4a4f60/4a4f60.png) |
| Accent (selected, main action) | `#6b2fb3` | ![#6b2fb3](https://placehold.co/24x24/6b2fb3/6b2fb3.png) |
| Accent, light (outlines, highlights) | `#8a5cf0` | ![#8a5cf0](https://placehold.co/24x24/8a5cf0/8a5cf0.png) |
| Text | `#eef0f4` | ![#eef0f4](https://placehold.co/24x24/eef0f4/eef0f4.png) |
| Icons, figures | `#cfe0ff` | ![#cfe0ff](https://placehold.co/24x24/cfe0ff/cfe0ff.png) |

Secondary text is the text colour at 50–75 % opacity.

## Type

**Noto Sans** is on every PB-OS device; use `font.family: "Noto Sans"`.
For another font, put the file in your app and load it:

```qml
FontLoader { id: display; source: "fonts/MyDisplayFont.ttf" }
Text { font.family: display.name }
```

## Touch

- **Show the press:** change a button's colour while `pressed`. A tap
  with no feedback feels missed.
- **Tap on release**, and only inside the button
  (`gesturePolicy: TapHandler.ReleaseWithinBounds`), so a finger that
  slides away cancels.
- **No hover:** a finger has no hover. Nothing should depend on it.
- **Keep away from the bottom edge** for swipes: a swipe up from the bottom
  45 pixels goes home.
- **Long-press and drag** are fine; explain them on screen the first time.

## Motion

- Short and purposeful: **150–450 ms**. Ease out (`Easing.OutCubic`) for
  things arriving; `Easing.OutBack` gives a small, friendly overshoot.
- Never animate forever when nothing is happening: a game runs on the same
  GPU.

## Icons

- **Square**, SVG (best) or PNG (256 × 256 or bigger).
- Barry Launcher's icons are **line art**: light lines (`#cfe0ff`) about
  1.4 units wide on a 24-unit grid, round caps, no background (the tile
  draws it). [Tabler Icons](https://tabler.io/icons) (MIT) are in that
  style and make good starting points; Barry's own Firefox, Discord and
  Signal outlines come from it.
- A full-colour icon is fine too: keep its own background inside the
  shape, since the tile is dark grey.

## Copy

- Short labels, verbs on buttons ("Roll", "Save", "Add note").
- Say what happened ("Saved.") and, for errors, what to do next.
