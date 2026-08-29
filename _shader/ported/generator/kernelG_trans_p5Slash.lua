
--[[
    https://godotshaders.com/shader/scene-change-transition-effects-persona-5-inspired/
    ProfesorShader
    June 14, 2026

    Ported from Godot's "Persona 5 slash transition". Original exposes
    mask_color/background_color as separate colors and normal as a raw
    vec2; here the reveal is done via alpha (background is always fully
    transparent, matching how the rest of this bank's trans shaders
    work) and normal.x/y is collapsed into a single Angle for a more
    slider-friendly control.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "trans"
kernel.name = "p5Slash"

kernel.vertexData =
{
  { name = "Progress",  default = .5,  min = 0,    max = 1,   index = 0, },
  { name = "Power",     default = 10,  min = 1,    max = 30,  index = 1, },
  { name = "Angle",     default = 45,  min = 0,    max = 360, index = 2, },
  { name = "Offset",    default = -.5, min = -1.5, max = 1.5, index = 3, },
}


kernel.fragment =
[[

float Progress = CoronaVertexUserData.x;
float Power    = CoronaVertexUserData.y;
float Angle    = CoronaVertexUserData.z;
float Offset   = CoronaVertexUserData.w;
//----------------------------------------------

P_COLOR vec4 Col_Fill = vec4( 0.0, 0.0, 0.5, 1.0 );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = Col_Fill;

    vec2 dir = normalize( vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) ) );
    float dist = abs( dot( dir, UV ) + Offset );
    float thickness = pow( Progress, Power );

    COLOR.a = dist <= thickness ? 1.0 : 0.0;
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

