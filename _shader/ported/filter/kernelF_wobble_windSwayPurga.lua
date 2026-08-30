--[[
    https://godotshaders.com/shader/2d-wind-sway-tree-grass-motion-shader/
    Purga
    Feb 28, 2026 (updated Mar 25)
    Lightweight wind sway, top moves more than base. CC0. Original uses
    REGION_RECT and VERTEX scaling; here approximated with UV distance
    from bottom (0,1). Uses discard outside 0..1.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "wobble"
kernel.name = "windSwayPurga"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniWind",
        paramName = {
            'Wind_Start','Start_Y','Strength','Curve',
            'Speed','','','',
            '','','','',
            '','','','',
        },
        default = { 0,.3,.15,1.5, 2,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { -1.57,0,0,0,  0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1.57,1,1,3,   10,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Wind_Start= u_UserData0[0][0];
float Start_Y   = u_UserData0[0][1];
float Strength  = u_UserData0[0][2];
float Curve     = u_UserData0[0][3];
float Speed     = u_UserData0[1][0];
float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float scale = (pow(2.0, Curve) * Strength * 2.0);
    // total_scale not needed for UV-only sway; use strength
    vec2 wind_uv = UV;
    // wind sway increases toward top (y=0), zero at bottom (y=1)
    float t = smoothstep(Start_Y, 1.0 + Start_Y, pow((1.0 - wind_uv.y), 0.5));
    wind_uv.x += sin(TIME * Speed + Wind_Start) * t * pow((1.0 - wind_uv.y + 1.0), Curve) * Strength;
    // discard outside is alpha 0 in Solar2D, not discard
    if (wind_uv.x < 0.0 || wind_uv.x > 1.0 || wind_uv.y < 0.0 || wind_uv.y > 1.0) {
        P_COLOR vec4 COLOR = vec4(0.0);
        return CoronaColorScale(COLOR);
    }
    P_COLOR vec4 COLOR = texture2D(CoronaSampler0, wind_uv);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
