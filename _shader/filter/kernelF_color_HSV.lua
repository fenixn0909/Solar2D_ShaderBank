--[[
  Origin Author: al1-ce
  https://godotshaders.com/shader/hsv-adjustment/

  Simple HSV adjustment.
  Fixed: the only slider (intensity) did nothing - h/s/v were
  overwritten by sin(TIME) test lines every frame. Now Hue (hue shift),
  Saturation, Value and Process (original -> graded) are real-time.
  Speed adds an optional auto hue-drift; 0 holds the grade still.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "HSV"

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Hue','Saturation','Value',
            'Speed','','','',
            '','','','',
            '','','','',
        },
        default = {
            1,0,1,1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,-1,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,2,2,
            5,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.isTimeDependent = true

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Process = u_UserData0[0][0];
float Hue     = u_UserData0[0][1];
float Sat     = u_UserData0[0][2];
float Val     = u_UserData0[0][3];
float Speed   = u_UserData0[1][0];

vec3 rgb2hsv_hsv( vec3 c )
{
    vec4 K = vec4( 0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0 );
    vec4 p = mix( vec4( c.bg, K.wz ), vec4( c.gb, K.xy ), step( c.b, c.g ) );
    vec4 q = mix( vec4( p.xyw, c.r ), vec4( c.r, p.yzx ), step( p.x, c.r ) );
    float d = q.x - min( q.w, q.y );
    float e = 1.0e-10;
    return vec3( abs( q.z + ( q.w - q.y ) / ( 6.0 * d + e ) ), d / ( q.x + e ), q.x );
}

vec3 hsv2rgb_hsv( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );

  float hueShift = Hue;
  if ( Speed > 0.01 ) { hueShift += sin( CoronaTotalTime * Speed ) * 0.5; }

  vec3 hsv = rgb2hsv_hsv( orig.rgb );
  hsv.r = fract( hsv.r + hueShift );
  hsv.g = clamp( hsv.g * Sat, 0.0, 1.0 );
  hsv.b = clamp( hsv.b * Val, 0.0, 2.0 );
  vec3 graded = hsv2rgb_hsv( hsv );

  vec3 col = mix( orig.rgb, graded, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
