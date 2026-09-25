
--[[
    Original implementation for this bank. Modeled on the "ghost /
    spirit" character-transform category from commercial character
    shader bundles - nothing was copied from any of them (all paid,
    closed-source). Progress 0 -> 1 fades alpha down to Min_Alpha,
    shifts color toward a cold Spirit_Tint, adds a slow vertical wave
    resample (so the silhouette itself wavers rather than just
    dimming) and an alpha-edge rim glow that brightens as more of the
    sprite becomes translucent, for an "ethereal, barely-there" read
    distinct from a flat opacity fade.

    Checked against all existing kernels first: this bank's dissolve
    family (kernelF_FX_dissolve/dissolveMistOG/dissolveNoise3D) removes
    pixels via a noise threshold (parts fully vanish, parts stay fully
    solid) rather than uniformly translucing the whole sprite; kernelF_
    FX_holoDataScan is a scan-line hologram flicker with no wavering
    silhouette or cold tint shift. Neither produces a uniformly
    translucent, wavering, cold-tinted ghost read.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "ghostSpiritFade"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Min_Alpha','Tint_R','Tint_G',
            'Tint_B','Tint_Amount','Wave_Speed','Wave_Amount',
            'Rim_Amount','Opacity','','',
            '','','','',
        },
        default = {
            0,.35,.6,.8,
            1,.6,2,.012,
            .8,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.8,1,1,
            1,1,6,.03,
            2,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress     = u_UserData0[0][0];
float Min_Alpha    = u_UserData0[0][1];
vec3  Spirit_Tint  = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Tint_Amount  = u_UserData0[1][1];
float Wave_Speed   = u_UserData0[1][2];
float Wave_Amount  = u_UserData0[1][3];
float Rim_Amount   = u_UserData0[2][0];
float Opacity      = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 wave = vec2( sin( UV.y * 22.0 + CoronaTotalTime * Wave_Speed ) * Wave_Amount, 0.0 ) * Progress;
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV + wave );

    vec2 texel = CoronaTexelSize.xy * 2.0;
    float aC = tex.a;
    float aL = texture2D( CoronaSampler0, UV + wave - vec2( texel.x, 0.0 ) ).a;
    float aR = texture2D( CoronaSampler0, UV + wave + vec2( texel.x, 0.0 ) ).a;
    float aD = texture2D( CoronaSampler0, UV + wave - vec2( 0.0, texel.y ) ).a;
    float aU = texture2D( CoronaSampler0, UV + wave + vec2( 0.0, texel.y ) ).a;
    float edge = clamp( abs( aC - aL ) + abs( aC - aR ) + abs( aC - aD ) + abs( aC - aU ), 0.0, 1.0 );

    vec3 ghostColor = mix( tex.rgb, Spirit_Tint, Progress * Tint_Amount );
    ghostColor += Spirit_Tint * edge * Rim_Amount * Progress;

    float ghostAlpha = tex.a * mix( 1.0, Min_Alpha, Progress );

    vec3 finalRGB = mix( tex.rgb, ghostColor, Opacity );
    float finalAlpha = mix( tex.a, ghostAlpha, Opacity );

    P_COLOR vec4 COLOR = vec4( clamp( finalRGB, 0.0, 1.0 ), finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
