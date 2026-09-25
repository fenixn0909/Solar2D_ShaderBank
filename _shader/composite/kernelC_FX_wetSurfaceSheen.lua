
--[[
    Original implementation for this bank. Simulates a surface getting
    rained on / wet: CoronaSampler1 supplies a grayscale wetness mask
    (white = puddled/soaked, black = dry), which drives two things at
    once - the albedo darkens and desaturates slightly under the mask
    (wet material reads darker, same real-world cue as a rained-on
    sidewalk), and a soft specular hotspot appears, its position
    nudged by the wetness map's own local gradient plus a gentle
    animated ripple so the highlight isn't perfectly static. Effect is
    fully masked by wetness, so dry regions are untouched.

    CoronaSampler0 = albedo. CoronaSampler1 = wetness mask (R channel).
    Wetness is a live-friendly multiplier (0 = bone dry regardless of
    the mask, 1 = full mask strength) so a rain-starting/stopping fade
    is a one-value tween, same pattern as this bank's other live-driven
    uniforms. Aspect_Ratio convention matches the rest of this bank
    (see kernelF_FX_shockwave.lua's header).

    Checked against all existing kernels first: kernelC_FX_
    silkAnisoSheen also reads a second-sampler direction map, but for
    fiber-aligned anisotropic highlighting (cloth/hair), with no
    darkening term - a different material model entirely.
    kernelF_FX_puddleReflection is a single-sampler filter that mirrors
    the image itself for a ground puddle; this has no reflection
    component and needs an authored mask, not a screen capture.
    kernelC_FX_heatHazeShimmer only distorts UVs, no albedo darkening
    or specular term. No overlap with any of the three.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "wetSurfaceSheen"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Light_X','Light_Y','Wetness','Darken_Amount',
            'Gloss_Power','Gloss_Strength','Ripple_Freq','Ripple_Speed',
            'Aspect_Ratio','Sheen_R','Sheen_G','Sheen_B',
            '','','','',
        },
        default = {
            .35,.15,1,.35,
            10,.9,40,1.2,
            1,.85,.92,1,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            1,0,5,0,
            .2,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,.8,
            40,3,200,4,
            5,1,1,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Light_X       = u_UserData0[0][0];
float Light_Y       = u_UserData0[0][1];
float Wetness       = u_UserData0[0][2];
float Darken_Amount = u_UserData0[0][3];
float Gloss_Power   = u_UserData0[1][0];
float Gloss_Strength= u_UserData0[1][1];
float Ripple_Freq   = u_UserData0[1][2];
float Ripple_Speed  = u_UserData0[1][3];
float Aspect_Ratio  = u_UserData0[2][0];
vec3  Sheen_Color   = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 albedo = texture2D( CoronaSampler0, UV );
    float wetMask = texture2D( CoronaSampler1, UV ).r * Wetness;

    vec2 texel = CoronaTexelSize.xy;
    float wC = texture2D( CoronaSampler1, UV ).r;
    float wR = texture2D( CoronaSampler1, UV + vec2( texel.x, 0.0 ) ).r;
    float wU = texture2D( CoronaSampler1, UV + vec2( 0.0, texel.y ) ).r;
    vec2 grad = vec2( wR - wC, wU - wC ) * 8.0;

    vec2 ripple = vec2(
        sin( UV.y * Ripple_Freq + CoronaTotalTime * Ripple_Speed ),
        cos( UV.x * Ripple_Freq + CoronaTotalTime * Ripple_Speed ) ) * 0.02 * wetMask;

    vec2 offsetUV = UV + grad * 0.05 + ripple;
    vec2 toLight = ( offsetUV - vec2( Light_X, Light_Y ) ) * vec2( 1.0, Aspect_Ratio );
    float distToLight = length( toLight );
    float spec = pow( clamp( 1.0 - distToLight, 0.0, 1.0 ), Gloss_Power ) * Gloss_Strength * wetMask;

    vec3 darkened = albedo.rgb * mix( 1.0, 1.0 - Darken_Amount, wetMask );
    vec3 rgb = darkened + Sheen_Color * spec * albedo.a;

    P_COLOR vec4 COLOR = vec4( rgb, albedo.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
