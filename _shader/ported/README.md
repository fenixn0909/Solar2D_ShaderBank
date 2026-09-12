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

## Genre-VFX originals (batch 4)

25 more, same sourcing policy as batches 2-3 (original GLSL, no copied
Unity/Asset-Store/2DFX code) but pulled from a wider net of AAA/top-tier-
indie 2D VFX tropes rather than any one engine's shipped shaders - loot
rarity shimmer, chain lightning, energy shields, and similar genre staples
that don't trace to one single canonical implementation. Checked against
every kernel that existed at the time these were written (the 345 original
+ this folder's batches 2 and 3) before writing any of these; where a new
kernel sits close to an existing one in technique or theme, that file's own
header calls out the difference explicitly.

| File | Kernel ID | Effect |
|---|---|---|
| `kernelG_FX_auroraBorealis2D.lua` | `generator.FX.auroraBorealis2D` | Flowing multi-band aurora curtain |
| `kernelG_FX_magicRuneCircle.lua` | `generator.FX.magicRuneCircle` | Rotating concentric rune circle, no art required |
| `kernelG_FX_chainLightningArc.lua` | `generator.FX.chainLightningArc` | Jittery bolt between two arbitrary points (Tesla arc / chain lightning) |
| `kernelG_FX_energyShieldDome.lua` | `generator.FX.energyShieldDome` | Fresnel shield dome with a settable impact ripple (standalone, not sprite-hugging - see note below) |
| `kernelG_FX_radiantHalo.lua` | `generator.FX.radiantHalo` | Rotating holy halo ring + radial spokes |
| `kernelG_FX_voidRiftTear.lua` | `generator.FX.voidRiftTear` | Jagged torn slit into a small starfield void |
| `kernelG_FX_circuitPulse.lua` | `generator.FX.circuitPulse` | Tron-style glowing circuit grid with travelling pulses |
| `kernelG_FX_arcaneSmoke.lua` | `generator.FX.arcaneSmoke` | Contained, domain-warped curse/magic smoke tendrils |
| `kernelG_FX_moltenCracks.lua` | `generator.FX.moltenCracks` | Glowing lava-vein Voronoi rock material |
| `kernelG_FX_emberDrift.lua` | `generator.FX.emberDrift` | Rising layered embers/ash with wobble and twinkle |
| `kernelG_FX_gemSparkle.lua` | `generator.FX.gemSparkle` | Multi-point twinkling star-glints for gems/loot |
| `kernelG_FX_overchargeCore.lua` | `generator.FX.overchargeCore` | Charging energy core with Charge-driven corona instability |
| `kernelG_FX_sandstormDrift.lua` | `generator.FX.sandstormDrift` | Horizontal streaking sand/dust particles + haze |
| `kernelG_FX_spiritWisp.lua` | `generator.FX.spiritWisp` | Wandering soul wisp with a closed-form fading trail |
| `kernelC_FX_subsurfaceGlow2D.lua` | `composite.FX.subsurfaceGlow2D` | Thickness-map-driven fake subsurface backlight glow |
| `kernelC_FX_prismGemRefraction.lua` | `composite.FX.prismGemRefraction` | Height-map refraction with per-channel chromatic dispersion |
| `kernelC_FX_silkAnisoSheen.lua` | `composite.FX.silkAnisoSheen` | Kajiya-Kay-style anisotropic silk/cloth sheen |
| `kernelF_UI_rarityGlow.lua` | `filter.UI.rarityGlow` | Loot-rarity edge glow + diagonal shine sweep |
| `kernelF_FX_wireframeReveal.lua` | `filter.FX.wireframeReveal` | Holographic wireframe mesh + scanline reveal |
| `kernelF_FX_toonCelShade.lua` | `filter.FX.toonCelShade` | Posterized cel-shade bands + ink outline for pre-shaded art |
| `kernelF_pixel_asciiTerminal.lua` | `filter.pixel.asciiTerminal` | Procedural (font-free) ASCII-density terminal look |
| `kernelF_FX_stainedGlassMosaic.lua` | `filter.FX.stainedGlassMosaic` | Voronoi stained-glass panes with dark leading |
| `kernelF_FX_chronoFreeze.lua` | `filter.FX.chronoFreeze` | Origin-centered time-stop: facets + radiating cracks |
| `kernelF_FX_obsidianGloss.lua` | `filter.FX.obsidianGloss` | Glossy wet/obsidian material sheen + grain |
| `kernelF_UI_xrayVision.lua` | `filter.UI.xrayVision` | Detective-mode X-ray silhouette (rim + scan hatch) |

### Worth knowing before you lean on these (batch 4)

- **`energyShieldDome` vs. the newer `forceField` (batch 3):** both are
  shield/barrier effects and both cite the same Unity Force-Field asset
  category, but they're mechanically different - `forceField` is a filter
  that hugs whatever silhouette CoronaSampler0 already has;
  `energyShieldDome` is a generator with its own independent circular
  radius (a free-standing bubble/ward, not tied to any sprite's outline)
  plus a settable `Impact_X/Y/Time` ripple that `forceField` doesn't have.
  Use `forceField` to wrap an existing sprite, `energyShieldDome` for a
  standalone shield object with impact feedback. Kept both rather than
  picking one since they solve genuinely different layout problems.
- **Two need a second texture:** `subsurfaceGlow2D` needs a grayscale
  thickness map in CoronaSampler1 (white = thin/translucent);
  `prismGemRefraction` needs a grayscale height/facet map; `silkAnisoSheen`
  needs a fiber-direction map encoded like a normal map's RG channels. All
  three fall back to looking flat/wrong on an arbitrary second image - they
  need a map actually authored for the purpose, same caveat as
  `normalMap2D` in batch 2.
- **A few expect a per-frame value from your own game code, not just a
  static art asset:** `energyShieldDome`'s `Impact_Time` (seconds since
  last hit - keep it negative for "no ripple"), `overchargeCore`'s
  `Charge` (0-1 ability-charge progress), and `chronoFreeze`'s
  `Freeze_Amount` (0-1 on/off) are all meant to be driven live, not left at
  their defaults.
- **Deliberately distinguished from existing/adjacent kernels:** see each
  file's own header for specifics, but in short - `voidRiftTear` has a
  hard torn silhouette rather than a full-frame UV swirl like
  `vortexOverlay`/`vortexShrink`/`aetherialFlow`; `arcaneSmoke` is a tight,
  object-attached tendril cloud rather than a screen-filling weather
  system like the `cloud` group; `moltenCracks` and `stainedGlassMosaic`
  both use Voronoi cells like `frostbite`/`crackOverlay` but for a static
  glowing-rock material and a flat-colored mosaic respectively, not a
  spreading damage animation; `toonCelShade` posterizes already-shaded art
  rather than computing lighting from a normal map like `normalMap2D`;
  `chainLightningArc` connects two independent points rather than
  anchoring one bolt to the sprite's own center like
  `lightning2D`/`lightningNature`.
- **Performance:** heaviest is `moltenCracks`/`stainedGlassMosaic`/
  `chronoFreeze` at a 3x3 (9-tap) Voronoi search - the same cost class as
  this bank's existing `frostbite`/`crackOverlay`. Everything else in this
  batch is a compile-time-bounded loop of 10 iterations or fewer, or no
  loop at all.

## Genre-VFX originals (batch 5)

25 more, same policy as batches 2-4 (original GLSL, nothing copied).
Checked against all 382 kernels that existed as of this batch's own
starting point (the 345 original + batches 2-4 + the standalone
`kernelF_color_posterize.lua` and the retuned `kernelF_BG_starFieldDreamy.lua`)
before finalizing. This batch leans further into retro print/animation
styles, additional water variety, sci-fi HUD elements, and small ambient
nature/weather beats that hadn't been covered yet.

**Bugfix included:** a prior commit in this same patch series fixes
`kernelG_FX_emberDrift.lua` (batch 4) - its embers were drifting *down*
instead of rising, a sign error in the vertical scroll term. One
character (`-` to `+`). Re-verified the scroll direction algebraically
(not just by eyeballing it) for every directional-motion kernel in this
batch too - see each file's own logic for `sakuraPetals` (falls),
`waterfallCascade` (falls), and `sandstormDrift`/`matrixCodeRain`
(horizontal, no up/down claim to get wrong).

| File | Kernel ID | Effect |
|---|---|---|
| `kernelG_FX_matrixCodeRain.lua` | `generator.FX.matrixCodeRain` | Falling digital-rain columns, font-free |
| `kernelG_UI_radarSweep.lua` | `generator.UI.radarSweep` | Rotating radar/sonar sweep with blips |
| `kernelG_FX_sakuraPetals.lua` | `generator.FX.sakuraPetals` | Falling, tumbling cherry-blossom petals |
| `kernelG_FX_fireflyDrift.lua` | `generator.FX.fireflyDrift` | Wandering bioluminescent fireflies that flash on independent cycles |
| `kernelG_FX_meteorShower.lua` | `generator.FX.meteorShower` | Streaking shooting stars with tapered tails |
| `kernelG_FX_rainbowArc.lua` | `generator.FX.rainbowArc` | Seven-band rainbow arc sitting on a horizon |
| `kernelF_FX_halftoneComic.lua` | `filter.FX.halftoneComic` | Comic-book Ben-Day dot halftone |
| `kernelF_FX_risoGrain.lua` | `filter.FX.risoGrain` | Risograph-style two-ink duotone misregistration |
| `kernelF_FX_watercolorBleed.lua` | `filter.FX.watercolorBleed` | Noise-bled edges + pigment pooling |
| `kernelF_FX_claymationJitter.lua` | `filter.FX.claymationJitter` | Stop-motion frame-hold jitter/flicker/grain |
| `kernelG_FX_spiderWebDew.lua` | `generator.FX.spiderWebDew` | Radial spider web with twinkling dew drops |
| `kernelF_FX_puddleReflection.lua` | `filter.FX.puddleReflection` | Wet-ground mirrored reflection with ripple |
| `kernelG_FX_whirlpoolVortex.lua` | `generator.FX.whirlpoolVortex` | Differential-rotation whirlpool funnel + foam rings |
| `kernelG_FX_waterfallCascade.lua` | `generator.FX.waterfallCascade` | Falling water columns + foam pool + mist |
| `kernelG_FX_geyserErupt.lua` | `generator.FX.geyserErupt` | Cyclic eruption column with spray and falling droplets |
| `kernelF_FX_icicleDrip.lua` | `filter.FX.icicleDrip` | Hanging icicles with dripping tips |
| `kernelG_FX_iceShardBurst.lua` | `generator.FX.iceShardBurst` | Progress-driven radial ice-shard burst |
| `kernelG_FX_enchantTrail.lua` | `generator.FX.enchantTrail` | Data-driven 5-point rune-glyph trail (feeds real object positions) |
| `kernelF_FX_shadowVeinsCreep.lua` | `filter.FX.shadowVeinsCreep` | Branching corruption veins from an origin point |
| `kernelF_UI_lowHealthPulse.lua` | `filter.UI.lowHealthPulse` | Health-driven heartbeat vignette warning |
| `kernelG_UI_questBeacon.lua` | `generator.UI.questBeacon` | Bobbing waypoint marker with light column |
| `kernelF_FX_holoDataScan.lua` | `filter.FX.holoDataScan` | Scrolling sci-fi data-readout overlay |
| `kernelG_FX_bioluminescentPulse.lua` | `generator.FX.bioluminescentPulse` | Staggered expanding organic pulse rings |
| `kernelG_FX_frozenBreathFog.lua` | `generator.FX.frozenBreathFog` | Small looping cold-breath puff |
| `kernelF_FX_paperCutoutShadow.lua` | `filter.FX.paperCutoutShadow` | Paper-craft soft offset shadow + shared grain |

### Worth knowing before you lean on these (batch 5)

- **Two are meant to be driven by real per-frame game data, not just art:**
  `enchantTrail`'s five points are UV positions you update from Lua with an
  object's actual recent path (unlike `spiritWisp` in batch 4, which fakes
  its trail with a closed-form wander and needs no input); `iceShardBurst`'s
  `Progress` and `lowHealthPulse`'s `Health` are also meant to be live
  values, not static art-time settings.
