--[[
  Hit-flash strobe: flips the sprite to its negative on a timer.
  Fixed: the only slider (intensity) did nothing - the flash gate was
  a hardcoded step(abs(tan(TIME*7)), ...) strobe. Now Speed sets the
  flash rate (0 = steady invert), Duty sets the on-fraction, and
  Process blends original -> inverted.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "invertFlash"

kernel.vertexData =
{
  { name = "Process", default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Speed",   default = 2,   min = 0, max = 10, index = 1, },
  { name = "Duty",    default = 0.5, min = 0, max = 1,  index = 2, },
}

kernel.isTimeDependent = true

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process = CoronaVertexUserData.x;
  float Speed   = CoronaVertexUserData.y;
  float Duty    = CoronaVertexUserData.z;

  // Speed = 0 holds a steady invert; otherwise strobe at Speed Hz
  float on = 1.0;
  if ( Speed > 0.01 ) { on = step( fract( CoronaTotalTime * Speed ), clamp( Duty, 0.0, 1.0 ) ); }

  P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
  vec3 inv = vec3( 1.0 ) * tex.a - tex.rgb;

  vec3 col = mix( tex.rgb, inv, on * clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, tex.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
