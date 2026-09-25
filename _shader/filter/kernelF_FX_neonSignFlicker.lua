
--[[
    Original implementation for this bank. Makes an existing sign/text/
    icon sprite read as a lit neon tube: a colored glow bleeds outward
    from the sprite's own alpha edge (sampled, not a fixed blur), held
    mostly steady but with brief hashed-timing dropouts/stutters
    (Flicker_Chance per short time-slot) that dim the tube instead of
    a smooth sine pulse - a real tube's flicker is irregular, not
    periodic.

    Checked against all existing kernels first: kernelF_FX_bloom and
    kernelF_color_glow are steady brightness blooms with no flicker-
    dropout timing at all; kernelF_FX_shine is a single diagonal sweep
    highlight, unrelated mechanic. Neither reproduces a neon tube's
    irregular on/off stutter.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "neonSignFlicker"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Glow_Amount','Glow_Radius','Flicker_Chance','Flicker_Speed',
            'Color_R','Color_G','Color_B','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            1.2,.02,.12,6,
            1,.2,.85,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,.005,0,1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3,.06,.5,20,
            1,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Glow_Amount    = u_UserData0[0][0];
float Glow_Radius    = u_UserData0[0][1];
float Flicker_Chance = u_UserData0[0][2];
float Flicker_Speed  = u_UserData0[0][3];
vec3  Neon_Color     = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Opacity        = u_UserData0[1][3];

//----------------------------------------------

P_RANDOM float neon_hash( float n )
{
    return fract( sin( n * 78.9 ) * 43758.5 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float glow = 0.0;
    for ( int i = 0; i < 8; i++ )
    {
        float a = float( i ) / 8.0 * 6.28318;
        vec2 offs = vec2( cos( a ), sin( a ) ) * Glow_Radius;
        glow += texture2D( CoronaSampler0, UV + offs ).a;
    }
    glow /= 8.0;

    float slot = floor( CoronaTotalTime * Flicker_Speed );
    float slotHash = neon_hash( slot );
    float dropout = 1.0 - step( 1.0 - Flicker_Chance, slotHash ) * ( 0.5 + 0.5 * neon_hash( slot + 5.0 ) );

    float glowAmt = glow * Glow_Amount * dropout;
    vec3 finalRGB = tex.rgb + Neon_Color * glowAmt * ( 1.0 - tex.a );
    float finalAlpha = clamp( tex.a + glowAmt * ( 1.0 - tex.a ) * 0.6, 0.0, 1.0 );

    vec3 outRGB = mix( tex.rgb, finalRGB, Opacity );
    float outAlpha = mix( tex.a, finalAlpha, Opacity );

    P_COLOR vec4 COLOR = vec4( outRGB, outAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
