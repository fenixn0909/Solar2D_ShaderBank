--[[
  Origin Author: jamesfrize
  https://godotshaders.com/author/jamesfrize/

  Spherical fisheye / barrel lens for sprites.
  Rebuilt for fun: the old 4 params are gone from the driver's seat no
  more - now Process (1st) fades the lens, Strength sets the bulge,
  Zoom sets the lens radius, Center_X/Y move the lens, Wobble breathes
  the bulge over time (0 = static). Also dropped the blocky
  pixelization pass and the hardcoded screen offset, and out-of-lens
  pixels stay original (no black crop disc).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fisheye"
kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Strength','Zoom','',
            'Center_X','Center_Y','Wobble','',
            '','','','',
            '','','','',
        },
        default = {
            1,20,1,0,
            0.5,0.5,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0.5,0.3,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,40,1.4,1,
            1,1,6,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Process  = u_UserData0[0][0];
float Strength = u_UserData0[0][1];
float Zoom     = u_UserData0[0][2];
vec2  Center   = vec2( u_UserData0[1][0], u_UserData0[1][1] );
float Wobble   = u_UserData0[1][2];

vec2 distort_fh( vec2 p, float distortion )
{
  float d = length( p );
  float z = sqrt( max( distortion * ( 1.0 - d * d ), 0.001 ) );
  float r = atan( d, z ) / 3.1415926535;
  float phi = atan( p.y, p.x );
  return vec2( r * cos( phi ), r * sin( phi ) );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    vec4 orig = texture2D( CoronaSampler0, texCoord );

    float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
    float distortion = clamp( Strength, 0.1, 40.0 );
    if ( Wobble > 0.01 ) { distortion += sin( CoronaTotalTime * 2.0 ) * Wobble; }
    distortion = clamp( distortion, 0.1, 40.0 );

    vec2 pc = ( texCoord - Center ) * vec2( 2.0 * aspect, 2.0 );
    float d = length( pc );

    vec4 warped = orig;
    if ( d < Zoom )
    {
        vec2 w = Center + distort_fh( pc, distortion ) * vec2( 1.0 / aspect, 1.0 );
        warped = texture2D( CoronaSampler0, w );
    }

    vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel


--[[

--]]
