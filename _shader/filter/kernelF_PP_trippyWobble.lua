
--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/Wlj3zm

  

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "PP"
kernel.name = "trippyWobble"


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
//P_UV vec2 iResolution = vec2(resolutionX,resolutionY);
P_UV vec2 iResolution = vec2(1);
//----------------------------------------------
  const float speed = 1.;
  const float size = 3.;
  const float strengh = 0.015;


// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 fragCoord = texCoord / iResolution;
  P_COLOR vec4 COLOR;
  P_DEFAULT float iTime = CoronaTotalTime;

  //----------------------------------------------
  
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = uv * 2. - 1.;
    vec2 offset = vec2(cos(length(p * size) + iTime * speed),
                       sin(length(p * size) + iTime * speed));
    vec2 offset2 = vec2(cos(length(p * size + iTime * speed)),
                        sin(length(p * size + iTime * speed)));
    vec2 offset3 = vec2(sin(( p.x * p.y ) * size + iTime * speed),
                  cos(( p.x * p.y ) * size + iTime * speed));
    vec2 offset4 = vec2(sin( uv.x * size + iTime * speed),
                  cos( uv.y * size + iTime * speed));
    vec2 offset5 = vec2(sin( p.x * size + iTime * speed),
                  cos( p.y * size + iTime * speed));
    COLOR = texture2D( CoronaSampler0, uv + strengh * offset3 );
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


