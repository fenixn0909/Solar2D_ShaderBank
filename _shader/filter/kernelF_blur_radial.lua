--[[
  Origin Author: arlez80
  Radial Blur by Yui Kinomoto MIT
  Fixed: had gridAmount/paletteRowCols unused, hardcoded
  blur_power = sin(TIME)*0.4. Now Progress controls blur.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "radial"

kernel.vertexData =
{
  { name = "Progress", default = 0, min = 0, max = 1, index = 0, },
  { name = "Samples",  default = 6, min = 1, max = 12, index = 1, },
}

kernel.isTimeDependent = true

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Progress = CoronaVertexUserData.x;
  float SamplesF = CoronaVertexUserData.y;
  int sampling_count = int(clamp(SamplesF,1.0,12.0));
  float blur_power = Progress * 0.35;
  // optional subtle time pulse when Progress >0
  blur_power *= (0.9 + 0.1 * sin(CoronaTotalTime*2.0));

  vec2 blur_center = vec2(0.5, 0.5);
  P_UV vec2 UV_Pix = (CoronaTexelSize.zw * 0.5) + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw );
  P_UV vec2 SCREEN_UV = UV_Pix;
  vec2 direction = SCREEN_UV - blur_center;
  vec3 c = vec3(0.0);
  float f = 1.0 / float(sampling_count);
  for(int i=0; i < 12; i++){
    if(i >= sampling_count) break;
    c += texture2D(CoronaSampler0, SCREEN_UV - blur_power * direction * float(i)).rgb * f;
  }
  P_COLOR vec4 COLOR = vec4(c, texture2D(CoronaSampler0, SCREEN_UV).a);
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale(COLOR);
}
]]

return kernel
