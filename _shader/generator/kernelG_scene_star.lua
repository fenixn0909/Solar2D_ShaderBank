--[[
    Origin Author: gerardogc2378
    https://godotshaders.com/author/gerardogc2378/
    gerardogc2378
    August 12, 2021
    Hi, if you like stars just like me then you can enjoy this shader. 
    I played with an Android device and works really fine with a GLES2 project.

--]]


local kernel = {}

kernel.language = "glsl"

kernel.category = "generator"
kernel.group = "scene"
kernel.name = "star"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Star_Size','Density','Twinkle_Speed','Brightness',
            'BG_R','BG_G','BG_B','Seed',
            '','','','',
            '','','','',
        },
        default = {
            100,.9,8,1,
            0,0,.2,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            20,.5,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            200,.995,20,3,
            1,1,1,50,
            0,0,0,0,
            0,0,0,0,
        },
    },
}


kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Star_Size     = u_UserData0[0][0];
float Density       = u_UserData0[0][1];
float Twinkle_Speed = u_UserData0[0][2];
float Brightness    = u_UserData0[0][3];
vec3 BG_Color       = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Seed          = u_UserData0[1][3];
vec4 Col_BG = vec4(BG_Color, 1.0);

//----------------------------------------------
float rand(vec2 st) {
    return fract(sin(dot(st.xy + Seed, vec2(12.9898,78.233))) * 43758.5453123);
}

//----------------------------------------------

float TIME = CoronaTotalTime;
P_COLOR vec4 COLOR = vec4(0);

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_UV vec2 SCREEN_UV = texCoord;
    P_UV vec2 texelOffset = ( CoronaTexelSize.zw * 0.5 );
    P_UV vec2 FRAGCOORD = ( texelOffset + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw ) );
    //----------------------------------------------

    float size = Star_Size;
    float prob = Density;
    vec2 pos = floor(1.0 / size * FRAGCOORD.xy);
    float color = 0.0;
    float starValue = rand(pos);

    if (starValue > prob)
    {
        vec2 center = size * pos + vec2(size, size) * 0.5;
        float t = 0.9 + 0.2 * sin(TIME * Twinkle_Speed + (starValue - prob) / (1.0 - prob) * 45.0);
        color = 1.0 - distance(FRAGCOORD.xy, center) / (0.5 * size);
        color = color * t / (abs(FRAGCOORD.y - center.y)) * t / (abs(FRAGCOORD.x - center.x));
    }
    else if (rand(SCREEN_UV.xy / 20.0) > 0.995)
    {
        float r = rand(SCREEN_UV.xy);
        color = r * (0.85 * sin(TIME * (r * 5.0) + 720.0 * r) + 0.95);
    }
    color *= Brightness;
    COLOR = vec4(vec3(color),1.0) + Col_BG;
    //----------------------------------------------

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[


--]]
