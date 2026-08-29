--[[
    https://godotshaders.com/shader/classic-dithering-shader/
    zessbin
    May 12, 2026
    Classic 4x4 Bayer dithering. CC0. Original does step(bayer, pow(TEXTURE, gamma)).
    Here CoronaSampler0 is TEXTURE, FRAGCOORD = UV * iResolution.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "ditherClassic"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Gamma','','','',
            '','','','',
            '','','','',
            '','','','',
        },
        default = { 2.2,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 10,0,0,0, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Gamma = u_UserData0[0][0];
P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;

const mat4 BAYER4 = mat4(
    vec4(0.0, 12.0, 3.0, 15.0),
    vec4(8.0, 4.0, 11.0, 7.0),
    vec4(2.0, 14.0, 1.0, 13.0),
    vec4(10.0, 6.0, 9.0, 5.0)
);

float bayer4(vec2 pixel){
    ivec2 p = ivec2(mod(pixel, 4.0));
    return BAYER4[p.x][p.y] / 16.0;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float threshold = bayer4(UV * iResolution);
    vec4 tex = texture2D(CoronaSampler0, UV);
    P_COLOR vec4 COLOR = step(threshold, pow(tex, vec4(Gamma)));
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
