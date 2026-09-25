
--[[
    https://godotshaders.com/shader/color-remap-shader-palette-swapper/
    Sm0ke_
    September 25, 2025

    paint1 = the sprite to recolor (CoronaSampler0), paint2 = a 1D (or
    thin 2D) gradient strip texture (CoronaSampler1) - the sprite is
    grayscaled and used as a lookup coordinate into the gradient, same
    as the original. Direct port, nothing dropped.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "color"
kernel.name = "paletteRemap"


kernel.vertexData =
{
  { name = "Mix", default = 1, min = 0, max = 1, index = 0, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Mix = CoronaVertexUserData.x;
    P_COLOR vec4 textura = texture2D( CoronaSampler0, UV );
    float grayValue = ( textura.r + textura.g + textura.b ) / 3.0;
    vec2 new_uv = vec2( grayValue );
    P_COLOR vec4 gradient_color = texture2D( CoronaSampler1, new_uv );
    P_COLOR vec4 remapped = vec4( gradient_color.rgb, textura.a );
    P_COLOR vec4 COLOR = mix(textura, remapped, clamp(Mix,0.0,1.0));
    COLOR.a = textura.a;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

