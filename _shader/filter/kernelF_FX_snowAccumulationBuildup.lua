
--[[
    Original implementation for this bank. Modeled on the "snow /
    frost buildup" character-transform category from commercial
    character shader bundles - nothing was copied from any of them
    (all paid, closed-source). Rather than falling snow, this detects
    the sprite's own top-facing silhouette edges cheaply (comparing
    each pixel's alpha to the alpha a couple of texels above it - a
    rising edge there means something solid begins facing upward right
    at this pixel, the same alpha-gradient trick this bank's edge-aware
    kernels already use for outlines/rims) and seeds a noise-gated snow
    cap there, plus a light overall dusting that grows with Progress
    for full coverage at high Progress.

    Checked against all existing kernels first: kernelG_FG_rainSnow is
    a parallax-scrolling *falling* snow/rain generator with no input
    sprite dependency at all - it can't accumulate ON a specific
    character; kernelF_wobble_windSway2D/windSwayPurga sway an existing
    sprite's UVs, unrelated to any snow buildup. No existing kernel
    detects a sprite's own top-facing surfaces to seed accumulation.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "snowAccumulationBuildup"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Scale','Snow_R','Snow_G',
            'Snow_B','Build_Sharpness','Dusting_Amount','Seed',
            'Opacity','','','',
            '','','','',
        },
        default = {
            0,26,.96,.97,
            1,.35,.15,0,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            0,8,0,0,
            0,.1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,60,1,1,
            1,.6,.4,50,
            1,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress         = u_UserData0[0][0];
float Scale            = u_UserData0[0][1];
vec3  Snow_Color       = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Build_Sharpness  = u_UserData0[1][1];
float Dusting_Amount   = u_UserData0[1][2];
float Seed             = u_UserData0[1][3];
float Opacity          = u_UserData0[2][0];

//----------------------------------------------

P_RANDOM float snowbuild_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 44.1, 92.3 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 texel = CoronaTexelSize.xy * 3.0;
    float aAbove = texture2D( CoronaSampler0, UV - vec2( 0.0, texel.y ) ).a;
    float topFacing = clamp( ( tex.a - aAbove ) * 3.0, 0.0, 1.0 );

    float n = snowbuild_hash( floor( UV * Scale ) + Seed );
    float capMask = smoothstep( 1.0 - Progress - Build_Sharpness, 1.0 - Progress + Build_Sharpness, n ) * topFacing;

    float generalDust = Progress * Dusting_Amount * step( 0.02, tex.a );
    float snowCoverage = clamp( capMask + generalDust, 0.0, 1.0 );

    vec3 finalRGB = mix( tex.rgb, Snow_Color, snowCoverage );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
