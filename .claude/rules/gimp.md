# Drawing with GIMP from Claude Code

How to produce drawings headlessly with GIMP 3.2 (Flatpak `org.gimp.GIMP`). Worked out 2026-09-06; three finished examples live in `~/.local/share/gimp-drawings/` and are the best starting point for any new drawing request:

| Script | What it makes | Time |
|---|---|---|
| `vector-portrait.py` | Flat vector-style illustration from filled polygons/ellipses (bricks, door, figure, martini) | ~10 s |
| `photo-to-pencil.py` | Pencil sketch *derived from a photo* via filters (desaturate / invert / blur / dodge). Only use when editing the photo is acceptable | ~15 s |
| `pencil-portrait.py` | Line-based pencil sketch drawn **from scratch** with the paintbrush: contours, hatching, scribble fills. Photo used only for landmark coordinates | ~60 s |
| `tonal-portrait.py` | **Current best.** Value-first graphite portrait from scratch: feathered tone fills + soft airbrush modelling + tone-driven hatching + selective line work. Env-tunable (see below) | ~3 min |

Run any of them with `~/.local/share/gimp-drawings/run.sh <script>`; each exports to `~/dl/<name>.png`. Preview the PNG with the Read tool, then iterate — expect 2–3 passes.

## Invocation

```bash
flatpak run org.gimp.GIMP -n -i -c --quit --batch-interpreter=python-fu-eval -b "$(cat script.py)" > run.log 2>&1
```

- `--quit` is mandatory. Without it GIMP idles forever after the batch; `Gimp.quit()` is deprecated and errors.
- `-c` routes messages to the console. Piping through `tail`/`grep` shows nothing until exit, so log to a file.
- Flatpak sandbox has `host` filesystem access: read/write `~/...` paths directly. Python is 3.13; `random`/`math` are available, no third-party modules.
- Errors are Python tracebacks in the log with `File "<string>", line N` — N is the line in your script. Grep for `Traceback|Error|line [0-9]+, in`.
- Several `-b` scripts can be chained in one launch (`-b "$(cat a.py)" -b "$(cat b.py)"`).

## GIMP 3 Python API cheat sheet

```python
import gi, random, math
gi.require_version('Gimp', '3.0'); gi.require_version('Gegl', '0.4')
from gi.repository import Gimp, Gegl, Gio

img = Gimp.Image.new(W, H, Gimp.ImageBaseType.RGB)
layer = Gimp.Layer.new(img, "name", W, H, Gimp.ImageType.RGBA_IMAGE, 100, Gimp.LayerMode.NORMAL)
img.insert_layer(layer, None, 0); layer.fill(Gimp.FillType.TRANSPARENT)

Gimp.context_set_foreground(Gegl.Color.new("#hex"))
img.select_polygon(Gimp.ChannelOps.REPLACE, [x1, y1, x2, y2, ...])   # flat float list
img.select_ellipse(op, x, y, w, h); img.select_rectangle(op, x, y, w, h)
img.get_selection().feather(img, radius); Gimp.Selection.none(img)
layer.edit_fill(Gimp.FillType.FOREGROUND)          # fill selection

# GEGL filter on a layer (property names are the GEGL ones)
f = Gimp.DrawableFilter.new(layer, "gegl:gaussian-blur", "blur")
f.get_config().set_property("std-dev-x", 9.0); layer.merge_filter(f)

# painting
Gimp.context_set_brush(Gimp.Brush.get_by_name("Pencil 01"))
Gimp.context_enable_dynamics(False)                # no context_set_dynamics; dynamics fade strokes otherwise
Gimp.context_set_brush_size(4.0); Gimp.context_set_opacity(70.0)
Gimp.context_set_brush_force(1.0); Gimp.context_set_brush_spacing(0.04)
Gimp.paintbrush_default(layer, [x1, y1, x2, y2, ...])   # polyline stroke; respects selection

# I/O
img = Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path(p))
img.flatten(); Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, img, Gio.File.new_for_path(out), None)   # no file_export
```