- **`whirlpoolVortex` vs. this bank's UV-swirl kernels:** deliberately not
  built the same way as `vortexOverlay`/`vortexShrink` (which redirect a
  sampled texture's UVs) - this is a self-contained generator with real
  differential rotation and a depth gradient, so it reads as a solid
  funnel rather than a distorted photo.
- **`shadowVeinsCreep` uses a different technique on purpose:** this
  batch's Voronoi-heavy kernels (see batch 4's notes) already cover
  "spreading cell-based cracks"; this one branches jagged lines outward
  from a point instead, so not everything here leans on the same trick.
- **Performance:** no loop in this batch exceeds 10 iterations
  (`matrixCodeRain`, `meteorShower`, `spiderWebDew`, `iceShardBurst`,
  `radarSweep` all cap at 6-10). Everything else - all the water, weather,
  and print-style filters - uses direct math with no loop at all.

## Genre-VFX originals (batch 6)

10 more, same policy as batches 2-5 (original GLSL, nothing copied).
Checked against all 407 kernels that existed as of this batch's own
starting point (345 original + batches 2-5) before finalizing - a full
category.group.name diff turned up zero collisions. This batch is
smaller and more exploratory than 4-5: the bank is dense enough now
that most "obvious" VFX categories are already covered several times
over, so this round leans on effects with a genuinely different
mechanic (audio-visualizer bars, day-night sky cycling, wetness-mask
compositing) instead of another reskin of an existing technique.

