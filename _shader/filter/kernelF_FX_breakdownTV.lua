
--[[
  
  Origin Author:  PGRacer
  https://www.shadertoy.com/view/DlSGzz

  

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "breakdownTV"


kernel.isTimeDependent = true

kernel.vertexData =
{
  {
    name = "resolutionX",
    default = 1,
    min = 1,
    max = 99,
    index = 0, 
  },
  {
    name = "resolutionY",
    default = 1,
    min = 1,
    max = 99,
    index = 1, 
  },
}


kernel.fragment =
[[
P_DEFAULT float resolutionX = CoronaVertexUserData.x;
P_DEFAULT float resolutionY = CoronaVertexUserData.y;
P_UV vec2 iResolution = vec2(resolutionX,resolutionY);
//----------------------------------------------
  
// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 fragCoord = texCoord / iResolution;
  P_COLOR vec4 COLOR;
  P_DEFAULT float iTime = CoronaTotalTime;

  //----------------------------------------------
  
    float shift = 32.0; // 32, affect texture color
    float offset = -2.0; // -2.0positive make dark

    //vec2 uv = fragCoord/iResolution.xy;
    vec2 uv = fragCoord;

    vec4 srcSample = texture2D(CoronaSampler0, uv);
    vec3 col = srcSample.rgb;
    
    // Use +-uv.x to go LR, +-uv.y go UD
    float l = sin((iTime * 0.2 - uv.y) * 20.0);
    l = l * 0.5 + 0.5;
    l = pow(l, 2.0);
    
    float divisor = (l * shift) + offset;
    divisor = abs(divisor) < 0.1 ? ( divisor < 0.0 ? -0.1 : 0.1 ) : divisor; // guard against the exact zero-crossing
    col *= divisor;
    col = floor(col);
    col /= divisor;
    
    COLOR = vec4(col, srcSample.a);
    COLOR.rgb *= COLOR.a;

  //----------------------------------------------
  //COLOR.a *= alpha;
  //COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


