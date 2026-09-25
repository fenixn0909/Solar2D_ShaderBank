
--[[
    https://godotshaders.com/shader/vertical-drops/
    FencerDevLog
    September 16, 2024

    Great for rain, snow, fireflies

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FG"
kernel.name = "verticleDrop"


kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Density','Trail','Compression',
            'Move_Angle','','','',
            '','','','',
            '','','','',
        },
        default = {
            2,800,77,1.1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -10,50,-50,-5,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            10,1000,800,5,
            6.28318,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}


kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Speed = u_UserData0[0][0];
float Density = u_UserData0[0][1];
float Trail = u_UserData0[0][2];
float Compression = u_UserData0[0][3];
float Move_Angle = u_UserData0[1][0];

//----------------------------------------------
//----------------------------------------------

uniform vec3 color = vec3(0.5, 0.7, .9); // : source_color 
uniform float brightness = 100.5; //: hint_range(0.1, 10.0, 0.1)

float PI = 3.14159265359;

// -----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    //----------------------------------------------

    // Move_Angle rotates the drop direction so rain/snow/firefly drift is tweakable.
    {
        vec2 cuv = UV - vec2( 0.5 );
        float ca = cos( Move_Angle );
        float sa = sin( Move_Angle );
        UV = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + vec2( 0.5 );
    }

    vec2 uv = -UV;
    float time = TIME * Speed;
    uv.x *= Density;
    vec2 duv = vec2(floor(uv.x), uv.y) * Compression;
    float offset = sin(duv.x);
    float fall = cos(duv.x * 30.0);
    float trail = mix(100.0, Trail, fall);
    float drop = fract(duv.y + time * fall + offset) * trail;
    drop = 1.0 / drop;
    drop = smoothstep(0.0, 1.0, drop * drop);
    drop = sin(drop * PI) * fall * brightness;
    float shape = sin(fract(uv.x) * PI);
    drop *= shape * shape;
    COLOR = vec4(color * drop, 0.0);

    //----------------------------------------------


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
    
--]]