| File | Kernel ID | Effect |
|---|---|---|
| `kernelF_UI_thermalVision.lua` | `filter.UI.thermalVision` | FLIR-style false-color heat-vision remap |
| `kernelF_FX_pencilSketch.lua` | `filter.FX.pencilSketch` | Tone-driven cross-hatch pencil/charcoal line art |
| `kernelG_BG_meadowWind.lua` | `generator.BG.meadowWind` | Procedural wind-blown grass field, two density layers |
| `kernelG_FX_stormCloudFlash.lua` | `generator.FX.stormCloudFlash` | Thunderhead mass lit by internal flashes, no bolt lines |
| `kernelG_BG_bokehDrift.lua` | `generator.BG.bokehDrift` | Soft drifting gaussian bokeh discs, two-layer parallax |
| `kernelG_BG_dayNightCycle.lua` | `generator.BG.dayNightCycle` | Full day-night sky gradient cycle with arcing sun/moon |
| `kernelG_FX_butterflyDrift.lua` | `generator.FX.butterflyDrift` | Wandering paired-wing butterflies with iridescent hue shift |
| `kernelG_UI_equalizerBars.lua` | `generator.UI.equalizerBars` | Fake-spectrum audio-visualizer bars with falling peak caps |
| `kernelF_trans_inkSpread.lua` | `filter.trans.inkSpread` | Staggered organic ink-diffusion scene transition |
| `kernelC_FX_wetSurfaceSheen.lua` | `composite.FX.wetSurfaceSheen` | Wetness-mask-driven darkening + moving specular sheen |

