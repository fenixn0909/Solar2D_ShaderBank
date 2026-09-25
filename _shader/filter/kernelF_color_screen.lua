--[[
    Screen-blend lighten filter.
    Fixed: used non-Solar2D API (u_FillSampler0/v_UserData/v_ColorScale)
    so it never rendered. Now uses Corona* API.
    Fun tweakings: Brightness (screen amount), Tint_Hue / Tint_Sat pick
    the screen color, Process blends original -> screened.
    Creator: phoenixongogo       License: MIT
]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "screen"

kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process",    default = 1,    min = 0, max = 1, index = 0, },
  { name = "Brightness", default = 0.5,  min = 0, max = 1, index = 1, },
  { name = "Tint_Hue",   default = 0.12, min = 0, max = 1, index = 2, },
  { name = "Tint_Sat",   default = 0.6,  min = 0, max = 1, index = 3, },
}

kernel.fragment =
[[
vec3 hsv2rgb_screen( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process    = CoronaVertexUserData.x;
  float Brightness = CoronaVertexUserData.y;
  float Tint_Hue   = CoronaVertexUserData.z;
  float Tint_Sat   = CoronaVertexUserData.w;

  P_COLOR vec4 tex = texture2D( CoronaSampler0, texCoord );

  vec3 tint = hsv2rgb_screen( vec3( Tint_Hue, clamp( Tint_Sat, 0.0, 1.0 ), 1.0 ) )
            * clamp( Brightness, 0.0, 1.0 );

  // Screen blend: 1 - (1 - a) * (1 - b), applied on straight color.
  float ta = max( tex.a, 0.0001 );
  vec3 straight = tex.rgb / ta;
  vec3 screened = 1.0 - ( 1.0 - straight ) * ( 1.0 - tint );
  vec3 col = mix( straight, screened, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col * tex.a, tex.a );
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel
