--[[
  Origin Author: SamuelWolfang
  https://godotshaders.com/shader/five-nights-at-freddys-style-fisheye/
  Fixed: had no vertexData, hardcoded coeff = sin(TIME)*2, not tweakable.
  Now Coeff is real-time vertex param, time still drives subtle pulse.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fisheyeNite5"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Coeff", default = 0.25, min = 0, max = 0.5, index = 0, },
  { name = "Speed", default = 1,    min = 0, max = 5,   index = 1, },
}

kernel.fragment =
[[

#define PI 3.14159265359

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Coeff = CoronaVertexUserData.x;
    float Speed = CoronaVertexUserData.y;
    // add subtle time pulse if desired: Coeff += sin(CoronaTotalTime*Speed)*0.05
    float coeff = Coeff + sin(CoronaTotalTime * Speed) * 0.02;

    P_UV vec2 SCREEN_UV = texCoord;
    P_COLOR vec4 COLOR;
    //----------------------------------------------
      vec2 suv = SCREEN_UV;
      float side = (SCREEN_UV.y * 2.0) - 1.0;
      float mountain = -abs((SCREEN_UV.x * 2.0) - 1.0) + 1.0;
      mountain = mountain * PI/2.0;
      float newv = coeff * sin(mountain);
      suv.y += ((newv * side) - (coeff*side));
      COLOR = texture2D(CoronaSampler0, suv);
    //----------------------------------------------
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
