--[[
  Origin Author: Rosace
  https://godotshaders.com/shader/glow-effect-2d/

  Selective glow: bright pixels bloom into a tinted halo.
  Rebuilt: the 2 old params (progress, vd_resolution) were boring, and
  threshold/intensity/glow_color were overwritten by sin(TIME) test
  lines every frame. Removed both old params. Now Threshold picks
  which pixels glow, Intensity sets halo strength, Radius sets halo
  size, Glow_Hue tints it, and Process fades original -> glowing.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "glow"

kernel.isTimeDependent = false

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Threshold','Intensity','Radius',
            'Glow_Hue','','','',
            '','','','',
            '','','','',
        },
        default = {
            1,0.5,1.2,2,
            0.33,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1.2,4,8,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Process   = u_UserData0[0][0];
float Threshold = u_UserData0[0][1];
float Intensity = u_UserData0[0][2];
float Radius    = u_UserData0[0][3];
float Glow_Hue  = u_UserData0[1][0];

vec3 hsv2rgb_glow( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;

  vec4 src = texture2D( CoronaSampler0, UV );

  float lum = dot( src.rgb, vec3( 0.299, 0.587, 0.114 ) ) / max( src.a, 0.001 );
  float mask = smoothstep( Threshold, Threshold + 0.2, lum );

  // tinted halo from blurred neighbours
  vec2 px = CoronaTexelSize.zw * max( Radius, 0.0 );
  vec3 halo = vec3( 0.0 );
  halo += texture2D( CoronaSampler0, UV + vec2( px.x, 0.0 ) ).rgb;
  halo += texture2D( CoronaSampler0, UV - vec2( px.x, 0.0 ) ).rgb;
  halo += texture2D( CoronaSampler0, UV + vec2( 0.0, px.y ) ).rgb;
  halo += texture2D( CoronaSampler0, UV - vec2( 0.0, px.y ) ).rgb;
  halo += texture2D( CoronaSampler0, UV + px ).rgb;
  halo += texture2D( CoronaSampler0, UV - px ).rgb;
  halo += texture2D( CoronaSampler0, UV + vec2( px.x, -px.y ) ).rgb;
  halo += texture2D( CoronaSampler0, UV + vec2( -px.x, px.y ) ).rgb;
  halo /= 8.0;

  vec3 tint = hsv2rgb_glow( vec3( Glow_Hue, 0.85, 1.0 ) );
  vec3 glowing = src.rgb + tint * halo * Intensity * ( 0.25 + mask );

  vec3 col = mix( src.rgb, glowing, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, src.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
