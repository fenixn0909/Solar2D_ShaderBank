--[[
  Origin Author: lurgx
  https://godotshaders.com/author/lurgx/
  Fixed: had no params (hardcoded strength 0.5/speed 2.5/angle 45) not tweakable.
  Now Strength/Speed/Angle are real-time vertex params.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "rainbowOver"
kernel.isTimeDependent = true

kernel.vertexData = {
  { name = "Strength", default = 0.5, min = 0, max = 1, index = 0, },
  { name = "Speed",    default = 2.5, min = 0, max = 10, index = 1, },
  { name = "Angle",    default = 45,  min = 0, max = 360, index = 2, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float strength = CoronaVertexUserData.x;
  float speed    = CoronaVertexUserData.y;
  float angle    = CoronaVertexUserData.z;

  P_COLOR vec4 finColor = texture2D(CoronaSampler0, texCoord);
  float hue = texCoord.x * cos(radians(angle)) - texCoord.y * sin(radians(angle));
  hue = fract(hue + fract(CoronaTotalTime * speed));
  float x = 1. - abs(mod(hue / (1./6.), 2.) - 1.);
  vec3 rainbow;
  if(hue < 1./6.){
    rainbow = vec3(1., x, 0.);
  } else if (hue < 1./3.) {
    rainbow = vec3(x, 1., 0);
  } else if (hue < 0.5) {
    rainbow = vec3(0, 1., x);
  } else if (hue < 2./3.) {
    rainbow = vec3(0., x, 1.);
  } else if (hue < 5./6.) {
    rainbow = vec3(x, 0., 1.);
  } else {
    rainbow = vec3(1., 0., x);
  }
  rainbow.rgb *= finColor.a;
  vec4 color = texture2D(CoronaSampler0, texCoord);
  finColor = mix(color, vec4(rainbow, color.a), strength);
  finColor.rgb *= finColor.a;
  return CoronaColorScale(finColor);
}
]]

return kernel
