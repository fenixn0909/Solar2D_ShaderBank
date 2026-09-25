
--[[
    Original implementation for this bank. Modeled on the "liquid
    metal" character-transform category well known from commercial and
    demo shader work (the classic "T-1000" chrome-morph look) - nothing
    was copied from any specific implementation. Progress 0 -> 1
    resamples through a growing sine-wobble UV ripple (selling a fluid,
    not-solid surface), desaturates toward a cool metallic tint, and
    layers a moving diagonal specular sweep plus an alpha-edge Fresnel
    brightening (the same cheap alpha-neighbor stand-in this bank's
    kernelF_FX_obsidianGloss uses for edge light) - three independent
    cheap layers rather than one, same design approach as obsidianGloss
    but animated as a transformation instead of a fixed material.

    Checked against all existing kernels first: kernelF_FX_obsidianGloss
    is explicitly a *static* material look (no Progress arc, no ripple
    - "a fixed... hashed sparkle grain" per its own header) for
    volcanic glass, not a liquid-metal transformation; kernelC_FX_
    puddleReflection mirrors the image itself for a ground puddle, a
    different mechanic (reflection sampling vs specular/Fresnel
    shading) and a different subject (ground surface, not a character
    becoming metal). Neither transforms a character into liquid chrome.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "liquidChromeMorph"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Chrome_R','Chrome_G','Chrome_B',
            'Ripple_Amount','Ripple_Speed','Spec_Speed','Spec_Intensity',
            'Fresnel_Amount','Opacity','','',
            '','','','',
        },
        default = {
            0,.7,.75,.8,
            .012,2.5,.6,1.3,
            .6,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            .03,6,3,3,
            1.5,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress        = u_UserData0[0][0];
vec3  Chrome_Tint     = vec3( u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3] );
float Ripple_Amount   = u_UserData0[1][0];
float Ripple_Speed    = u_UserData0[1][1];
float Spec_Speed      = u_UserData0[1][2];
float Spec_Intensity  = u_UserData0[1][3];
float Fresnel_Amount  = u_UserData0[2][0];
float Opacity         = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 ripple = vec2(
        sin( UV.y * 30.0 + CoronaTotalTime * Ripple_Speed ),
        cos( UV.x * 25.0 - CoronaTotalTime * Ripple_Speed * 0.8 ) ) * Ripple_Amount * Progress;

    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV + ripple );
    P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );

    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 metallic = vec3( lum ) * Chrome_Tint * 1.4;
    vec3 baseColor = mix( tex.rgb, metallic, Progress );

    float specPos = fract( UV.x * 0.5 + UV.y * 0.5 + CoronaTotalTime * Spec_Speed );
    float spec = smoothstep( 0.08, 0.0, abs( specPos - 0.5 ) ) * Progress * Spec_Intensity;
    baseColor += vec3( 1.0 ) * spec;

    vec2 texel = CoronaTexelSize.xy * 2.0;
    float aC = orig.a;
    float edge = clamp(
        abs( aC - texture2D( CoronaSampler0, UV - vec2( texel.x, 0.0 ) ).a ) +
        abs( aC - texture2D( CoronaSampler0, UV + vec2( texel.x, 0.0 ) ).a ) +
        abs( aC - texture2D( CoronaSampler0, UV - vec2( 0.0, texel.y ) ).a ) +
        abs( aC - texture2D( CoronaSampler0, UV + vec2( 0.0, texel.y ) ).a ), 0.0, 1.0 );
    baseColor += Chrome_Tint * edge * Fresnel_Amount * Progress;

    vec3 finalRGB = mix( orig.rgb, clamp( baseColor, 0.0, 1.0 ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, orig.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
