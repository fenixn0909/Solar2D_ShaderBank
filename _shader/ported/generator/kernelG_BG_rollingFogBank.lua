
--[[
    Original implementation for this bank. A big, slow-drifting ground
    mist layer for ambience (forest/graveyard/dawn scenes) - two fbm
    bands scrolling horizontally at different speeds/scales for a
    cheap parallax read, with a soft vertical falloff so it's densest
    at Fog_Height and thins out above it, rather than filling the
    whole frame evenly.

    Checked against all existing kernels first: kernelF_FX_retroFog is
    a Godot-ported dithered *lighting/occlusion* system (lights,
    obstructors, bayer quantization) - a completely different
    mechanic aimed at 2D shadow-casting, not a visual mist layer;
    kernelG_FX_frozenBreathFog is a tiny looping personal breath puff,
    not an environment-scale layer; kernelC_FX_fogOfWar is a reveal-
    mask (hides/shows areas), not an atmospheric visual. None overlap
    with a drifting environmental mist bank.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "rollingFogBank"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Fog_Height','Speed1','Speed2','Scale',
            'Density','Color_R','Color_G','Color_B',
            'Softness','Opacity','','',
            '','','','',
        },
        default = {
            .4,.015,.03,3,
            .6,.85,.88,.9,
            .3,.85,0,0,
            0,0,0,0,
        },
        min = {
            .05,-.1,-.1,.5,
            0,0,0,0,
            .05,0,0,0,
            0,0,0,0,
        },
        max = {
            .8,5,5,8,
            1,1,1,1,
            .6,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Fog_Height  = u_UserData0[0][0];
float Speed1      = u_UserData0[0][1];
float Speed2      = u_UserData0[0][2];
float Scale       = u_UserData0[0][3];
float Density     = u_UserData0[1][0];
vec3  Fog_Color   = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Softness    = u_UserData0[2][0];
float Opacity     = u_UserData0[2][1];

//----------------------------------------------

P_RANDOM float fog_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 12.9, 78.2 ) ) ) * 43758.5453123 );
}

P_RANDOM float fog_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( fog_hash( i ), fog_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( fog_hash( i + vec2( 0.0, 1.0 ) ), fog_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float fog_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 4; i++ )
    {
        total += fog_noise( p ) * amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p1 = vec2( UV.x * Scale + CoronaTotalTime * Speed1, UV.y * Scale * 0.5 );
    vec2 p2 = vec2( UV.x * Scale * 1.7 - CoronaTotalTime * Speed2, UV.y * Scale * 0.5 + 5.0 );

    float n1 = fog_fbm( p1 );
    float n2 = fog_fbm( p2 );
    float n = ( n1 * 0.6 + n2 * 0.4 );

    float fogLine = 1.0 - Fog_Height;
    float vgrad = smoothstep( fogLine - Softness, fogLine + Softness, UV.y );

    float alpha = clamp( n * Density * vgrad, 0.0, 1.0 ) * Opacity;

    P_COLOR vec4 COLOR = vec4( Fog_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
