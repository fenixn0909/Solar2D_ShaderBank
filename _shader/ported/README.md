# _shader/ported/

38 shaders ported from [godotshaders.com](https://godotshaders.com/) (35 CC0 + 3 MIT,
all licenses confirmed individually per source page) into this bank's kernel format.
Organized the same way as the top-level `_shader/` folder - `generator/`,
`filter/`, `composite/` - and merged into those same three category tabs at
startup (see `mC_pthG2`/`mC_pthF2`/`mC_pthC2` and the extra `shdilr.load_list(...,
true)` calls in `main.lua`'s `M.startup()`). No `filter_trans/` subfolder here
yet - nothing has landed in that category from this batch.

Every file's own header comment has the full attribution (source URL, author,
post date) plus any adaptation notes specific to that shader. This file is
just an index.

## generator/

| File | Kernel ID | Effect |
|---|---|---|
| `kernelG_trans_p5Slash.lua` | `generator.trans.p5Slash` | Persona 5-style diagonal slash wipe transition |
| `kernelG_trans_p5Square.lua` | `generator.trans.p5Square` | Persona 5-style growing-square wipe transition |
| `kernelG_FX_vignetteDither.lua` | `generator.FX.vignetteDither` | Screen vignette with dithering to avoid banding |
| `kernelG_FX_torchFlame.lua` | `generator.FX.torchFlame` | Fully procedural fire + smoke + sparks (torch/candle/campfire) |
| `kernelG_BG_starryNight.lua` | `generator.BG.starryNight` | Scintillating star field with gradient-tinted stars (hybrid uniform + optional composite texture) |
| `kernelG_BG_starryTunnel.lua` | `generator.BG.starryTunnel` | Warp tunnel of neon/dot particles with isWhite / mask modes |
| `kernelG_BG_gridScroller.lua` | `generator.BG.gridScroller` | Dark diagonal scrolling grid with central pulse (menu / loading) |
| `kernelG_BG_determinationWaves.lua` | `generator.BG.determinationWaves` | Undertale-style determination waves, 5-color palette + RGB mode |
| `kernelG_FX_starburst.lua` | `generator.FX.starburst` | Starburst with procedural spikes + glow (pulsars, suns) |

## filter/

| File | Kernel ID | Effect |
|---|---|---|
| `kernelF_FX_fire2D.lua` | `filter.FX.fire2D` | Anime-style 2-tone fire, driven by a mask texture |
| `kernelF_FX_fire2DV2.lua` | `filter.FX.fire2DV2` | V2 recolorable fire — same as fire2D but palette exposed as uniforms |
| `kernelF_FX_tilerSplatter.lua` | `filter.FX.tilerSplatter` | Randomly scattered/rotated tile splatter (decals, leaves, blood) |
| `kernelF_FX_tilerSplatterV2.lua` | `filter.FX.tilerSplatterV2` | V2 static splatter (rotation off) — cheaper variant for non-spinning scatter |
| `kernelF_FX_retroFog.lua` | `filter.FX.retroFog` | Retro dithered lighting / fog-of-war, 4 lights + 2 occluders, bayer quantized (MIT*) |
| `kernelF_FX_frostbite.lua` | `filter.FX.frostbite` | Screen-space freeze/ice overlay - voronoi cracking + vignette growth |
| `kernelF_FX_screenEdgeThreshold.lua` | `filter.FX.screenEdgeThreshold` | Cinematic letterbox bars + optional B&W threshold |
| `kernelF_FX_turnToDust.lua` | `filter.FX.turnToDust` | Dissolve / disintegration effect |
| `kernelF_FX_wallDestruction.lua` | `filter.FX.wallDestruction` | Shatter / break-apart destruction effect |
| `kernelF_FX_outlineUniversal.lua` | `filter.FX.outlineUniversal` | Multi-directional sprite outline |
| `kernelF_wobble_windSway2D.lua` | `filter.wobble.windSway2D` | Wind sway for foliage/grass |
| `kernelF_UI_progressFill.lua` | `filter.UI.progressFill` | Bottom-up fill progress/health bar |
| `kernelF_FX_shine.lua` | `filter.FX.shine` | Diagonal shine/sweep highlight |
| `kernelF_FX_shockwave.lua` | `filter.FX.shockwave` | Radial distortion + chromatic aberration shockwave |
| `kernelF_FX_panoramaPerspective.lua` | `filter.FX.panoramaPerspective` | Fake 3D panorama perspective (FNaF fangame horizontal warp) |
| `kernelF_FX_squigglePen.lua` | `filter.FX.squigglePen` | Hand-drawn squiggle pen post-process, edge + noise warp |
| `kernelF_FX_ditherClassic.lua` | `filter.FX.ditherClassic` | Classic 4×4 Bayer dithering, gamma-controlled |
| `kernelF_FX_aetherialFlow.lua` | `filter.FX.aetherialFlow` | Sine-wave + ripple + swirl flow, HSV pulse (MIT*) |
| `kernelF_FX_sphereProjection.lua` | `filter.FX.sphereProjection` | 2D sphere projection with XYZ rotation |
| `kernelF_FX_parchment.lua` | `filter.FX.parchment` | Retro parchment paper, sepia + ink bleed + dirt (CC0) |
| `kernelF_FX_sideVignette.lua` | `filter.FX.sideVignette` | Directional side vignette with convex/concave curvature |
| `kernelF_wobble_windSwayPurga.lua` | `filter.wobble.windSwayPurga` | Purga wind sway for trees/grass, top moves more than base |

