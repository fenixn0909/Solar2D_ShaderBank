
--[[
  Origin Author: mandubian
  https://gl-transitions.com/editor/ButterflyWaveScrawler

  License: MIT

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "trans"
kernel.name = "waveScrawler"

kernel.vertexData =
{
  {
    name = "progress",
    default = .5,
    min = 0,
    max = 1,
    index = 0, 
  },
  {
    name = "amplitude",
    default = 2.0,
    min = -2,
    max = 12,
    index = 1, 
  },
  {
    name = "waves",
    default = 60,
    min = 0,
    max = 300,
    index = 2, 
  },
  {
    name = "colorSeparation",
    default = .5,
    min = 0,
    max = 100,
    index = 3, 
  },
}


kernel.fragment =
[[
float progress = CoronaVertexUserData.x;
float amplitude = CoronaVertexUserData.y;
float waves = CoronaVertexUserData.z;
float colorSeparation = CoronaVertexUserData.w;

//----------------------------------------------

vec4 colorBG = vec4(0,0,0,0);
 
float PI = 3.14159265358979323846264;

//----------------------------------------------
float compute(vec2 p, float progress, vec2 center) {
  vec2 o = p*sin(progress * amplitude)-center;
  // horizontal vector
  vec2 h = vec2(1., 0.);

  // butterfly polar function (don't ask me why this one :))
  float theta = acos(dot(o, h)) * waves;
  return (exp(cos(theta)) - 2.*cos(4.*theta) + pow(sin((2.*theta - PI) / 24.), 5.)) / 10.;
}

//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV);
  //----------------------------------------------

  vec2 p = UV.xy / vec2(1.0).xy;
  float inv = 1. - progress;
  vec2 dir = p - vec2(.5);
  float dist = length(dir);
  float disp = compute(p, progress, vec2(0.5, 0.5)) ;
  //vec4 texTo = getToColor(p + inv*disp);
  /*
  vec4 texFrom = vec4(
  getFromColor(p + progress*disp*(1.0 - colorSeparation)).r,
  getFromColor(p + progress*disp).g,
  getFromColor(p + progress*disp*(1.0 + colorSeparation)).b,
  1.0);
  return texTo*progress + texFrom*inv;
  */
  //----------------------------------------------

  vec4 texTo = colorBG;
  vec4 base = texture2D(CoronaSampler0, p + progress*disp);
  vec4 texFrom = vec4(
  texture2D( CoronaSampler0, p + progress*disp * ( 1.0 - colorSeparation )).r,
  base.g,
  texture2D( CoronaSampler0, p + progress*disp * ( 1.0 + colorSeparation )).b,
  base.a
  );

  colorBG.rgb *= colorBG.a;
  texTo.rgb *= texTo.a;
  // correctly blend from->to; at progress 0 shows original, at 1 shows transparent (background visible)
  COLOR = texTo * progress + texFrom * inv;

  //COLOR.a *= m;
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale(COLOR);
}
]]

return kernel

--[[

--]]


