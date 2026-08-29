
--[[
    https://godotshaders.com/shader/noise-offset-wiggle/
    nuzcraft
    October 26, 2023

    ✳️ Great for Wind / Water Flow ✳️

]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "wobble"
kernel.name = "noiseOffset"

kernel.isTimeDependent = true


kernel.vertexData =
{
  { name = "Strength",        default = 1.4, min = 0, max = 5,   index = 0, },
  { name = "UV_Scaling",      default = 1,   min = .1, max = 5,  index = 1, },
  { name = "Movement_Angle",  default = 90,  min = 0, max = 360, index = 2, },
  { name = "Movement_Speed",  default = .5,  min = 0, max = 3,   index = 3, },
}


kernel.fragment =
[[

float Strength       = CoronaVertexUserData.x;
float UV_Scaling     = CoronaVertexUserData.y;
float Movement_Angle = CoronaVertexUserData.z;
float Movement_Speed = CoronaVertexUserData.w;

//----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;
P_UV vec2 SCREEN_PIXEL_SIZE = CoronaTexelSize.xy;

P_COLOR vec4 FragmentKernel( P_UV vec2 SCREEN_UV )
{

    //----------------------------------------------
    vec2 uv = SCREEN_UV;
    vec2 movement_direction = vec2( cos( radians( Movement_Angle ) ), sin( radians( Movement_Angle ) ) );
    vec2 movement_factor = movement_direction * Movement_Speed * TIME;
    float noise_value = texture2D( CoronaSampler1, uv * UV_Scaling + movement_factor ).r - 0.5;
    uv += noise_value * SCREEN_PIXEL_SIZE * Strength;
    COLOR = texture2D( CoronaSampler0, uv );


    //----------------------------------------------

    return CoronaColorScale(COLOR);
}
]]

return kernel