Gotchas hit so far: `gegl:noise-rgb` has no `gray` property (use `independent=False`); `Gimp.file_export` does not exist; `Gimp.Path` strokes work too (`stroke_new_from_points(PathStrokeType.BEZIER, ctrl, False)` + `layer.edit_stroke_item(path)`) but `paintbrush_default` is simpler for hand-drawn looks. Useful brushes: `Pencil 01/02/03`, `Charcoal 01`, `Hatch Pen 01`, `2. Hardness 050/075`; list with `Gimp.brushes_get_list('')`.

## Technique: pencil drawing from scratch

Structure of `pencil-portrait.py`, reusable for any subject:

1. **Paper**: fill `#f6f1e6`, add a 30% OVERLAY layer of grey with `gegl:noise-rgb` for tooth, then a transparent "graphite" layer for strokes.
2. **Helpers**: `line(pts, jitter)` adds Gaussian jitter to each point; `smooth()` is Catmull-Rom densification; `sketchy()` draws 3 passes at decreasing jitter (searching lines); `ell_pts()` for arcs; `hatch(poly, angle, spacing, size, opacity, feather)` selects the polygon, feathers it, then paints parallel lines across its bbox; `scribble(poly, count, len, size, opacity, angle, spread)` paints random short strokes inside a region (hair, beard, iris).
3. **Layout**: work in the reference photo's pixel coordinates (canvas = photo size) so landmarks can be read straight off it — face outline, eye centers, nose tip, mouth, collar points, hand, glass rim. Use the photo *only* for coordinates when the user wants an original drawing.
4. **Order**: background (faint bricks/door, clipped with a figure-silhouette polygon via `ChannelOps.SUBTRACT`) → table/props → body contours → tie/hatching → head contours → hair (scribble fill + curl loops along the hairline arc) → brows/eyes/nose/mouth → beard scribbles → shading hatches.
5. **Calibration**: textured brushes deposit little pigment — the `pen()` helper multiplies size ×1.5 and opacity ×2.4 for graphite strokes. First pass will look like a faint underdrawing otherwise. Always feather shading selections (6–10 px; 40 px for large soft wall tone) or the fills read as boxes.
6. **Reserving light details on dark fills** (flowers on the tie): paint them in paper color on top with 100% opacity, then a thin outline.

## Technique: value-first graphite (most realistic so far)

`tonal-portrait.py`, 2026-09-06. Result: `~/dl/portrait-pencil-v2.png`; the experiment series is in `~/dl/gimp-tests/tonal-*.png` (A/B/C = first attempts, 4/7 = good, 5/6 = contrast bug).

Layer stack: `paper` (fill `#f4efe4`) → `grain` (grey + `gegl:noise-rgb`, OVERLAY 25%) → `tone` (transparent, **MULTIPLY**) → `strokes` (hatching) → `lines` (contours/details). Flatten at the end, optional `gegl:brightness-contrast` with `contrast=1.2`.

