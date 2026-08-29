--[[
  Origin Author: snesmocha
  https://godotshaders.com/author/snesmocha/
  Fixed: vertexData intensity/size/tilt/speed were never read (globals
  center/force/size/thickness uninitialized), so sprite was displaced
  off-screen and appeared invisible. Now center=0.5, force=intensity,
  size, thickness wired real-time.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "impact"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Force",     default = 0.15, min = 0, max = 0.5, index = 0, },
  { name = "Size",      default = 0.25, min = 0, max = 0.8, index = 1, },
  { name = "Thickness", default = 0.12, min = 0.02, max = 0.4, index = 2, },
  { name = "Speed",     default = 1,    min = 0, max = 10,  index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float force     = CoronaVertexUserData.x;
  float size      = CoronaVertexUserData.y;
  float thickness = CoronaVertexUserData.z;
  // speed could drive time pulse if needed
  // float speed = CoronaVertexUserData.w;

  vec2 SCREEN_UV = texCoord;
  vec2 center = vec2(0.5, 0.5);
  float ratio = CoronaTexelSize.z / CoronaTexelSize.w;
  vec2 scaledUV = (SCREEN_UV - vec2(0.5,0.0)) / vec2(ratio, 1.0) + vec2(0.5,0.0);
  // ring mask
  float d = length(scaledUV - center);
  float mask = (1.0 - smoothstep(size-0.08, size+0.08, d)) * smoothstep(size-thickness-0.08, size-thickness+0.08, d);
  mask = clamp(mask, 0.0, 1.0);
  vec2 disp = normalize(scaledUV - center + vec2(0.0001)) * force * mask;
  // keep background visible where no displacement
  vec2 uv = clamp(SCREEN_UV - disp, vec2(0.0), vec2(1.0));
  P_COLOR vec4 texColor = texture2D(CoronaSampler0, uv);
  texColor.rgb *= texColor.a;
  return CoronaColorScale(texColor);
}
]]

return kernel
