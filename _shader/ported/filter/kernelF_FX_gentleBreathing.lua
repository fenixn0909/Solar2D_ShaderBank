
--[[
    https://godotshaders.com/shader/gentle-breathing-effect-for-face-body-animation/
    emre
    October 30, 2025

    Direct port, single texture (CoronaSampler0), nothing dropped.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "wobble"
kernel.name = "gentleBreathing"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Breath_Strength", default = .007, min = 0,  max = .03, index = 0, },
  { name = "Breath_Speed",    default = .8,   min = 0,  max = 4,   index = 1, },
  { name = "Face_Center_Y",   default = .5,   min = 0,  max = 1,   index = 2, },
  { name = "Face_Radius",     default = .5,   min = .05, max = 1,  index = 3, },
}


kernel.fragment =
[[

float Breath_Strength = CoronaVertexUserData.x;
float Breath_Speed    = CoronaVertexUserData.y;
float Face_Center_Y    = CoronaVertexUserData.z;
float Face_Radius      = CoronaVertexUserData.w;

vec2 Face_Center = vec2( 0.5, Face_Center_Y );
float TIME = CoronaTotalTime;

//----------------------------------------------

float circle_mask( vec2 uv, vec2 center, float radius )
{
    float d = distance( uv, center );
    return 1.0 - smoothstep( radius * 0.6, radius, d );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float face_m = circle_mask( UV, Face_Center, Face_Radius );
    float dist = distance( UV, Face_Center );
    float falloff = exp( -dist * dist * 6.0 );
    float breath = sin( TIME * Breath_Speed ) * Breath_Strength * face_m * falloff;

    vec2 final_uv = UV + vec2( 0.0, breath );

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, final_uv );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

