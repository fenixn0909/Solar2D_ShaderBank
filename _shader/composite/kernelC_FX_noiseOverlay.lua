
--[[
    Simple noise overlay
    https://godotshaders.com/shader/simple-noise-overlay/
    MacNaab
    May 28, 2022
--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "noiseOverlay" 

kernel.isTimeDependent = true
kernel.textureWrap = 'repeat'


kernel.vertexData =
{
  { name = "Speed",   default = 1, min = 0, max = 10, index = 0, },
  { name = "Move_X",  default = 1, min = -5, max = 5, index = 1, },
  { name = "Move_Y",  default = 0, min = -5, max = 5, index = 2, },
  { name = "Mix",  default = 0, min = 0, max = 1, index = 3, },
  { name = "Progress", default = 1, min = 0, max = 1, index = 0, },
} 

kernel.fragment =
[[

float Speed = CoronaVertexUserData.x;
float Move_X = CoronaVertexUserData.y;
float Move_Y = CoronaVertexUserData.z;
float Mix = CoronaVertexUserData.w;

vec2 direction = vec2( Move_X, Move_Y );

//----------------------------------------------
uniform sampler2D TEXTURE;
//uniform sampler2D noise; //CoronaSampler1

//----------------------------------------------
vec4 overlay(vec4 base, vec4 blend){
    vec4 limit = step(0.5, base);
    return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit + Mix );
}

//----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec4 base = texture2D(TEXTURE, UV);
    vec4 blend = texture2D(CoronaSampler1, UV + ( direction * Speed * TIME ));
    
    COLOR = overlay(base, blend);

    COLOR.a = base.a;
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


