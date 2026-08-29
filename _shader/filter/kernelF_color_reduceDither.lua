--[[
  Origin Author: Vildravn
  https://godotshaders.com/shader/color-reduction-and-dither/
  Reduces values per RGB-channel. Fixed: progress was declared but not
  used (colors/dither hardcoded). Now Colors and Dither are real-time
  via vertexData, and Blend controls mix with original.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "reduceDither"

kernel.vertexData =
{
  { name = "Colors", default = 4,   min = 2, max = 16, index = 0, },
  { name = "Dither", default = 0.2, min = 0, max = 0.5, index = 1, },
  { name = "Blend",  default = 1,   min = 0, max = 1,  index = 2, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float colors = CoronaVertexUserData.x;
  float dither = CoronaVertexUserData.y;
  float blend  = CoronaVertexUserData.z;
  colors = clamp(colors, 2.0, 16.0);
  P_UV vec2 UV = texCoord;
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;
  vec4 orig = texture2D(CoronaSampler0, UV);
  float a = floor(mod(UV.x / TEXTURE_PIXEL_SIZE.x, 2.0));
  float b = floor(mod(UV.y / TEXTURE_PIXEL_SIZE.y, 2.0));
  float c = mod(a + b, 2.0);
  vec4 dithered;
  dithered.r = (floor((orig.r * colors + dither) + 0.5) / colors) * c;
  dithered.g = (floor((orig.g * colors + dither) + 0.5) / colors) * c;
  dithered.b = (floor((orig.b * colors + dither) + 0.5) / colors) * c;
  c = 1.0 - c;
  dithered.r += (floor((orig.r * colors - dither) + 0.5) / colors) * c;
  dithered.g += (floor((orig.g * colors - dither) + 0.5) / colors) * c;
  dithered.b += (floor((orig.b * colors - dither) + 0.5) / colors) * c;
  dithered.a = orig.a;
  P_COLOR vec4 COLOR = mix(orig, dithered, clamp(blend,0.0,1.0));
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale(COLOR);
}
]]

return kernel
