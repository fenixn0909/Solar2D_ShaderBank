
--[[
    https://godotshaders.com/shader/yoshis-island-shimmer-heat-haze-distortion/
    Gerardo LCDF
    October 10, 2025

    Renamed from the original post's title, which references a
    trademarked game - the technique itself (flowing-noise screen
    warp, classic SNES-era heat-haze/shimmer look) is generic.

    paint1 = screen capture to distort (CoronaSampler0, feed it a
    snapshot/render-texture), paint2 = a seamless noise texture
    (CoronaSampler1). Direct port, nothing dropped.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "heatHazeShimmer"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Strength", default = .005, min = 0,   max = .05, index = 0, },
  { name = "Speed_X",  default = .1,   min = -2,  max = 2,   index = 1, },
  { name = "Speed_Y",  default = .05,  min = -2,  max = 2,   index = 2, },
}


kernel.fragment =
[[

float Strength = CoronaVertexUserData.x;
vec2  Speed     = vec2( CoronaVertexUserData.y, CoronaVertexUserData.z );

float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 noise_uv = UV + TIME * Speed;

    vec2 offset = ( texture2D( CoronaSampler1, noise_uv ).xy * 2.0 - 1.0 );
    offset *= Strength;

    vec2 distorted_uv = UV + offset;

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, distorted_uv );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

