--[[
    https://godotshaders.com/shader/advanced-side-vignette/
    herrmarx
    March 2, 2026
    Side vignette with directional sweep, curvature, intensity. CC0.
    Original used discard when !active; here active=0 makes alpha 0.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "sideVignette"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Active','Invert_Side','Convex_Mode','Progress',
            'Softness','Curvature','Intensity','',
            'Vignette_R','Vignette_G','Vignette_B','Vignette_A',
            '','','','',
        },
        default = {
            1,0,0,.5,
            .4,.8,1,0,
            0,0,0,1,
            0,0,0,0,
        },
        min = {
            0,0,0,-1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,2,
            1,2,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Active      = u_UserData0[0][0];
float Invert_Side = u_UserData0[0][1];
float Convex_Mode = u_UserData0[0][2];
float Progress    = u_UserData0[0][3];
float Softness    = u_UserData0[1][0];
float Curvature   = u_UserData0[1][1];
float Intensity   = u_UserData0[1][2];
vec4 Vignette_Color = vec4(u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3]);

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    if (Active < 0.5) {
        P_COLOR vec4 c = texture2D(CoronaSampler0, UV);
        return CoronaColorScale(c);
    }
    vec2 uv = UV;
    float x = Invert_Side > 0.5 ? 1.0 - uv.x : uv.x;
    float dist = abs(uv.y - 0.5);
    float curve = dist * dist * Curvature;
    float modified = Convex_Mode > 0.5 ? (x + curve) : (x - curve + (Curvature * 0.25));
    float v = smoothstep(Progress, Progress + Softness, modified);
    float mask = 1.0 - v;
    vec4 base = texture2D(CoronaSampler0, UV);
    vec4 vig = Vignette_Color;
    vig.a = mask * Intensity;
    // blend vignette over base using alpha
    P_COLOR vec4 COLOR = mix(base, vig, vig.a);
    // keep original alpha where not vignetted? use base alpha
    COLOR.a = base.a;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