## composite/

| File | Kernel ID | Effect |
|---|---|---|
| `kernelC_mask_dissolveGlow.lua` | `composite.mask.dissolveGlow` | Noise-threshold dissolve with a flat emissive glow color |
| `kernelC_trans_luminanceMask.lua` | `composite.trans.luminanceMask` | Luminance-driven mask wipe transition |
| `kernelC_FX_obliqueShadow.lua` | `composite.FX.obliqueShadow` | Raymarched top-down drop shadow from a height map |
| `kernelC_FX_fogOfWar.lua` | `composite.FX.fogOfWar` | Animated noise-based fog/vision overlay |
| `kernelC_color_paletteRemap.lua` | `composite.color.paletteRemap` | Recolor via grayscale-to-gradient lookup |
| `kernelC_FX_stylizedWater.lua` | `composite.FX.stylizedWater` | Ripple + wave-highlight water surface |
| `kernelC_deform_vertical3.lua` | `composite.deform.vertical3` | Vertical 3-section deform driven by effector position + mask (MIT*) |

## Worth knowing before you lean on these

- **Performance-heavy ones:** `frostbite` (voronoi + multi-tap blur), `wallDestruction`
  (a ~17x23 cell search per pixel), `torchFlame` (up to 512+50+50 particles per
  pixel if you push its sliders), `stylizedWater` (25 + 30-iteration loops),
  `starryTunnel` (up to 30×8=240 particles per pixel), and `retroFog`
  (4 lights × 2 obstructors with bayer8 + seg_dist per pixel) are all
  considerably more expensive than the average shader in the original
  bank. Their defaults are reasonable; their slider ceilings are not free.
- **Screen-space ones need a real screen capture:** `frostbite`, `shockwave`,
  `screenEdgeThreshold`, and `retroFog` all stand in Godot's automatic
  backbuffer texture with plain `CoronaSampler0` - feed them a
  snapshot/render-to-texture, not an arbitrary sprite.
- **Three need a specific input texture, not just any sprite:** `fire2D` /
  `fire2DV2` expect its input texture's R/G channels to encode an
  outer/inner flame mask; `tilerSplatter` / `tilerSplatterV2` sample the
  input texture as `tex_draw` tiles (both not bundled here - texture
  assets aren't covered by godotshaders.com's CC0 code license, only the
  code is). `starryNight`'s hybrid note: defaults are self-contained via
  uniform gradient lerp, but the file header shows how to swap to a
  composite sampler for custom gradient strips.
- **License split:** 35 shaders in this folder are CC0, `retroFog`, `aetherialFlow`,
  and `vertical3` are MIT (see their headers) — all permissive, keep headers.
  `luminanceMask` and `turnToDust` from the request were already ported in this
  folder (`luminanceMask` / `turnToDust`), so no duplicate was created.
- Several others carry a specific one-off simplification from their Godot
  original (dropped atlas-region support, dropped vertex-kernel bounds
  expansion, a documented bug fix, etc.) - noted in that file's own header,
  not repeated here.

## Unity-technique originals (batch 2)

Unlike the batch above, these 5 are not ports of one external source file.
Unity's own shader source carries the Unity Companion License (not freely
redistributable), and the specific Asset Store/Fab packages that popularized
several of these looks are paid and closed-source - so nothing was copied
from either. Each file is instead an original GLSL kernel implementing a
technique that's genuinely characteristic of a well-known/top-rated Unity 2D
shader category, chosen specifically because it wasn't covered anywhere else
in this bank (checked against all ~345 existing kernels first). Full
technique notes and specific reference points are in each file's own header.

