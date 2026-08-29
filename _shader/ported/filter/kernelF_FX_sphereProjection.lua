--[[
    https://godotshaders.com/shader/2d-sphere-projection-with-rotation/
    breadpack (CC0, original by Ultipuk)
    May 7, 2026
    Projects equirectangular texture onto a sphere with rotation.
    Uses discard outside radius; here alpha=0. Original CC0.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "sphereProjection"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniCenter",
        paramName = {
            'Center_X','Center_Y','Radius','Rot_Speed_X',
            'Rot_Speed_Y','Rot_Speed_Z','Rot_Offset_X','Rot_Offset_Y',
            'Rot_Offset_Z','','','',
            '','','','',
        },
        default = {
            .5, .5, .5, 0,
            .3, 0, 0, 0,
            0, 0,0,0,
            0,0,0,0,
        },
        min = {
            0,0, 0, -2,
            -2,-2, -3.14, -3.14,
            -3.14,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1, 2, 2,
            2,2, 3.14, 3.14,
            3.14,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------
vec2 Center = vec2(u_UserData0[0][0], u_UserData0[0][1]);
float Radius = u_UserData0[0][2];
float Rot_Speed_X = u_UserData0[0][3];
float Rot_Speed_Y = u_UserData0[1][0];
float Rot_Speed_Z = u_UserData0[1][1];
float Rot_Offset_X= u_UserData0[1][2];
float Rot_Offset_Y= u_UserData0[1][3];
float Rot_Offset_Z= u_UserData0[2][0];
float TIME = CoronaTotalTime;
const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec3 rotate_x(vec3 p, float a){ float s=sin(a); float c=cos(a); return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z); }
vec3 rotate_y(vec3 p, float a){ float s=sin(a); float c=cos(a); return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z); }
vec3 rotate_z(vec3 p, float a){ float s=sin(a); float c=cos(a); return vec3(c*p.x - s*p.y, s*p.x + c*p.y, p.z); }

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p = (UV - Center) / Radius;
    float r2 = dot(p,p);
    if (r2 > 1.0) {
        P_COLOR vec4 COLOR = vec4(0.0);
        COLOR.rgb *= COLOR.a;
        return CoronaColorScale(COLOR);
    }
    vec3 n = vec3(p.x, p.y, sqrt(1.0 - r2));
    float ax = (TIME * Rot_Speed_X + Rot_Offset_X) * PI;
    float ay = (TIME * Rot_Speed_Y + Rot_Offset_Y) * PI;
    float az = (TIME * Rot_Speed_Z + Rot_Offset_Z) * PI;
    n = rotate_x(n, ax);
    n = rotate_y(n, ay);
    n = rotate_z(n, az);
    float u = atan(-n.z, n.x) / TAU + 0.5;
    float v = asin(clamp(n.y, -1.0, 1.0)) / PI + 0.5;
    P_COLOR vec4 COLOR = texture2D(CoronaSampler0, vec2(u, v));
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
