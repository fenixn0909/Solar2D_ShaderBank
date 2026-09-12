
--[[
    Original implementation for this bank. Film halation: real film
    stock's clear/reflective backing layer bounces light back through
    the red-sensitive emulsion layer, so overexposed highlights bleed a
    soft red-orange halo - a distinct, recognizable look from a neutral
    bloom. An 8-tap ring samples around each pixel, gates on a high
    near-white Threshold (only genuinely clipped highlights bleed, not
    every bright pixel), and adds the result back tinted red-orange.

    Checked against all existing kernels first: kernelF_FX_bloom (a
    Godot-tutorial port) does a plain 4-neighbor glow-threshold blur
    with no color shift - it brightens, it doesn't redden. This is
    deliberately the opposite of a neutral bloom: fewer pixels qualify
    (higher threshold, true clipped-highlight gating) but the ones that
    do bleed a specific warm-red tint rather than their own color,
    which is what makes it read as film rather than a generic glow.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "filmHalation"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Radius','Threshold','Intensity','Halation_R',
            'Halation_G','Halation_B','Opacity','',
            '','','','',
            '','','','',
        },
        default = {
            .02,.82,1.1,1,
            .35,.15,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .002,.5,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            .06,.98,3,1,
            1,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Radius        = u_UserData0[0][0];
float Threshold     = u_UserData0[0][1];
float Intensity     = u_UserData0[0][2];
vec3  Halation_Tint = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Opacity       = u_UserData0[1][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec3 accum = vec3( 0.0 );
    for ( int i = 0; i < 8; i++ )
    {
        float a = float( i ) / 8.0 * 6.28318530718;
        vec2 offs = vec2( cos( a ), sin( a ) ) * Radius;
        vec3 s = texture2D( CoronaSampler0, UV + offs ).rgb;
        float sLum = dot( s, vec3( 0.299, 0.587, 0.114 ) );
        accum += s * smoothstep( Threshold, 1.0, sLum );
    }
    accum *= ( 1.0 / 8.0 );

    vec3 halation = accum * Halation_Tint * Intensity;
    vec3 finalRGB = clamp( tex.rgb + halation, 0.0, 1.0 );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
