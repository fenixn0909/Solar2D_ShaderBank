--[[
  Origin Author: QueenOfSquiggles https://godotshaders.com/shader/fnaf-faked-3d-displacement-shader/
  Fixed: had hardcoded scroll = sin(TIME)*0.1 not tweakable, and
  texDiffRatio only X/Y. Now exposes Scroll and Displacement_Scale
  as real-time params, and background remains visible where displaced
  UV is outside 0..1.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "deform"
kernel.name = "fake3d"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Scroll",      default = 0,   min = -0.5, max = 0.5, index = 0, },
  { name = "Disp_Scale",  default = 1,   min = 0, max = 3, index = 1, },
  { name = "Scale",       default = 0.5, min = 0.1, max = 1, index = 2, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Scroll     = CoronaVertexUserData.x;
  float Disp_Scale = CoronaVertexUserData.y;
  float Scale      = CoronaVertexUserData.z;
  // allow auto scroll if Speed param is 0
  float autoScroll = sin(CoronaTotalTime * 0.5) * 0.02;
  float scroll = Scroll + autoScroll * step(abs(Scroll), 0.001);

  P_UV vec2 UV = texCoord;
  vec2 uv = (UV - 0.5) * Scale + 0.5;
  uv = uv + vec2(scroll, 0.0);
  float disp = texture2D(CoronaSampler1, uv).r;
  disp *= Disp_Scale;
  disp *= (0.5 - uv.y);
  vec2 displaced = uv + vec2(0.0, disp);
  // keep background where displaced outside
  if (displaced.x < 0.0 || displaced.x > 1.0 || displaced.y < 0.0 || displaced.y > 1.0) {
      P_COLOR vec4 COLOR = texture2D(CoronaSampler0, UV);
      COLOR.rgb *= COLOR.a;
      return CoronaColorScale(COLOR);
  }
  P_COLOR vec4 COLOR = texture2D(CoronaSampler0, displaced);
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale(COLOR);
}
]]

return kernel
