--[[
  Origin Author: lurgx
  https://godotshaders.com/author/lurgx/
  Flash for sprite – hit/low-health.
  Fixed: vertex shader moved but never applied, fragment had hardcoded
  color (1,0,0) and time. Now Flash_Color/Intensity and Speed are
  real-time vertex params.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "flash"
kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Flash_R','Flash_G','Flash_B','Flash_A',
            'Intensity','Speed','','',
            '','','','',
            '','','','',
        },
        default = { 1,0,0,1, .7,1,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,1,1,1, 1,10,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
vec4 Flash_Color = vec4(u_UserData0[0][0], u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3]);
float Intensity = u_UserData0[1][0];
float Speed     = u_UserData0[1][1];

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_COLOR vec4 finColor = texture2D(CoronaSampler0, texCoord);
  float pulse = abs(cos(CoronaTotalTime * Speed));
  finColor.rgb += Flash_Color.rgb * pulse * Intensity * finColor.a;
  finColor.rgb *= finColor.a;
  return CoronaColorScale(finColor);
}
]]

return kernel