### Worth knowing before you lean on these (batch 6)

- **`kernelF_trans_inkSpread.lua` lives outside this folder on purpose:**
  it's physically in `_shader/filter_trans/`, not `_shader/ported/filter/`,
  because no `_shader/ported/filter_trans/` path exists in `main.lua`'s
  loader (nothing scans it - see the loader's path-list comments) and
  every other transition kernel already uses the older 4-slot
  `kernel.vertexData`/`CoronaVertexUserData` mechanism rather than this
  bank's newer mat4 `uniformData` convention, which is almost certainly
  what actually wires up to composer's progress feed. It's listed here
  anyway since it went through the same batch and collision-check
  process - it's just filed alongside its working siblings instead.
- **Two are meant to take live values from game code, same pattern as
  `enchantTrail`/`lowHealthPulse` in batch 5:** `dayNightCycle`'s
  `Time_Offset` can be driven every frame for a game-controlled clock
  (or left alone with `Cycle_Speed` > 0 for a self-playing sky);
  `wetSurfaceSheen`'s `Wetness` is meant for a rain-starting/stopping
  tween rather than a fixed art-time constant.
- **`equalizerBars`'s peak-hold cap uses no frame memory:** a real VU
  meter's peak lags and falls slowly because it remembers last frame's
  value; a single fragment invocation can't do that, so it instead
  resamples its own height function at several recent time offsets in a
  small fixed loop and keeps the max, which reads the same way without
  any persisted state.
- **Performance:** loops stay small - `stormCloudFlash`'s fbm is 4
  octaves, `bokehDrift` checks a 3x3 neighborhood (9 taps, same class as
  this bank's existing Voronoi searches), `butterflyDrift` caps at 6,
  `equalizerBars`'s peak search is 5, `inkSpread`'s seed loop is 5.
  Everything else uses direct math with no loop.

## Genre-VFX originals (batch 7)

25 more, same policy as batches 2-6 (original GLSL, nothing copied).
Checked against all 417 kernels that existed as of this batch's own
starting point (345 original + batches 2-6) - a full category.group.name
diff turned up zero collisions, and every candidate concept was also
grepped across every existing file's actual code/header text, not just
kernel names, before being finalized (this round included spot-reading
several existing files in full - `kernelG_FG_rainSnow.lua`,
`kernelF_ui_cooldown.lua`, `kernelC_FX_iridescence2d.lua` and others -
to rule out near-miss ideas that a name-only search would have missed).
This batch leans into combat/impact one-shots, racing, RPG status
effects, and a couple of small-scene UI widgets - areas with less
existing coverage than nature/fantasy VFX at this point.

| File | Kernel ID | Effect |
|---|---|---|
| `kernelG_FX_hitSparkBurst.lua` | `generator.FX.hitSparkBurst` | Radiating spark-line combat impact flash |
| `kernelG_FX_nitroFlameTrail.lua` | `generator.FX.nitroFlameTrail` | Dual-nozzle turbulent exhaust flame plumes |
| `kernelG_FX_driftSparkShower.lua` | `generator.FX.driftSparkShower` | Gravity-arced spark shower from a contact point |
| `kernelG_UI_rangeIndicatorRing.lua` | `generator.UI.rangeIndicatorRing` | Filled-radius TD/RTS range indicator, dashed rotating rim |
| `kernelG_FX_pathArrowFlow.lua` | `generator.FX.pathArrowFlow` | Flowing chevron arrows along a path direction |
| `kernelG_FX_packOpenBurst.lua` | `generator.FX.packOpenBurst` | One-shot ring + ray-burst + sparkle for loot/pack reveals |
| `kernelG_FX_springBouncePulse.lua` | `generator.FX.springBouncePulse` | Damped-spring squash/stretch bounce-pad pulse |
| `kernelG_FX_flashlightDustCone.lua` | `generator.FX.flashlightDustCone` | Spotlight cone with slow suspended dust motes |
| `kernelG_BG_rollingFogBank.lua` | `generator.BG.rollingFogBank` | Two-layer drifting ground mist with vertical falloff |
| `kernelG_FX_teleporterBeamColumn.lua` | `generator.FX.teleporterBeamColumn` | Sci-fi teleporter pad column with materialize trigger |
| `kernelG_FX_poisonBubbleDrip.lua` | `generator.FX.poisonBubbleDrip` | Rising, wobbling, popping toxin-bubble status aura |
| `kernelG_FX_stunStarsOrbit.lua` | `generator.FX.stunStarsOrbit` | Orbiting sparkle-stars stun/dizzy status |
| `kernelG_FX_curseAuraWisp.lua` | `generator.FX.curseAuraWisp` | Curling dark tendrils climbing from a curse-status point |
| `kernelG_FX_frostBreathCone.lua` | `generator.FX.frostBreathCone` | Directional icy breath-attack cone with fast streaks |
| `kernelG_FX_dandelionDrift.lua` | `generator.FX.dandelionDrift` | Wispy suspended seed-tufts drifting on the wind |
| `kernelG_UI_loadingSpinnerRing.lua` | `generator.UI.loadingSpinnerRing` | Indeterminate rotating arc spinner with fading tail |
| `kernelF_color_seasonalShift.lua` | `filter.color.seasonalShift` | Hue-gated foliage-only recolor across 4 seasons |
| `kernelF_FX_buffSparkleRise.lua` | `filter.FX.buffSparkleRise` | Alpha-edge rim + rising twinkle motes, buff status |
| `kernelF_FX_blockParryFlash.lua` | `filter.FX.blockParryFlash` | Cross-flash + expanding ring, block/parry hit-stop |
| `kernelF_FX_koFreezeVignette.lua` | `filter.FX.koFreezeVignette` | Desaturate + contrast + vignette + chroma KO freeze-frame |
| `kernelF_FX_tireSkidMarks.lua` | `filter.FX.tireSkidMarks` | Paired wobbling wheel-path skid/scuff streaks |
| `kernelF_FX_movingPlatformStripe.lua` | `filter.FX.movingPlatformStripe` | Diagonal hazard stripes with scroll + pulse |
| `kernelF_FX_neonSignFlicker.lua` | `filter.FX.neonSignFlicker` | Alpha-edge neon glow with irregular tube-flicker dropouts |
| `kernelC_FX_stainedLightThroughWindow.lua` | `composite.FX.stainedLightThroughWindow` | Colored window light projected onto a separate base scene |
| `kernelC_FX_tornPagePeel.lua` | `composite.FX.tornPagePeel` | Mask-driven curling page-corner peel with shading + shadow |

### Worth knowing before you lean on these (batch 7)

- **Verified-clear near-misses worth knowing about:** `kernelG_FG_
  rainSnow.lua` already does diagonal parallax rain streaks (so a
  "heavy rain sheet" idea was dropped rather than risk a near-dupe);
  `kernelF_ui_cooldown.lua` already masks an icon with a determinate
  radial wedge (so `loadingSpinnerRing` was deliberately built as a
  self-contained *indeterminate* spinner instead, with no icon
  dependency); `kernelC_FX_iridescence2d.lua` already covers thin-film
  holographic shimmer (so a "holographic card foil" idea was dropped).
- **Progress/Trigger-driven one-shots, not loops:** `hitSparkBurst`,
  `packOpenBurst`, `springBouncePulse`, `blockParryFlash` and
  `koFreezeVignette` all key off a static Progress/Trigger value with
  no `CoronaTotalTime` term at all - tween 0->1 from Lua, same pattern
  as batch 3's `teleport`/`stone`/`crackOverlay`. Everything else in
  this batch is `isTimeDependent` and runs on its own.
- **`teleporterBeamColumn`'s `Materialize` is separate from its idle
  animation:** the streak-scroll and base-ring pulse always run; only
  the whole column's visibility is gated by `Materialize`, so you tween
  that one value for an appear/disappear beat without touching timing.
- **Two share a cone-shape helper concept on purpose, with different
  content:** `flashlightDustCone` (slow suspended dust, ambient) and
  `frostBreathCone` (fast axial streaks, an attack) - same
  Origin/Aim_Angle/Spread framing, deliberately different motion so
  they don't read as reskins of each other.
- **Performance:** loop counts stay in this bank's usual range -
  `driftSparkShower`/`frostBreathCone` use 10, `poisonBubbleDrip`/
  `dandelionDrift`/`buffSparkleRise` use 8-12, `packOpenBurst` runs a
  12-ray loop plus an 8-sparkle loop (each with a 3-iteration pop
  loop nested only after a life > 0.82 gate), `curseAuraWisp` and
  `stunStarsOrbit`/`neonSignFlicker` use 4-8. Everything else uses
  direct math with no loop.


## AAA post-process originals (batch 8)

10 more, filter category only, aimed specifically at production-grade
post-process techniques rather than character/particle VFX. Checked
against all 417 kernels on `origin/main` as of this batch's own
starting point (345 original + batches 2-6) - zero collisions. Note:
**this batch branches from the same commit as batch 7 rather than
stacking on top of it**, since batch 7 hadn't been pushed yet when this
one started - the two are independent siblings and can be applied in
either order (or both; nothing in batch 8 overlaps batch 7, checked
against its planned kernel IDs too before writing any code).

| File | Kernel ID | Effect |
|---|---|---|
| `kernelF_FX_volumetricLightShafts.lua` | `filter.FX.volumetricLightShafts` | Classic Mitchell/GPU-Gems radial light-shaft accumulation |
| `kernelF_color_filmicSplitTone.lua` | `filter.color.filmicSplitTone` | ACES-approx filmic curve + independent shadow/highlight tint |
| `kernelF_FX_filmHalation.lua` | `filter.FX.filmHalation` | Red-shifted bloom bleed gated on clipped highlights only |
| `kernelF_FX_lensDustOverlay.lua` | `filter.FX.lensDustOverlay` | Procedural smudges + scratches, luminance-adaptive visibility |
| `kernelF_UI_nightVisionAmp.lua` | `filter.UI.nightVisionAmp` | Green-channel light amplification, dual-lens NVG mask |
| `kernelF_blur_pointFocusDOF.lua` | `filter.blur.pointFocusDOF` | Stationary point-focus depth of field, not a motion blur |
| `kernelF_FX_heroRimFresnel.lua` | `filter.FX.heroRimFresnel` | Power-curve Fresnel rim light with directional bias |
| `kernelF_FX_underwaterCaustics.lua` | `filter.FX.underwaterCaustics` | Refractive wobble + tint + scrolling caustic net, for existing art |
| `kernelF_FX_cinematicLetterbox.lua` | `filter.FX.cinematicLetterbox` | Letterbox bars + grain + grade + vignette, one cutscene toggle |
| `kernelF_FX_anamorphicLensStreak.lua` | `filter.FX.anamorphicLensStreak` | Axis-constrained bidirectional streak from in-scene highlights |

### Worth knowing before you lean on these (batch 8)

- **Verified-clear near-misses worth knowing about:** read `kernelF_FX_
  bloom.lua`, `kernelF_blur_radial.lua`, `kernelF_fxNoise_lensFlare.lua`
  and `kernelF_FX_outlineUniversal.lua` in full before finalizing this
  batch. Bloom is a plain neutral-tint 4-neighbor glow (no red shift,
  so `filmHalation` doesn't reskin it); `blur_radial` is a Progress-
  driven directional zoom-streak (motion read, not a stationary focus-
  preserving blur, so `pointFocusDOF` doesn't reskin it); `lensFlare`
  draws the classic multi-ghost circular flare along a line (not an
  axis-constrained streak, so `anamorphicLensStreak` doesn't reskin
  it); `outlineUniversal` traces a uniform-width solid silhouette line
  (not a graded Fresnel falloff, so `heroRimFresnel` doesn't reskin
  it). All four are called out by name in their respective kernel's
  own header, not just here.
- **`nightVisionAmp` vs this bank's own `thermalVision` (batch 6):**
  same "vision mode" slot but a different amplification model (single
  green channel from real luminance vs a seven-stop false-color heat
  palette) and a dual-lens binocular mask thermalVision doesn't have -
  they're meant to be genuinely different toggle-able modes, not
  palette swaps of each other.
- **`volumetricLightShafts` and `anamorphicLensStreak` are both multi-
  tap bright-pixel accumulators on purpose, with different sampling
  geometry:** light shafts converge every sample toward one Light_Pos
  (radial); the streak marches bidirectionally along one fixed
  Streak_Angle with no target point at all (axis-constrained). Real
  engines ship both as separate post-process passes for the same
  reason - they solve different problems (occluded shafts vs a lens
  artifact on any bright pixel).
- **Performance:** `volumetricLightShafts` is a 16-tap march (in line
  with `outlineUniversal`'s existing 64-tap precedent in this same
  folder); `filmHalation`, `pointFocusDOF`, `heroRimFresnel` and
  `anamorphicLensStreak` are single 8-tap rings; `lensDustOverlay` runs
  two small loops (5 smudges + 6 scratches). `filmicSplitTone`,
  `nightVisionAmp`, `underwaterCaustics` and `cinematicLetterbox` use
  direct math with no loop at all.
