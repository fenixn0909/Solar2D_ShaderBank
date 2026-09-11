
--[[

  Original implementation for this bank. A scene-transition wipe where
  the incoming image bleeds in through five noise-perturbed blobs
  growing from hashed seed points, each with its own randomized start
  delay (scaled by Stagger) so blobs don't all begin/finish together -
  closer to ink or dye spreading irregularly through water than a
  clean geometric wipe. A thin darker band tracks each blob's growing
  edge (Ink_Edge) for a brief "wet edge" tint as it passes.

  Follows this folder's existing pattern rather than the rest of the
  bank's newer mat4-uniformData convention: every kernel already in
  _shader/filter_trans/ drives its "progress" uniform through the old
  4-slot kernel.vertexData / CoronaVertexUserData mechanism (see
  kernelF_trans_swirl.lua), and that's almost certainly what actually
  wires up to composer's transition-progress feed, so this stays
  consistent with every working sibling in this folder instead of
  switching mechanisms on its own. That leaves exactly 4 total slots
  (progress + 3), so Speed/Noise/Ink-color are fixed constants below
  rather than exposed uniforms - Seed, Stagger and Ink_Edge cover the
  useful tuning within that budget.

  Checked against all existing kernels first: the noise/threshold
  dissolves already here (kernelF_trans_perlin, pixelDissolve,
  randSquares, luminanceMelt, dreamy) all reveal via a per-pixel
  threshold test against a static noise field, which pops in
  independently all over the frame at once; this instead grows a
  small number of *localized* fronts outward from specific points, so
  the reveal has real spatial origin and direction. Also distinct from
  the burn family (filmBurn, rippleBurnOut, composite burn/burnOut) -
  no scorched/ember edge treatment, no single sweeping front.

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "trans"
kernel.name = "inkSpread"

kernel.vertexData =
{
  {
    name = "progress",
    default = .5,
    min = 0,
    max = 1,
    index = 0,
  },
  {
    name = "Seed",
    default = 0,
    min = 0,
    max = 20,
    index = 1,
  },
  {
    name = "Stagger",
    default = .5,
    min = 0,
    max = 1,
    index = 2,
  },
  {
    name = "Ink_Edge",
    default = .6,
    min = 0,
    max = 1,
    index = 3,
  },
}


kernel.fragment =
[[
P_DEFAULT float progress = CoronaVertexUserData.x;
P_DEFAULT float Seed     = CoronaVertexUserData.y;
P_DEFAULT float Stagger  = CoronaVertexUserData.z;
P_DEFAULT float Ink_Edge = CoronaVertexUserData.w;

const vec3 INK_COLOR = vec3( 0.05, 0.05, 0.08 );
//----------------------------------------------

P_RANDOM float ink_hash( vec2 p )
{
  return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float ink_noise( vec2 p )
{
  vec2 i = floor( p );
  vec2 f = fract( p );
  vec2 u = f * f * ( 3.0 - 2.0 * f );
  return mix( mix( ink_hash( i ), ink_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
              mix( ink_hash( i + vec2( 0.0, 1.0 ) ), ink_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float ink_blob( vec2 uv, vec2 seedPos, float startT, float t )
{
  float localT = clamp( ( t - startT ) / max( 1.0 - startT, 0.0001 ), 0.0, 1.0 );
  vec2 d = uv - seedPos;
  float dist = length( d );
  float n = ink_noise( uv * 6.0 + seedPos * 13.0 ) - 0.5;
  float radius = localT * 0.9;
  float edge = radius + n * 0.12 * localT;
  return smoothstep( edge + 0.05, edge - 0.05, dist );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  vec2 UV = texCoord;
  float t = progress;
  float reveal = 0.0;

  for ( int i = 0; i < 5; i++ )
  {
    float fi = float( i );
    vec2 seedPos = vec2( ink_hash( vec2( fi, Seed ) ), ink_hash( vec2( fi + 50.0, Seed ) ) );
    float startT = ink_hash( vec2( fi + 100.0, Seed ) ) * Stagger;
    reveal = max( reveal, ink_blob( UV, seedPos, startT, t ) );
  }
  reveal = clamp( max( reveal, step( 0.999, t ) ), 0.0, 1.0 );

  vec4 fromColor = texture2D( CoronaSampler0, UV );
  vec4 toColor = texture2D( CoronaSampler1, UV );

  float edgeBand = 4.0 * reveal * ( 1.0 - reveal ) * Ink_Edge;

  vec4 mixed = mix( fromColor, toColor, reveal );
  mixed.rgb = mix( mixed.rgb, INK_COLOR, edgeBand );

  P_COLOR vec4 COLOR = mixed;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