| File | Kernel ID | Effect |
|---|---|---|
| `kernelC_Lit_normalMap2D.lua` | `composite.Lit.normalMap2D` | Tangent-space normal-map + point-light 2D lighting - the technique behind Unity's own URP "Sprite-Lit-Default" |
| `kernelG_water_caustics2D.lua` | `generator.water.caustics2D` | Procedural animated underwater caustics light-network overlay |
| `kernelG_FX_metaball2D.lua` | `generator.FX.metaball2D` | Procedural 2D metaballs - up to 6 self-animating blobs that merge/split |
| `kernelF_UI_liquidFillWave.lua` | `filter.UI.liquidFillWave` | Liquid fill meter with wavy surface, foam ridge and rising bubbles - fills any sprite's own shape |
| `kernelF_pixel_ledMatrix.lua` | `filter.pixel.ledMatrix` | LED/dot-matrix retro display filter, square-to-circular dot shape blend |
| `kernelF_pixel_ledMatrixV2.lua` | `filter.pixel.ledMatrixV2` | V2 sprite-masked LED — dots only where the sprite has color, gaps + empty stay transparent |

### Worth knowing before you lean on these (batch 2)

- **Needs a second texture:** `normalMap2D` is a composite effect -
  CoronaSampler1 must be an actual tangent-space normal map (a flat,
  no-bumps map is solid `(128,128,255)`), not an arbitrary second sprite.
- **Transparent by default:** `metaball2D` and `caustics2D` are generators
  meant to sit as an overlay on top of existing art - metaballs render on a
  transparent background and caustics ships with `Background_A = 0`. Raise
  the relevant alpha uniform if you want either as an opaque standalone
  background instead.
- **Deliberately not a repeat of what's already here:** `liquidFillWave`
  differs on purpose from the flat `kernelF_UI_progressFill.lua` (adds
  wave/foam/bubbles) and from the circular, fixed-shape
  `kernelG_UI_liquidSphere2D.lua` (this one is a filter that respects
  whatever silhouette CoronaSampler0's own alpha already has, so it works on
  a bar, a round gauge, or a custom potion-bottle sprite equally). Likewise
  `metaball2D` is unrelated to `kernelG_BG_bubbles.lua`'s ambient floating
  bubbles - different technique, different purpose.
- **Performance:** all six are cheap. Nothing here loops beyond a
  compile-time-bounded 6 iterations (`metaball2D`) or 3 (`caustics2D`);
  `ledMatrix`, `ledMatrixV2` and `liquidFillWave` use no loops at all.
- **LED pick:** `ledMatrix` fills the whole rect with dots over a
  `Background` color (jumbotron / terminal-screen look);
  `ledMatrixV2` keeps the sprite silhouette - empty areas and dot gaps
  stay transparent so it composites over any backdrop.

## Combat-state FX (batch 3)

Two direct CC0 ports plus three original technique implementations,
all checked against every existing kernel first - nothing here repeats
an effect the bank already has. The ports carry full attribution in
their own headers; the originals name the paid Unity/2DFX category
they reimplement (nothing copied) in theirs.

| File | Kernel ID | Effect |
|---|---|---|
| `kernelF_FX_teleport.lua` | `filter.FX.teleport` | Teleport-away dissolve sweeping bottom-to-top with a hot beam edge (pend00, CC0) |
| `kernelF_FX_burnFromPoint.lua` | `filter.FX.burnFromPoint` | Radial burn spreading from a sprite point with ember ring (enekoassets, CC0; noise texture replaced with procedural value noise) |
| `kernelF_FX_stone.lua` | `filter.FX.stone` | Petrify-to-statue: desaturate to gray rock with grain + carved top-light (original; cf. 2DFX Stone category) |
| `kernelF_FX_crackOverlay.lua` | `filter.FX.crackOverlay` | Damage fissures with ember lips spreading as Damage rises (original; cf. 2DFX Cracked Overlay) |
| `kernelF_FX_forceField.lua` | `filter.FX.forceField` | Sprite-hugging energy bubble: alpha-gradient rim + scrolling scans + pulse (original; cf. Unity Force Field packs) |

### Worth knowing before you lean on these (batch 3)

- **All progress-driven except the bubble:** `teleport` (`Progress`
  0->1), `burnFromPoint` (`Radius` 0->2), `stone` (`Progress` 0->1)
  and `crackOverlay` (`Damage` 0->1) are static/time-frozen - drive
  them with a tween like the bank's other dissolves. Only
  `forceField` animates on its own (`isTimeDependent`).
- **`burnFromPoint` epicenter is UV space:** `(0.5, 0.5)` is sprite
  center, `(0, 0)` bottom-left - matches the original's click-to-UV
  example in its header.
- **`forceField` needs padding:** the rim can only draw into
  transparent pixels already around the art - same caveat as
  `outlineUniversal`. Leave a few px margin or it clips.
- **Performance:** `teleport`, `burnFromPoint` and `stone` are
  single-tap + cheap noise; `forceField` adds 4 rim taps + noise;
  `crackOverlay` is the heaviest (3x3 Voronoi search per pixel) but
  still far below `frostbite`/`wallDestruction` territory.
