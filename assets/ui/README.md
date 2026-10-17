# Bonfire — Godot UI Asset Kit

A lightweight rustic/woodland UI kit designed for the multiplayer forest campfire game.
The **PNG sprites have no baked-in labels**. Add localized labels, progress values and
inventory items using normal Godot `Control` nodes.

## Contents

- `buttons/`: normal, hover, pressed, disabled (420 × 96, transparent PNG).
- `panels/`: `panel_wood.png` and `panel_parchment.png` (760 × 600), plus a wooden heading plate.
- `slots/`: inventory and hotbar slots in normal/selected states (112 × 112).
- `bars/`: bar track and four colored fills (360 × 46); resize/crop fill by value.
- `icons/png/`: 26 transparent 128 × 128 illustrations.
- `icons/svg/`: corresponding scalable SVG originals.
- `overlays/`: 1920 × 1080 translucent menu dimmer and vignette.
- `previews/`: 4 layout demonstrations and 4 illustrated direction references.
- `references/`: 2 full illustrated concept sheets; **not sliced interactive UI**.

## Import into Godot 4

1. Copy folders into your project under `res://ui/assets/`.
2. Use `NinePatchRect` for panels, wooden headers and button backgrounds. Suggested
   patch margins: panel 44 px on every side; header 27 px horizontal / 25 px vertical;
   button 28 px horizontal / 24 px vertical. For dynamically scaling buttons,
   add a child `Label` centered on top.
3. To support hover/press/disabled states, use a `TextureButton` and assign the
   four textures (`texture_normal`, `texture_hover`, `texture_pressed`, `texture_disabled`).
   Put a `Label` child over it with `mouse_filter = Ignore`.
4. Inventory: use a `GridContainer` with a reusable `PanelContainer` or `TextureRect`
   for each slot. Place icons and small stack-count `Label`s on top; selection swaps
   the slot texture.
5. HUD: use a `HBoxContainer` for the 8 hotbar slots, anchor bottom-center. Place
   health/hunger/thirst/stamina rows top-left. For progress bars, use `TextureProgressBar`
   and assign `under_texture` to `bars/track.png`, `progress_texture` to a fill image.
6. Menus: use `CanvasLayer` + full-screen `Control` with anchors = Full Rect, place
   `overlays/menu_dimmer.png` over the 3D forest scene, then center panels and buttons.
   Set game pause process modes correctly so buttons remain clickable while paused.

## Layout recommendations

- Target a 1920 × 1080 reference canvas. Set **Project Settings → Display → Window →
  Stretch Mode** to `canvas_items`; use anchors and containers so screens scale.
- Maintain a **minimum readable label size** of around 18–24 px at the reference size.
- Buttons are 420 × 96 source pixels; typical on-screen size ~270–400 × 64–92.
- Use cream `#F4DFB4` labels, charcoal `#171914` text on hover/cream surfaces,
  moss `#809555` for success and amber `#E5B96C` for selection.
- Suggested typography: a clear serif for headings, a legible sans-serif for small
  inventory counts and settings. Use fonts you have licenses to redistribute.
- The menu scene background is intentionally not a baked image asset: your existing
  procedural forest can run behind a dim overlay, matching the actual world.

## Notes

The illustrated concept previews contain example text and inventory content. They
are **visual references**, whereas all items in `buttons`, `panels`, `slots`, `bars`,
`icons` and `overlays` are separate assets intended for direct use in Godot.
No shaders, external fonts or paid resources are required.
