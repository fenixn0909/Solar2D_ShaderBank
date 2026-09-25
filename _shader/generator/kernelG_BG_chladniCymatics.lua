
--[[
    Original implementation for this bank of Chladni figures - the
    nodal-line patterns that appear on a vibrating plate (classic
    cymatics physics, a recurring subject for shader demos because the
    whole pattern comes from one closed-form standing-wave equation:
    sin(n*pi*x)*sin(m*pi*y) - sin(m*pi*x)*sin(n*pi*y) for mode numbers
    n, m). Nodal lines are drawn wherever that expression crosses zero;
    Mode_N/Mode_M drift slowly over time via a sine offset so the
    pattern continuously morphs between mode shapes rather than sitting
    static.

    Checked against all existing kernels first: nothing else in the
    bank builds a standing-wave interference pattern from this
    equation - closest by surface look is kernelF_trans_crossHatch (a
    fixed-angle static hatch used as a transition wipe mask, no
    standing-wave math, no morphing) and this bank's own kernelG_FX_
    moireInterference (this batch - two overlapping radial gratings
    beating against each other, a different equation and a different
    visual family from nodal nulls of one combined wave).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "chladniCymatics"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Mode_N','Mode_M','Scale','Line_Width',
            'Morph_Speed','Morph_Amount','Color_R','Color_G',
            'Color_B','BG_R','BG_G','BG_B',
            'Opacity','','','',
        },
        default = {
            5,4,1,.05,
            .15,1.5,.85,.9,
            1,.04,.05,.08,
            1,0,0,0,
        },
        min = {
            1,1,.3,.01,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            12,12,3,.15,
            .6,4,1,1,
            1,1,1,1,
            1,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Mode_N        = u_UserData0[0][0];
float Mode_M        = u_UserData0[0][1];
float Scale         = u_UserData0[0][2];
float Line_Width    = u_UserData0[0][3];
float Morph_Speed   = u_UserData0[1][0];
float Morph_Amount  = u_UserData0[1][1];
vec3  Line_Color    = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
vec3  BG_Color      = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float Opacity       = u_UserData0[3][0];

const float PI = 3.14159265;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float n = Mode_N + sin( CoronaTotalTime * Morph_Speed ) * Morph_Amount;
    float m = Mode_M + cos( CoronaTotalTime * Morph_Speed * 0.77 ) * Morph_Amount;

    vec2 p = UV * Scale;
    float f = sin( n * PI * p.x ) * sin( m * PI * p.y ) - sin( m * PI * p.x ) * sin( n * PI * p.y );

    float lines = smoothstep( Line_Width, 0.0, abs( f ) );
    vec3 finalRGB = mix( BG_Color, Line_Color, lines );
    finalRGB = mix( BG_Color, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
