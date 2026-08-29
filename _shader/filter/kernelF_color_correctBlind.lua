--[[
  Origin Author: Vildravn
  https://godotshaders.com/shader/colorblindness-correction-shader/
  Corrects protanopia/deuteranopia/tritanopia via Daltonize.
  Fixed: vertexData progress was declared but fragment used hardcoded
  uniform int mode=2 and intensity=1.0, never reading CoronaVertexUserData.
  Now mode (0..2) and intensity (0..1) are real-time vertex params,
  progress blends original vs corrected.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "correctBlind"

kernel.vertexData =
{
  { name = "Mode",      default = 2,   min = 0, max = 2, index = 0, },
  { name = "Intensity", default = 1,   min = 0, max = 1, index = 1, },
  { name = "Blend",     default = 1,   min = 0, max = 1, index = 2, },
}

kernel.fragment =
[[
int   Mode      = int(CoronaVertexUserData.x + 0.5);
float Intensity = CoronaVertexUserData.y;
float Blend     = CoronaVertexUserData.z;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 COLOR;
  vec4 tex = texture2D( CoronaSampler0, UV );

    float L = (17.8824 * tex.r) + (43.5161 * tex.g) + (4.11935 * tex.b);
    float M = (3.45565 * tex.r) + (27.1554 * tex.g) + (3.86714 * tex.b);
    float S = (0.0299566 * tex.r) + (0.184309 * tex.g) + (1.46709 * tex.b);

    float l, m, s;
    if (Mode == 0) // Protanopia
    {
      l = 0.0 * L + 2.02344 * M + -2.52581 * S;
      m = 0.0 * L + 1.0 * M + 0.0 * S;
      s = 0.0 * L + 0.0 * M + 1.0 * S;
    } else if (Mode == 1) // Deuteranopia
    {
      l = 1.0 * L + 0.0 * M + 0.0 * S;
      m = 0.494207 * L + 0.0 * M + 1.24827 * S;
      s = 0.0 * L + 0.0 * M + 1.0 * S;
    } else // Tritanopia (default 2)
    {
      l = 1.0 * L + 0.0 * M + 0.0 * S;
      m = 0.0 * L + 1.0 * M + 0.0 * S;
      s = -0.395913 * L + 0.801109 * M + 0.0 * S;
    }

    vec4 error;
    error.r = (0.0809444479 * l) + (-0.130504409 * m) + (0.116721066 * s);
    error.g = (-0.0102485335 * l) + (0.0540193266 * m) + (-0.113614708 * s);
    error.b = (-0.000365296938 * l) + (-0.00412161469 * m) + (0.693511405 * s);
    error.a = 1.0;
    vec4 diff = tex - error;
    vec4 correction;
    correction.r = 0.0;
    correction.g =  (diff.r * 0.7) + (diff.g * 1.0);
    correction.b =  (diff.r * 0.7) + (diff.b * 1.0);
    correction = tex + correction;
    correction.a = tex.a * Intensity;

    COLOR = mix(tex, correction, clamp(Blend,0.0,1.0));

  return CoronaColorScale( COLOR );
}
]]

return kernel
