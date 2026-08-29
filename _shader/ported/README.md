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
