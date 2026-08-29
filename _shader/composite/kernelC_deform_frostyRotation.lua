--[[
    https://godotshaders.com/shader/frosty-rotative-deformation/
    CasualGarageCoder Dec 6, 2022
    Fixed: used uniform sampler2D TEXTURE (not Corona) and
    texture2D(TEXTURE, ...) not CoronaSampler0, and TIME*100
    too fast. Now uses CoronaSampler0/1 correctly and Speed param.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "deform"
kernel.name = "frostyRotation" 

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Speed",     default = 1,   min = 0, max = 10, index = 0, },
  { name = "Dist_Rate", default = 2,   min = 0.01, max = 10, index = 1, },
  { name = "Coord_Off", default = 0.7, min = -1, max = 1, index = 2, },
  { name = "Dist_Off",  default = 0.5, min = -1, max = 1, index = 3, },
} 

kernel.fragment =
[[

float Speed = CoronaVertexUserData.x;
float Dist_Rate = CoronaVertexUserData.y;
float Coord_Off = CoronaVertexUserData.z;
float Dist_Off = CoronaVertexUserData.w;  

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float dist_rate = Dist_Rate * 0.0001;
    float angle = CoronaTotalTime * Speed;
    vec2 dist = vec2(Dist_Off) - UV;
    float s = sin(angle);
    float c = cos(angle);
    mat2 m = mat2(vec2(c, -s), vec2(s, c));
    dist *= m;
    vec4 coord = texture2D(CoronaSampler1, dist * dist_rate);
    coord.x -= Coord_Off;
    coord.y -= Coord_Off;
    vec4 col = texture2D(CoronaSampler0, UV + coord.xy);
    P_COLOR vec4 COLOR = col;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
