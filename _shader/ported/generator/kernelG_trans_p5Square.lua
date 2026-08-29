
--[[
    https://godotshaders.com/shader/scene-change-transition-effects-persona-5-inspired/
    ProfesorShader
    June 14, 2026

    Ported from Godot's "Persona 5 square transition". Original corrects
    for screen aspect ratio via SCREEN_PIXEL_SIZE so the mask reads as a
    true square on any screen; a generator kernel has no input texture
    to read dimensions from, so that correction is dropped here - apply
    this to a square (or near-square) display object, or add your own
    aspect correction to `uv.y` below if you need it on a wide rect.
    Reveal is done via alpha (background fully transparent) rather than
    a second background_color, matching this bank's other trans shaders.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "trans"
kernel.name = "p5Square"

kernel.vertexData =
{
  { name = "Progress",    default = .5,  min = 0,    max = 1,   index = 0, },
  { name = "Translate_X", default = -.25, min = -1.5, max = 1.5, index = 1, },
  { name = "Translate_Y", default = -.25, min = -1.5, max = 1.5, index = 2, },
  { name = "Extra_Size",  default = 1,   min = 0,    max = 3,   index = 3, },
}


kernel.fragment =
[[

#define PI 3.14159265359

float Progress    = CoronaVertexUserData.x;
float Translate_X = CoronaVertexUserData.y;
float Translate_Y = CoronaVertexUserData.z;
float Extra_Size  = CoronaVertexUserData.w;
//----------------------------------------------

P_COLOR vec4 Col_Fill = vec4( 0.0, 0.0, 0.5, 1.0 );

float square( vec2 uv, float width )
{
    return step( max( abs( uv.x ), abs( uv.y ) ), width );
}

vec2 rotate( vec2 uv, float angle )
{
    return uv * mat2( vec2( sin( angle ), -cos( angle ) ), vec2( cos( angle ), sin( angle ) ) );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = Col_Fill;

    vec2 uv = UV * 2.0 - 1.0;
    uv += vec2( Translate_X, Translate_Y );
    uv = rotate( uv, PI * 0.25 );

    float sqr = square( uv, ( 1.0 + Extra_Size ) * Progress );

    COLOR.a = 1.0 - sqr;
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

