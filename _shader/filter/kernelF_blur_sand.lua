--[[
  Origin Author: arlez80 Sand Storm (Screen Noise) MIT
  Fixed: had r,g,b,size vertexData unused, hardcoded power/speed.
  Now Progress controls power, r/g/b/size kept for compatibility but
  also drive subtle tint if desired.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "sand"

kernel.vertexData   = {
  { name = "Progress", default = 0.5, min = 0, max = 1, index = 0, },
  { name = "Size",     default = 1,   min = 0, max = 4, index = 1, },
}

kernel.isTimeDependent = true

kernel.fragment = [[

uniform float seed = 81.0;
uniform float speed = 0.1;

vec2 random( vec2 pos )
{ 
  return fract(
    sin(
      vec2(
        dot(pos, vec2(12.9898,78.233))
      , dot(pos, vec2(-148.998,-65.233))
      )
    ) * 43758.5453
  );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Progress = CoronaVertexUserData.x;
    float Size     = CoronaVertexUserData.y;
    P_UV vec2 UV_Pix = (CoronaTexelSize.zw * 0.5) + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw );
    P_UV vec2 SCREEN_UV = UV_Pix;
    float power = Progress * 0.25 * (0.5 + Size*0.5);
    float TIME = CoronaTotalTime;
    vec2 uv = SCREEN_UV + ( random( SCREEN_UV + vec2( seed - TIME * speed, TIME * speed ) ) - vec2( 0.5, 0.5 ) ) * power;
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, uv, 0.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]
return kernel
