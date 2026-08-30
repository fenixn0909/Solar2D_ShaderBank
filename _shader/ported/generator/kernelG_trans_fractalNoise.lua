
--[[
    https://godotshaders.com/shader/fractal-noise-scene-transition/
    shadecore_dev
    February 10, 2026
    (based on "Pixelated Warped Fractal Noise" by the same author,
    Copyright Gerardo Montano 2025, MIT-style license per the source
    file's own header, plus the site's usual CC0)

    Direct port, no texture needed - pure generator, matches the
    original (only its own procedural noise, no external samplers).

    Fixed a real bug from the initial port: background_threshold and
    color_threshold looked like independent tunables and were exposed
    as separate sliders, but they aren't independent in the original -
    the author's own Godot integration code computes both FROM progress
    every frame via a Tween (background_threshold =
    abs(1-progress*2)-0.5, color_threshold = min(1,abs(-4+progress*8))
    *0.48), sweeping progress 0->0.5 to cover the screen and 0.5->1.0
    to dissipate. Leaving them as static sliders at their defaults (0
    and 0.24) meant the reveal shape was wrong at every progress value
    except by coincidence - it never properly swept across the screen.
    Both are now computed internally from Progress, matching the
    original's actual behavior; only Progress is exposed.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "trans"
kernel.name = "fractalNoise"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Speed','Pixelation_X','Pixelation_Y',
            'Zoom','Seed','Color_R','Color_G',
            'Color_B','Color_A','','',
            '','','','',
        },
        default = { 0,.1,2,2,  2,0,0,0,  0,1,0,0,  0,0,0,0, },
        min =     { 0,0,1,1,   .5,0,0,0, 0,0,0,0,  0,0,0,0, },
        max =     { 1,1,8,8,   6,10,1,1, 1,1,1,1,   1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Progress              = u_UserData0[0][0];
float Speed                  = u_UserData0[0][1];
vec2  Pixelation              = vec2( u_UserData0[0][2], u_UserData0[0][3] );
float Zoom                    = u_UserData0[1][0];
float Seed                    = u_UserData0[1][1];
vec4  Color                    = vec4( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );

// computed from Progress, matching the original's own Tween callback -
// see header
float Background_Threshold = abs( 1.0 - Progress * 2.0 ) - 0.5;
float Color_Threshold      = min( 1.0, abs( -4.0 + Progress * 8.0 ) ) * 0.48;

const mat2 mtx = mat2( vec2( 0.80, -0.60 ), vec2( 0.60, 0.80 ) );
float TIME = CoronaTotalTime;

//----------------------------------------------

float rand( vec2 n )
{
    return fract( sin( dot( n, vec2( 12.9898 + Seed, 4.1414 - Seed ) ) ) * ( 43758.5453 + Seed * 1000.0 ) );
}

float noiseFn( vec2 p )
{
    vec2 ip = floor( p );
    vec2 u = fract( p );
    u = u * u * ( 3.0 - 2.0 * u );

    float res = mix(
        mix( rand( ip ), rand( ip + vec2( 1.0, 0.0 ) ), u.x ),
        mix( rand( ip + vec2( 0.0, 1.0 ) ), rand( ip + vec2( 1.0, 1.0 ) ), u.x ), u.y );

    return res * res;
}

float fbm( vec2 p, float iTime )
{
    float f = 0.0;

    f += 0.500000 * noiseFn( p + iTime ); p = mtx * p * 2.02;
    f += 0.031250 * noiseFn( p ); p = mtx * p * 2.01;
    f += 0.250000 * noiseFn( p ); p = mtx * p * 2.03;
    f += 0.125000 * noiseFn( p ); p = mtx * p * 2.01;
    f += 0.062500 * noiseFn( p ); p = mtx * p * 2.04;
    f += 0.015625 * noiseFn( p + sin( iTime ) );

    return f / 0.96875;
}

float pattern( vec2 p, float iTime )
{
    return fbm( p + fbm( p + fbm( p, iTime ), iTime ), iTime );
}

vec4 colormap( float x, vec2 uv )
{
    x *= max( 0.0, min( -abs( Progress * 4.0 - uv.x - uv.y - 1.0 ) + 1.0, 1.0 ) * 2.0 );

    if ( x < Background_Threshold ) {
        return vec4( 0.0, 0.0, 0.0, 0.0 );
    }
    else if ( x < Color_Threshold ) {
        return mix(
            vec4( 0.0, 0.0, 0.0, 0.0 ),
            Color,
            round( ( x - Background_Threshold ) / ( Color_Threshold - Background_Threshold ) )
        );
    }
    else {
        return Color;
    }
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float iTime = TIME * Speed - Seed;

    vec2 modifier = 1.0 / ( CoronaTexelSize.xy * Pixelation );
    vec2 uv = floor( UV * modifier ) / modifier;
    float shade = pattern( uv * Zoom, iTime );

    P_COLOR vec4 COLOR = colormap( shade, uv );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

