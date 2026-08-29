--[[
      https://godotshaders.com/shader/just-chromatic-aberration/
      jecovier April 23, 2022
  Chromatic Aberration with per-channel displacement.
  Fixed: vertexData r,g,b,size were declared but fragment used hardcoded
  uniform vec2 r/g/b_displacement = (-3,0),(0,2),(3,0). Now wired:
  r -> red X, g -> green Y, b -> blue X, size -> global scale.
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "CA"

kernel.vertexData   = {
  { name = "R_Shift", default = 3,  min = -8, max = 8, index = 0, },
  { name = "G_Shift", default = 0,  min = -8, max = 8, index = 1, },
  { name = "B_Shift", default = -3, min = -8, max = 8, index = 2, },
  { name = "Scale",   default = 1,  min = 0, max = 4, index = 3, },
  { name = "Progress", default = 1, min = 0, max = 1, index = 0, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float R_Shift = CoronaVertexUserData.x;
  float G_Shift = CoronaVertexUserData.y;
  float B_Shift = CoronaVertexUserData.z;
  float Scale   = CoronaVertexUserData.w;

  // scale multiplies the displacement in texel units
  vec2 r_displacement = vec2(R_Shift, 0.0) * Scale;
  vec2 g_displacement = vec2(0.0, G_Shift) * Scale;
  vec2 b_displacement = vec2(B_Shift, 0.0) * Scale;

  P_UV vec2 uv_pix = (CoronaTexelSize.zw * 0.5) + ( floor( UV / CoronaTexelSize.zw ) * CoronaTexelSize.zw );
  P_UV vec2 SCREEN_UV = uv_pix;

  float r = texture2D(CoronaSampler0, SCREEN_UV + vec2(CoronaTexelSize.zw * r_displacement), 0.0).r;
  float g = texture2D(CoronaSampler0, SCREEN_UV + vec2(CoronaTexelSize.zw * g_displacement), 0.0).g;
  float b = texture2D(CoronaSampler0, SCREEN_UV + vec2(CoronaTexelSize.zw * b_displacement), 0.0).b;
  float a = texture2D(CoronaSampler0, SCREEN_UV).a;

  P_COLOR vec4 COLOR = vec4(r, g, b, a);
  return CoronaColorScale( COLOR );
}
]]
return kernel
