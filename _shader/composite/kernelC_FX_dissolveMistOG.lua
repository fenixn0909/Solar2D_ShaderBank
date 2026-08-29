
--[[
  Inspire from TY Code Monkey
  https://www.youtube.com/watch?v=auglNRLM944



--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "dissolveMistOG" --With Outline Glow

--Test
kernel.isTimeDependent = true

kernel.vertexData =
{
  {
    name = "colorFadeR",
    default = 1,
    min = 0,
    max = 1,     
    index =0,    
  },
  {
    name = "colorFadeG",
    default = 1,
    min = 0,
    max = 1,     
    index = 1,    
  },
  {
    name = "colorFadeB",
    default = 1,
    min = 0,
    max = 1,     
    index = 2,    
  },
  {
    name = "slider", --The smaller the larger
    default = 1,
    min = 0,
    max = 1,
    index = 3,    
  },
}


kernel.fragment =
[[

uniform P_DEFAULT float strokeSize = 0.125; // best 0.125~0.3  :hint (0 ,1) GT 1 then color overlay one sprite 
uniform P_DEFAULT float texNoiseScaler = 0.8; 

P_COLOR vec4 colorFade = vec4( CoronaVertexUserData.x, CoronaVertexUserData.y, CoronaVertexUserData.z, 1);
P_DEFAULT float slider = CoronaVertexUserData.w;


P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{

  P_UV vec2 uvSpr = texCoord;
  P_UV vec2 uvNoise = texCoord * texNoiseScaler;
  P_COLOR vec4 colorSpr = texture2D(CoronaSampler0, uvSpr);
  P_COLOR vec4 colorNoise = texture2D(CoronaSampler1, uvNoise);

  // slider driven by Progress param (CoronaVertexUserData.w), keep as is
  
  float aInner = step(colorNoise.r, slider  );
  float aOutter = step(colorNoise.r, slider+strokeSize  );
  float aOutLine = aOutter - aInner;

  colorFade.rgb *= aOutLine;
  colorSpr.a *= aOutter;
  
  // Fade 
  colorSpr.rgb += colorFade.rgb;
  colorSpr.rgb *= colorSpr.a;

  // Shield Damaged
  //colorSpr.rgb += colorFade.rgb * colorSpr.a;

  return CoronaColorScale(colorSpr);
  //return CoronaColorScale(colorNoise);
}
]]

return kernel

--[[

--]]


