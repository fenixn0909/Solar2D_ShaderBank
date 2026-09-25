--[[
  Origin Author: Vildravn
  https://godotshaders.com/shader/color-splash-show-only-one-color/

  Color splash: keep one hue, everything else goes gray.
  Rebuilt: the target color was hardcoded magenta and only Strength /
  Blend were exposed. Now Hue picks the kept color, Tolerance sets how
  wide the net is, Sat_Min ignores near-gray pixels (so white UI text
  doesn't get tinted), Invert flips to "everything BUT this color",
  and Process fades original -> splash.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "splash"

kernel.isTimeDependent = false

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Hue','Tolerance','Sat_Min',
            'Invert','','','',
            '','','','',
            '','','','',
        },
        default = {
            1,0.83,0.25,0.15,
            0,0,0,0,
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
            1,1,0.6,0.8,
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
float Hue       = u_UserData0[0][1];
float Tolerance = u_UserData0[0][2];
float Sat_Min   = u_UserData0[0][3];
float Invert    = u_UserData0[1][0];

vec3 hsv2rgb_splash( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );
}

vec3 rgb2hsv_splash( vec3 c )
{
    vec4 K = vec4( 0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0 );
    vec4 p = mix( vec4( c.bg, K.wz ), vec4( c.gb, K.xy ), step( c.b, c.g ) );
    vec4 q = mix( vec4( p.xyw, c.r ), vec4( c.r, p.yzx ), step( p.x, c.r ) );
    float d = q.x - min( q.w, q.y );
    float e = 1.0e-10;
    return vec3( abs( q.z + ( q.w - q.y ) / ( 6.0 * d + e ) ), d / ( q.x + e ), q.x );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  vec4 orig = texture2D( CoronaSampler0, texCoord );

  vec3 hsv = rgb2hsv_splash( orig.rgb );
  float dh = abs( hsv.r - Hue );
  dh = min( dh, 1.0 - dh );

  float isTarget = ( 1.0 - smoothstep( Tolerance * 0.7, Tolerance, dh ) )
                 * smoothstep( Sat_Min * 0.5, Sat_Min, hsv.g );
  isTarget = mix( isTarget, 1.0 - isTarget, clamp( Invert, 0.0, 1.0 ) );

  vec3 gray = vec3( dot( orig.rgb, vec3( 0.299, 0.587, 0.114 ) ) );
  vec3 splash = mix( gray, orig.rgb, clamp( isTarget, 0.0, 1.0 ) );
  vec3 col = mix( orig.rgb, splash, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
