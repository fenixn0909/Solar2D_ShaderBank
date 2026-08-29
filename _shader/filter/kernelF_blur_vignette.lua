--[[
    Blur Vignette (Post Processing / ColorRect) [Godot 4.2.1]
    https://godotshaders.com/shader/blur-vignette-post-processing-colorrect-godot-4-2-1/
    paitorocxon Dec 29, 2023
    Fixed: was intensity-only with hardcoded blur_radius/amount/inner/outer
    and used screen_texture (not CoronaSampler0) plus a mix with Col_Base
    that made vignette just a solid color. Now all four main params are
    real-time vertexData and the effect properly blurs the background.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "vignette"

kernel.isTimeDependent = false

kernel.vertexData   = {
  { name = "Blur_Amount", default = 5,   min = 0, max = 10,  index = 0, },
  { name = "Inner",       default = 0.7, min = 0, max = 1,   index = 1, },
  { name = "Outer",       default = 0.8, min = 0, max = 1.5, index = 2, },
  { name = "Radius",      default = 0.3, min = 0, max = 1,   index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Blur_Amount = CoronaVertexUserData.x;
    float Inner       = CoronaVertexUserData.y;
    float Outer       = CoronaVertexUserData.z;
    float Radius      = CoronaVertexUserData.w;

    float blur_radius = max(Radius, 0.01);
    float blur_inner  = Inner;
    float blur_outer  = max(Outer, blur_inner + 0.05);
    float blur_amount = Blur_Amount;

    // sample original
    vec4 pixelColor = texture2D(CoronaSampler0, UV);
    // simple box blur approximation using lod bias (works in Solar2D filter)
    vec4 blurColor = texture2D(CoronaSampler0, UV, blur_amount * 0.5);

    float dist = length(UV - vec2(0.5, 0.5));

    float blur = smoothstep(blur_inner - blur_radius, blur_outer, dist);

    // blend blurred vs original by vignette
    vec3 col = mix(pixelColor.rgb, blurColor.rgb, clamp(blur,0.0,1.0));

    P_COLOR vec4 COLOR = vec4(col, pixelColor.a);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
