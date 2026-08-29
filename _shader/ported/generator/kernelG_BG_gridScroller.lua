--[[
    https://godotshaders.com/shader/background-grid-scroller/
    dibin
    May 5, 2026
    Dark diagonal scrolling grid with central pulse. CC0. Original for ColorRect,
    here as generator (no texture needed). CC0.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "gridScroller"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Bg_R','Bg_G','Bg_B','Bg_A',
            'Line_R','Line_G','Line_B','Line_A',
            'Glow_R','Glow_G','Glow_B','Glow_A',
            'Grid_Size','Line_Thickness','Scroll_Speed','Motion_Strength',
        },
        default = {
            .03, .03, .07, 1,
            .1, .1, .3, 1,
            .2, .4, 1, 1,
            .06, .002, .06, .007,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            .01,0,0,0,
        },
        max = {
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
            .2,.05,.2,.02,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniMotion",
        paramName = {
            'Motion_Speed1','Motion_Speed2','','',
            '','','','',
            '','','','',
            '','','','',
        },
        default = { .03, .015,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { .1,.1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
//----------------------------------------------
vec4 Bg_Color   = vec4(u_UserData0[0][0], u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3]);
vec4 Line_Color = vec4(u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3]);
vec4 Glow_Color = vec4(u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3]);
float Grid_Size      = u_UserData0[3][0];
float Line_Thickness = u_UserData0[3][1];
float Scroll_Speed   = u_UserData0[3][2];
float Motion_Strength= u_UserData0[3][3];
float Motion_Speed1  = u_UserData1[0][0];
float Motion_Speed2  = u_UserData1[0][1];
float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    float w1 = sin((uv.x + uv.y) * 10.0 + TIME * Motion_Speed1);
    float w2 = sin((uv.x - uv.y) * 50.0 + TIME * Motion_Speed2);
    float subtle = (w1 + w2) * 0.5 * Motion_Strength;
    vec2 warped = uv + vec2(subtle, subtle);
    vec2 scrolled = warped + vec2(TIME * Scroll_Speed, TIME * Scroll_Speed);
    vec2 grid = fract(scrolled / Grid_Size);
    float lineX = step(1.0 - Line_Thickness / Grid_Size, grid.x);
    float lineY = step(1.0 - Line_Thickness / Grid_Size, grid.y);
    float lines = max(lineX, lineY);
    vec2 centered = uv - vec2(0.5);
    float dist = length(centered);
    float pulse = sin(TIME * 0.4) * 0.5 + 0.5;
    float glow = smoothstep(0.9, 0.0, dist) * 0.1 * pulse;
    vec4 col = Bg_Color;
    col = mix(col, Line_Color, lines * 0.5);
    col += Glow_Color * glow;
    P_COLOR vec4 COLOR = col;
    return CoronaColorScale(COLOR);
}
]]

return kernel
