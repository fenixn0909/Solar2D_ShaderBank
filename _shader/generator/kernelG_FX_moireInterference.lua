
--[[
    Original implementation for this bank of a classic moire
    interference pattern: two radial sine gratings centered at
    slightly offset points are multiplied together (rather than added),
    which is what makes the beating bands appear - multiplying two
    oscillating signals produces sum/difference frequency components,
    the actual mathematics behind real-world moire. Offset drifts
    slowly over time so the interference bands visibly crawl and pulse
    rather than sitting static.

    Checked against all existing kernels first: this bank's own
    kernelG_BG_chladniCymatics (this batch) is a single combined
    standing-wave equation whose *zero-crossings* are drawn as nodal
    lines - a subtractive equation with hard nulls, not two full
    gratings multiplied together; no existing kernel multiplies two
    independent radial gratings for a beat-frequency pattern.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "moireInterference"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Frequency','Offset','Anim_Speed','Color_R',
            'Color_G','Color_B','BG_R','BG_G',
            'BG_B','Aspect_Ratio','Opacity','',
            '','','','',
        },
        default = {
            60,.06,.15,.7,
            .85,1,.05,.05,
            .08,1,1,0,
            0,0,0,0,
        },
        min = {
            10,0,0,0,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            150,.2,1,1,
            1,1,1,1,
            1,5,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Frequency     = u_UserData0[0][0];
float Offset        = u_UserData0[0][1];
float Anim_Speed    = u_UserData0[0][2];
vec3  Line_Color    = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
vec3  BG_Color      = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];
float Opacity       = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float wobble = sin( CoronaTotalTime * Anim_Speed ) * Offset;

    vec2 c1 = vec2( 0.5 + Offset + wobble, 0.5 );
    vec2 c2 = vec2( 0.5 - Offset - wobble, 0.5 );

    float r1 = length( ( UV - c1 ) * vec2( 1.0, Aspect_Ratio ) );
    float r2 = length( ( UV - c2 ) * vec2( 1.0, Aspect_Ratio ) );

    float g1 = 0.5 + 0.5 * sin( r1 * Frequency * 6.28318 );
    float g2 = 0.5 + 0.5 * sin( r2 * Frequency * 6.28318 );

    float moire = g1 * g2;

    vec3 finalRGB = mix( BG_Color, Line_Color, moire );
    finalRGB = mix( BG_Color, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
