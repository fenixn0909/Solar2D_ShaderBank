--[[
    https://godotshaders.com/shader/panorama-perspective-fnaf-fake-3d/
    Bixqa
    July 25, 2026
    PanoramaPerspective by Emil "Ace" Macko (FNaF fangame fake 3D).
    Original Direct3D -> GDShader, here -> Solar2D filter. CC0.
    Helper for faux-3D room scrolling; horizontal warp only.
    Original samples SCREEN_TEX (hint_screen_texture) with hfov/vfov/hr/vr
    etc. Here CoronaSampler0 is the screen capture (feed a snapshot).
    Keeps original trig + fov math, aspect 0.5625 as in source.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "panoramaPerspective"

kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Hr','Vr','Hfov','Vfov',
            'Z','Ho','Vo','To',
            'To2','','','',
            '','','','',
        },
        default = {
            .5, 1, 180, 60,
            1, .5, .5, 1,
            1, 0,0,0,
            0,0,0,0,
        },
        min = {
            0, 0, 0, 0,
            0.1, 0, 0, 0.1,
            0.1, 0,0,0,
            0,0,0,0,
        },
        max = {
            1, 1, 360, 360,
            3, 1, 1, 2,
            2, 1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Hr   = u_UserData0[0][0];
float Vr   = u_UserData0[0][1];
float Hfov = u_UserData0[0][2];
float Vfov = u_UserData0[0][3];
float Z    = u_UserData0[1][0];
float Ho   = u_UserData0[1][1];
float Vo   = u_UserData0[1][2];
float To   = u_UserData0[1][3];
float To2  = u_UserData0[2][0];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 texCoord = UV;
    vec2 newCoord;

    texCoord = (texCoord - 0.5) * Z + 0.5;

    vec2 o;
    o.x = radians(Hfov);
    o.y = radians(Vfov);

    float aspect = 0.5625;

    vec2 fov;
    fov.y = o.y * Vr;
    fov.x = atan(1.0 / (aspect / tan(fov.y * 0.5))) * 2.0;

    vec3 v;

    v.x = texCoord.x - 0.5 - (Ho - 0.5);
    v.y = (texCoord.y - 0.5) * aspect - To2 * (Vo - 0.5);
    v.z = 0.5 / tan(fov.x * 0.5);

    float ta = (0.5 - Vo) * (1.0 - Vr) * o.y * 2.0;

    float c = cos(ta);
    float s = sin(ta);

    float tz = v.z * c - v.y * s;
    float ty = v.z * s + v.y * c;

    v.z = tz;
    v.y = ty;

    v = normalize(v);

    float lon = atan(v.x, v.z);
    float vz2 = v.x * sin(lon) + v.z * cos(lon);
    float lat = atan(v.y, vz2);

    newCoord.x = lon / (o.x * Hr) + 0.5;
    newCoord.y = lat / (o.y * Vr) + To * tan((1.0 - Vr) * (Vo - 0.5)) + 0.5;

    P_COLOR vec4 COLOR;
    if (any(lessThan(newCoord, vec2(0.0))) ||
        any(greaterThan(newCoord, vec2(1.0))))
    {
        COLOR = vec4(0.0);
    }
    else
    {
        COLOR = texture2D(CoronaSampler0, newCoord);
    }
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
