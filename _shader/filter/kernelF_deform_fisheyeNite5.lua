--[[
  Origin Author: SamuelWolfang
  https://godotshaders.com/shader/five-nights-at-freddys-style-fisheye/
  Fixed: had no vertexData, hardcoded coeff = sin(TIME)*2, not tweakable.
  Round 2 (improve + fun): the time pulse amplitude was a fixed 0.02 and
  there was no way to fade the effect. Now Wobble controls the pulse
  (0 = static fisheye) and Process blends original -> fisheye.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fisheyeNite5"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,    min = 0, max = 1,   index = 0, },
  { name = "Coeff",   default = 0.25, min = 0, max = 0.8, index = 1, },
  { name = "Speed",   default = 1,    min = 0, max = 5,   index = 2, },
  { name = "Wobble",  default = 0.02, min = 0, max = 0.2, index = 3, },
}

kernel.fragment =
[[

#define PI 3.14159265359

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Process = CoronaVertexUserData.x;
    float Coeff   = CoronaVertexUserData.y;
    float Speed   = CoronaVertexUserData.z;
    float Wobble  = CoronaVertexUserData.w;

    float coeff = Coeff + sin( CoronaTotalTime * Speed ) * Wobble;

    vec4 orig = texture2D( CoronaSampler0, texCoord );

    vec2 suv = texCoord;
    float side = ( texCoord.y * 2.0 ) - 1.0;
    float mountain = -abs( ( texCoord.x * 2.0 ) - 1.0 ) + 1.0;
    mountain = mountain * PI / 2.0;
    float newv = coeff * sin( mountain );
    suv.y += ( ( newv * side ) - ( coeff * side ) );
    vec4 warped = texture2D( CoronaSampler0, suv );

    vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