1. **Tone first, lines last.** Build values on the `tone` layer, then let edges emerge from value contrast; draw contour lines only where the photo shows a real edge (shadow-side jaw, collar, sleeves, glass), at 30–45% opacity.
2. **Three tone tools**: `tonefill(poly, value, feather)` = select polygon → `feather` → `edit_fill` with `context_set_opacity(value*100)` (edit_fill honours context opacity); `shade(path, size, value)` = soft airbrush stroke along a path with brush `2. Hardness 025`, **`context_set_brush_hardness(0.05)`, force 0.3**; `lift(path, size, amount)` = `Gimp.eraser_default` with the same soft brush for highlights (nose bridge, cheekbone, lower lip, hair curls, glass rim). Feather 20–90 px for skin planes, 2–8 for hard objects.
3. **Facial modelling that worked**: skin base 0.07; eye sockets 0.16 (`shade` 34 px); nose side plane 0.18 + under-nose 0.28 + nostrils 0.55; upper lip 0.42, lower lip 0.18, under-lip 0.28, lip highlight lifted; jaw→neck shadow `shade` 90 px at 0.13; shadow side of the face as `shade` strokes following temple→cheek→jaw (a feathered polygon reads as a vertical stripe); hair mass 0.95 with a 1.0 core and ~90 erased curl loops; beard 0.44 + 2200 short strokes whose opacity increases toward the jaw; moustache 0.30 + strokes; eyes = iris r13 tucked under the upper lid and **clipped to the almond selection**, pupil 0.95, radial iris strokes, 0.3 lid shadow band, catchlight dot in paper colour, brows as ~60 short angled strokes.
4. **Tone-driven hatching** (`hatch_region`): after the tone layer is done (and blurred 1.2–2 px), walk parallel line segments over a bbox, sample the tone layer at each segment midpoint with `layer.get_pixel(x, y).get_rgba()[3]` (returns a `Gegl.Color` directly, not a tuple) and paint the segment with opacity ∝ darkness. One direction per region (face 55°, body 35°, door 88°) plus a lighter cross pass at +85° only where darkness > 0.18. This is what makes it look drawn rather than airbrushed. ~10 k `get_pixel` calls + ~6 k strokes ≈ 2 min.
5. **Tunables via env** (`flatpak run --env=NAME=value ...`): `PBRUSH` (`Pencil 02` best; `Pencil 01` finer), `GAIN` (2.2), `SPACING` (4), `XGAIN` (1.0), `BLUR` (1.2), `CONTRAST` (1.2; it is a **multiplier**, 1.0 = unchanged — 0.25 washes the image out), `VARIANT`/`OUT` for the output name.
6. **Parallel experiments**: several `flatpak run org.gimp.GIMP -n ...` instances run concurrently without interfering (`-n` = new instance); launch 3 variants with different env values, `until [ -f a.png ] && [ -f b.png ]; do sleep 3; done`, then Read all PNGs and compare. Three at once cost no more wall-clock than one.

Batch-mode brush pitfalls (cost a full iteration each): context brush hardness defaults to **1.0** and overrides the brush's own softness, so every "soft" brush paints hard stamps until `context_set_brush_hardness` is lowered; `Pencil 01` at size 2–4 is nearly invisible — the `pencil()` helper multiplies size ×1.6 and opacity ×2.2.

**Round 2 (same day) — cross-contour + feature fixes**, result `~/dl/portrait-pencil-v3.png` (variant 13; experiments `tonal-9..13`, `-head.png` crops):
- `PREVIEW=1` skips hatching and most stubble (~40 s instead of ~3 min) and `CROP=1` (default) also exports a 460×560 head crop — Read the crop to judge eyes/mouth at full resolution. Iterate features on the preview crop, then confirm with full renders in parallel.
- **Cross-contour hatching**: `hatch_region` is now tile-based (30–36 px tiles); `angle` may be a function `f(x, y)`; `face_field` = `90 + 40·tanh((x−1015)/110) − 25·tanh((230−y)/80)` wraps strokes around the head like a cylinder. Stroke opacity is `(darkness ** CURVE) * 130 * GAIN` — **`CURVE` 1.5–1.8 is what keeps the lights clean**; with a linear curve the whole face and wall get scribbled over. Thresholds that worked: face `minv` 0.11, body 0.09, wall 0.15 with `gain` 0.3×, cross pass `minv` 0.24. Winner: `GAIN=2.0 SPACING=4.5 XGAIN=1.0 CURVE=1.8 PBRUSH="Pencil 02" CONTRAST=1.25`.
- Feature calibration that improved likeness: eye half-width 33/34 px, iris r 15 at 0.72 with a BLACK pupil r 7 and a darker upper crescent, sclera toned 0.08 (pure white looks startled), upper-lid line size 6 at 95%, lid-thickness line, lid shadow band 0.38; brows = 120 strokes each angled along the brow (not vertical) over a 0.5 brow mass; lip line as a thin BLACK fill, no vertical lip strokes (they read as teeth), lower lip 0.30; nostrils BLACK 0.7; nose side plane 0.24, under-nose 0.32, ball highlight lift; face side planes as `shade` strokes at 0.14 (0.09 was invisible); reflected light lifted along both jaw edges; speculars on nose tip, lower lip, forehead, cheekbone.
- `BLACK = "#0c0b0e"` via `tonefill(..., color=BLACK)` for the darkest accents (pupils, nostrils, lip line, hair core); `GR` alone tops out at mid-dark.
- Hair: rings look like doodles. Better = clumps (26 centres) with a lifted core, 7 short erased arcs (90–170°) each, plus ~160 short pencil arcs on the lines layer, on top of a 0.92 mass with a BLACK core. Still the weakest element.
- Fingers: four separate rounded polygons, each casting a `shade` onto the one below, knuckle lift, fingertip shadow.

