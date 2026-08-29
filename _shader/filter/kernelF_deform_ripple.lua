--[[
  Origin Author: Nevoski
  https://godotshaders.com/author/Nevoski/
  Converted from ShaderToy https://www.shadertoy.com/view/ldBXDD ripple.
  Fixed: hardcoded wave_count=2000, speed=3, height=0.003 and
  height = sin(TIME)*0.1 override ignored vertexData screenPxX/Y/tilt/speed.
  Now: X=Wave_Count, Y=Speed, Z=Tilt (height), W=Center_Offset are real-time.
  Also removed erroneous u_resolution/gl_FragCoord uniforms; use
  CoronaTexelSize + CoronaTotalTime like other time-dependent filters.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "ripple"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Wave_Count", default = 12, min = 1, max = 40, index = 0, },
  { name = "Speed",      default = 3,  min = 0, max = 10, index = 1, },
  { name = "Height",     default = 0.03, min = 0, max = 0.15, index = 2, },
  { name = "Center_X",   default = 0.5, min = 0, max = 1, index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Wave_Count = CoronaVertexUserData.x;
  float Speed      = CoronaVertexUserData.y;
  float Height     = CoronaVertexUserData.z;
  float Center_X   = CoronaVertexUserData.w; // reuse as center.x, y fixed 0.5

  P_DEFAULT float TIME = CoronaTotalTime;
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;

  P_UV vec2 UV = texCoord;
  // center in UV space, allow horizontal shift via Center_X
  vec2 center = vec2(Center_X, 0.5);
  vec2 cPos = -1.0 + 2.0 * (UV - center) / (1.0 / TEXTURE_PIXEL_SIZE * TEXTURE_PIXEL_SIZE.x);
  // simpler: use UV distance from center
  vec2 dUV = UV - center;
  float cLength = length(dUV * vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y) * 0.002);
  // use wave_count directly
  vec2 uv = UV + normalize(dUV + vec2(0.0001)) * cos(cLength * Wave_Count - TIME * Speed) * Height * 0.5;
  uv = clamp(uv, vec2(0.0), vec2(1.0));
  vec4 tex = texture2D(CoronaSampler0, uv);
  // preserve original texture alpha; no black opaque where no ripple
  P_COLOR vec4 COLOR = tex;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel
