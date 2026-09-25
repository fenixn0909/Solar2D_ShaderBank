
--[[
    Original implementation for this bank. Modeled on the "stone /
    petrify" sprite-FX category that's a staple of 2D action/RPG
    plugins (e.g. the 2DFX sprite-FX suite's Stone effect and similar
    Unity 2D_Status-effect packs all lead with a gray-statue
    petrification look) - nothing was copied from any of them (all
    paid, closed-source); this reimplements the same feature list as a
    plain fragment kernel: luminance-desaturate toward a gray Stone
    tint with a Contrast lift so it reads as carved rock rather than a
    flat gray wash, plus a two-octave procedural grain that darkens
    crevices and a subtle top-light gradient for a chiseled feel.
    Progress 0 -> 1 goes flesh to statue; alpha is untouched so the
    silhouette is preserved.

    Checked against all existing kernels first: this bank has
    grayscale-adjacent looks (parchment, whiteBalance, paletteLimit)
    but no dedicated petrify/statue effect.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "stone"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Noise_Scale','Grain','Contrast',
            'Stone_R','Stone_G','Stone_B','Stone_Strength',
            'Light_Dir_X','Light_Dir_Y','Light_Amount','',
            '','','','',
        },
        default = {
            .8,7,.45,1.12,
            .62,.62,.66,1,
            0,.9,.25,0,
            0,0,0,0,
        },
        min = {
            0,1,0,.5,
            0,0,0,0,
            -1,-1,0,0,
            0,0,0,0,
        },
        max = {
            1,16,1,2,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress       = u_UserData0[0][0];
float Noise_Scale    = u_UserData0[0][1];
float Grain          = u_UserData0[0][2];
float Contrast       = u_UserData0[0][3];
vec3  Stone_Tint     = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Stone_Strength = u_UserData0[1][3];
vec2  Light_Dir      = vec2( u_UserData0[2][0], u_UserData0[2][1] );
float Light_Amount   = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float stone_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float stone_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( stone_hash( i ), stone_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( stone_hash( i + vec2( 0.0, 1.0 ) ), stone_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 carved = vec3( lum ) * Stone_Tint * 2.0;
    carved = ( carved - 0.5 ) * Contrast + 0.5;

    float grain = stone_noise( UV * Noise_Scale ) * 0.6
                + stone_noise( UV * Noise_Scale * 2.7 + 13.1 ) * 0.4;
    carved *= 1.0 - ( grain - 0.5 ) * Grain;

    float light = dot( UV - 0.5, normalize( Light_Dir + vec2( 0.0001, 0.0 ) ) );
    carved *= 1.0 - light * Light_Amount * 0.5;

    vec3 finalRGB = mix( tex.rgb, carved, clamp( Progress, 0.0, 1.0 ) * Stone_Strength );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
