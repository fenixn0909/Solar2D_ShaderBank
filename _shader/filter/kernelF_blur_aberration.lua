
--[[
  Origin Author: hayden
  https://godotshaders.com/author/hayden/
  
  Adjustable chromatic abberation.

  Spread determines the intensity of the effect.
  Quality determines the level of detail (tap count).
  Process blends from no effect (0) to fully applied (1).

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "aberration"

kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process", default = 1,   min = 0,  max = 1,  index = 0, },
  { name = "Spread",  default = 0.8, min = -2, max = 2,  index = 1, },
  { name = "Quality", default = 7,   min = 2,  max = 16, index = 2, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process = CoronaVertexUserData.x;
  float Spread  = CoronaVertexUserData.y;
  int   Quality = int( clamp( CoronaVertexUserData.z + 0.5, 2.0, 16.0 ) );

  vec4 orig = texture2D( CoronaSampler0, UV );

  vec3 acc = vec3( 0.0 );
  vec3 sum = vec3( 0.0 );
  vec2 offset = ( UV - vec2( 0.5 ) ) * vec2( 1.0, -1.0 );
  // constant-bound taps, gated by Quality
  for ( int i = 0; i < 16; i++ )
  {
    if ( i >= Quality ) break;
    float t = 2.0 * float( i ) / float( Quality - 1 ); // range 0.0->2.0
    vec3 slice = max( vec3( 1.0 - t, 1.0 - abs( t - 1.0 ), t - 1.0 ), 0.0 );
    sum += slice;
    vec2 slice_offset = ( t - 1.0 ) * Spread * offset;
    acc += slice * texture2D( CoronaSampler0, UV + slice_offset ).rgb;
  }
  vec3 aberr = acc / max( sum, vec3( 0.001 ) );

  vec3 col = mix( orig.rgb, aberr, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


