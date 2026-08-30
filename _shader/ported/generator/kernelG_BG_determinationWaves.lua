--[[
    https://godotshaders.com/shader/determination-waves-undertale-style/
    Dep Emily
    April 14, 2026
    Undertale Asgore-style determination waves. CC0. Generator (no texture).
    5-color palette + RGB mode toggle, bar-based wave.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "determinationWaves"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniWave",
        paramName = {
            'Height_Limit','Color_Speed','Follow_Strength','Fade_Strength',
            'Use_Rgb','Speed','Bar_Height','Alpha',
            '','','','',
            '','','','',
        },
        default = { .5, 1, .7, 2, 1,1.5,.03,1, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,.01,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,5,1,5, 1,5,.1,1, 1,1,1,1, 1,1,1,1, },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor1",
        paramName = {
            'C1_R','C1_G','C1_B','C1_A',
            'C2_R','C2_G','C2_B','C2_A',
            'C3_R','C3_G','C3_B','C3_A',
            'C4_R','C4_G','C4_B','C4_A',
        },
        default = { 1,0,0,1, 0,1,0,1, 0,0,1,1, 1,1,0,1, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
    {
        index = 2,
        type = "mat4",
        name = "uniColor2",
        paramName = {
            'C5_R','C5_G','C5_B','C5_A',
            '','','','',
            '','','','',
            '','','','',
        },
        default = { 1,0,1,1, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

float Speed      = u_UserData0[1][1];
float Bar_Height = u_UserData0[1][2];
float Alpha      = u_UserData0[1][3];

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
uniform P_COLOR mat4 u_UserData2;
//----------------------------------------------
float Height_Limit   = u_UserData0[0][0];
float Color_Speed    = u_UserData0[0][1];
float Follow_Strength= u_UserData0[0][2];
float Fade_Strength  = u_UserData0[0][3];
float Use_Rgb        = u_UserData0[1][0];
vec4 C1 = vec4(u_UserData1[0][0],u_UserData1[0][1],u_UserData1[0][2],u_UserData1[0][3]);
vec4 C2 = vec4(u_UserData1[1][0],u_UserData1[1][1],u_UserData1[1][2],u_UserData1[1][3]);
vec4 C3 = vec4(u_UserData1[2][0],u_UserData1[2][1],u_UserData1[2][2],u_UserData1[2][3]);
vec4 C4 = vec4(u_UserData1[3][0],u_UserData1[3][1],u_UserData1[3][2],u_UserData1[3][3]);
vec4 C5 = vec4(u_UserData2[0][0],u_UserData2[0][1],u_UserData2[0][2],u_UserData2[0][3]);
float TIME = CoronaTotalTime;

float random(float x){ return fract(sin(x * 12345.678) * 98765.4321); }

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    float row = floor(uv.y / Bar_Height);
    float base = random(row) * 2.0;
    float neigh = random(row + 1.0) * 2.0;
    float offset = mix(base, neigh, Follow_Strength);
    float global_wave = sin(TIME * Speed);
    float local_wave = sin(TIME * Speed + offset) * 0.3;
    float wave = (global_wave + local_wave) * 0.5 + 0.5;
    wave *= Height_Limit;
    float mask = step(uv.y, wave);
    float fade = clamp((wave - uv.y) * Fade_Strength, 0.0, 1.0);
    vec3 col;
    if (Use_Rgb > 0.5){
        float r = sin(TIME * Color_Speed + row * 0.2) * 0.5 + 0.5;
        float g = sin(TIME * Color_Speed + row * 0.2 + 2.0) * 0.5 + 0.5;
        float b = sin(TIME * Color_Speed + row * 0.2 + 4.0) * 0.5 + 0.5;
        col = vec3(r,g,b);
    } else {
        float t = fract(TIME * Color_Speed + row * 0.1);
        vec3 c12 = mix(C1.rgb, C2.rgb, t);
        vec3 c23 = mix(C2.rgb, C3.rgb, t);
        vec3 c34 = mix(C3.rgb, C4.rgb, t);
        vec3 c45 = mix(C4.rgb, C5.rgb, t);
        col = mix(mix(c12,c23,t), mix(c34,c45,t), 0.5);
    }
    P_COLOR vec4 COLOR = vec4(col, fade * mask * Alpha);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