Still weak / next: hair mass reads as a cap (needs an irregular hairline with curls breaking over the forehead and top-left highlights); ears are missing; the beard's chin patch can read as a stripe; the hand's fingers need to visibly cross the glass stem; the sleeve and torso need cylinder shading; table needs perspective. Bottleneck remains measurement by eye — see the plan discussion in the session of 2026-09-06.

Next ideas not yet tried: per-region hatch angles that follow the form (cross-contour), a second finer hatch pass only on the face, darker accents (near-black) at nostrils/pupils/hair core, a lifted rim light along the shadow-side jaw, and the hand wrapping the glass with real finger overlap.

## GIMP MCP servers (evaluated 2026-09-06, not installed)

Several exist; the most mature is [maorcc/gimp-mcp](https://github.com/maorcc/gimp-mcp) (GIMP 3.2+, ~200 stars, GPL-3, 56 tools plus `get_state_snapshot` live PNG previews, `claude mcp add gimp-mcp -- uv run --directory <dir> gimp_mcp_server.py`). Others: [abelduarte/gimp-mcp](https://github.com/abelduarte/gimp-mcp) (MIT, PDB search/call, image preview, no raw Python), [Shriinivas/gimpmcp](https://github.com/Shriinivas/gimpmcp), [martinduartemore/mcp-gimp](https://github.com/martinduartemore/mcp-gimp), [mstampfer/gimp-mcp-gateway](https://github.com/mstampfer/gimp-mcp-gateway). All need the plug-in copied into GIMP's per-user plug-ins dir, which for the Flatpak is `~/.var/app/org.gimp.GIMP/config/GIMP/3.2/plug-ins/`, and a running GIMP GUI. Benefit over batch mode: interactive sessions with live previews instead of a 1–3 min relaunch per iteration. It does not change drawing quality — the techniques above are the bottleneck — so batch mode + parallel variants was kept for now.

## Technique: vector illustration

`vector-portrait.py`: single RGB layer, everything is `poly()/ell()/rect()` = select + `edit_fill`. Draw back-to-front. Brick mortar: fill mortar color, then jittered brick rects with small gaps didn't show (unclear why) — stroking mortar lines on top with a `Gimp.Path` did. Curly hair = ~70 random dark circles around an elliptical band; beard = one thick jaw-shaped polygon (dots along the jaw look like moles).

## Technique: photo → pencil (filters only)

desaturate → duplicate, invert, gaussian blur ~9 px, layer mode DODGE, merge down → `gegl:brightness-contrast` (contrast ≈1.25) → copy with `gegl:cartoon` at 35% MULTIPLY for line definition → noise OVERLAY grain + warm paper MULTIPLY layer → flatten. Contrast ≈1.9 turns it into an ink look rather than graphite.
