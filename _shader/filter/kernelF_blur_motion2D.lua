--[[
  Original Author : hayden
  https://godotshaders.com/author/hayden/

  Directional motion blur for sprites.
  Fixed (round 2): the old version scaled the mesh in a custom vertex
  shader, overrode `quality` with a sin(TIME) test line every frame, had
  a junk paletteRowCols param, and used a dynamic loop bound (GLES
  compile risk). Rebuilt as a fragment-only blur: no vertex stage, no
  overrides, constant-bound taps. Params: Angle (streak direction),
  Length (streak reach in UV), Samples (tap count), Process (sharp ->
  smeared).
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "motion2D"
kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process", default = 1,    min = 0, max = 1,   index = 0, },
  { name = "Angle",   default = 45,   min = 0, max = 360, index = 1, },
  { name = "Length",  default = 0.05, min = 0, max = 0.2, index = 2, },
  { name = "Samples", default = 8,    min = 2, max = 16,  index = 3, },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process = CoronaVertexUserData.x;
  float Angle   = CoronaVertexUserData.y;
  float Length  = CoronaVertexUserData.z;
  int   Samples = int( clamp( CoronaVertexUserData.w + 0.5, 2.0, 16.0 ) );

  vec4 orig = texture2D( CoronaSampler0, texCoord );

  vec2 dir = vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) )
           * Length / float( Samples );

  vec3 acc = orig.rgb;
  float acA = orig.a;
  // constant-bound taps, gated by Samples
  for ( int i = 1; i <= 16; i++ )
  {
      if ( i > Samples ) break;
      vec2 off = dir * float( i );
      vec4 a = texture2D( CoronaSampler0, texCoord + off );
      vec4 b = texture2D( CoronaSampler0, texCoord - off );
      acc += a.rgb + b.rgb;
      acA += a.a + b.a;
  }
  float n = float( Samples ) * 2.0 + 1.0;
  vec4 blurred = vec4( acc / n, acA / n );

  vec4 outc = mix( orig, blurred, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = outc;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel
