--[[
    Origin Author: oli4_vh
    https://godotshaders.com/author/oli4_vh/
    Picks the highest value color in a circle range as the output color.
    Fixed: uniform float size hardcoded (1.5) ignored vertexData size,
    r,g,b params had no effect. Now all four vertex params are wired:
    r,g,b tint the result, size controls radius in real-time.
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "artsy"

kernel.vertexData   = {
  { name = "R",    default = 0, min = 0, max = 1, index = 0, },
  { name = "G",    default = 0, min = 0, max = 1, index = 1, },
  { name = "B",    default = 0, min = 0, max = 1, index = 2, },
  { name = "Size", default = 1, min = 0, max = 4, index = 3, },
}

kernel.vertex =
[[
varying P_UV vec2 slot_size;
varying P_UV vec2 sample_uv_offset;
P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{
  slot_size = ( CoronaTexelSize.zw * 1.0);
  sample_uv_offset = ( slot_size * 0.5 );
  return position;
}
]]

kernel.fragment =
[[

varying P_UV vec2 slot_size;
varying P_UV vec2 sample_uv_offset;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float R    = CoronaVertexUserData.x;
  float G    = CoronaVertexUserData.y;
  float B    = CoronaVertexUserData.z;
  float Size = CoronaVertexUserData.w;

  P_UV vec2 UV = texCoord;

  // clamp size to avoid huge loops (max 4 as per vertex max)
  float size = clamp(Size, 0.0, 4.0);

  vec4 c = texture2D(CoronaSampler0, UV, 0.0);
  // early out if size ==0 : no artsy, just tint
  if (size > 0.05) {
    for (float x = -4.0; x <= 4.0; x += 1.0)
    {
      if (abs(x) > size) continue;
      for (float y = -4.0; y <= 4.0; y += 1.0)
      {
        if (abs(y) > size) continue;
        if (x*x + y*y > size*size) continue;
        vec4 new_c = texture2D( CoronaSampler0, UV+CoronaTexelSize.zw * vec2(x, y));
        if (length(new_c) > length(c)){
          c = new_c;
        }
      }
    }
  }

  // r,g,b now visibly tint the picked color (real-time)
  c.rgb += vec3(R, G, B) * 0.35;

  return CoronaColorScale( c );
}
]]
return kernel
