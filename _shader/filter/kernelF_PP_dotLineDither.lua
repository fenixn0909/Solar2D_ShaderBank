--[[
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/tdBSRc
  fork of https://www.shadertoy.com/view/4sBBDK
  Fixed: duplicate vertex index (both 0), hardcoded angle/scale/amount/saturation,
  uv-before-declaration bug, and time-override of amount. Now all four
  params are real-time sliders. DOT pattern is default; switch to LINE by
  changing #define below.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "PP"
kernel.name = "dotLineDither"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Angle",      default = 20,  min = 0,   max = 90,  index = 0, },
  { name = "Scale",      default = 1.5, min = 0.1, max = 10,  index = 1, },
  { name = "Amount",     default = 4,   min = 0.5, max = 10,  index = 2, },
  { name = "Saturation", default = 1.2, min = 0,   max = 3,   index = 3, },
}

kernel.fragment =
[[
P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;
//----------------------------------------------
#define DOT
// #define LINE

float greyScale(in vec3 col) {
  return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

mat2 rotate2d(float angle){
  return mat2(cos(angle), -sin(angle), sin(angle),cos(angle));
}

// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Angle      = CoronaVertexUserData.x;
    float Scale      = CoronaVertexUserData.y;
    float Amount     = CoronaVertexUserData.z;
    float Saturation = CoronaVertexUserData.w;

    P_UV vec2 fragCoord = UV * iResolution;
    P_COLOR vec3 col = texture2D(CoronaSampler0, UV).rgb;
    // greyscale toggle via Saturation==0 could be added, keep original false
    // if (false) col = vec3(greyScale(col));

    vec2 p = rotate2d(radians(Angle)) * fragCoord * Scale * 0.05;

    float pattern;
    #ifdef LINE
    pattern = sin(p.x) * Amount;
    col = col * 10.0 * Saturation - 5.0 + pattern;
    #endif

    #ifdef DOT
    pattern = sin(p.x) * sin(p.y) * Amount;
    col = col * 10.0 * Saturation - 5.0 + pattern;
    #endif

    P_COLOR vec4 COLOR = vec4(col, 1.0);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
