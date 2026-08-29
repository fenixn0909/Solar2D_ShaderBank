local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "wobble"
kernel.name = "water2"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Speed",     default = 1,   min = 0, max = 5,   index = 0, },
  { name = "Frequency", default = 15,  min = 5, max = 60,  index = 1, },
  { name = "Amplitude", default = 0.008, min = 0, max = 0.02, index = 2, },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Speed     = CoronaVertexUserData.x;
  float Frequency = CoronaVertexUserData.y;
  float Amplitude = CoronaVertexUserData.z;

  P_UV vec2 uv = texCoord;
  // stronger water2 variant
  uv.y += (cos((uv.y + (CoronaTotalTime * 0.04 * Speed)) * Frequency) * Amplitude) +
          (cos((uv.x + (CoronaTotalTime * 0.08 * Speed)) * 12.0) * Amplitude);
  uv.x += (sin((uv.x + (CoronaTotalTime * 0.07 * Speed)) * Frequency) * Amplitude) +
          (sin((uv.y + (CoronaTotalTime * 0.1 * Speed)) * 10.0) * Amplitude);
  uv = clamp(uv, vec2(0.0), vec2(1.0));
  P_COLOR vec4 texColor = texture2D(CoronaSampler0, uv);
  return CoronaColorScale( texColor );
}
]]

return kernel
