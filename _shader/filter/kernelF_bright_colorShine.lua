--[[
  Origin Author: 9exa
  https://godotshaders.com/shader/2d-shine-highlight/

  Diagonal shine band sweeping across the sprite.
  Fixed: the 4 params were boring texWidth/texHeight/screenWidth/
  screenHeight (defaults of 64 broke the gl_FragCoord math), and the
  shine color/speed/size were hardcoded uniforms. Removed all 4 and
  added fun tweakings: Speed (sweep rate), Width (band size),
  Angle (sweep direction), Process (original -> shine).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "bright"
kernel.name = "colorShine"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,    min = 0,   max = 1,   index = 0, },
  { name = "Speed",   default = 0.6,  min = 0,   max = 3,   index = 1, },
  { name = "Width",   default = 0.18, min = 0.02, max = 0.6, index = 2, },
  { name = "Angle",   default = 45,   min = -180, max = 180, index = 3, },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;

  float Process = CoronaVertexUserData.x;
  float Speed   = CoronaVertexUserData.y;
  float Width   = CoronaVertexUserData.z;
  float Angle   = CoronaVertexUserData.w;

  P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

  vec2 dir = vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) );
  float proj = dot( UV - vec2( 0.5 ), dir );

  float sweep = mix( -0.9, 0.9, fract( CoronaTotalTime * Speed * 0.25 ) );
  float band = smoothstep( Width, 0.0, abs( proj - sweep ) );

  vec3 shine_color = vec3( 1.0, 0.9, 0.7 );
  vec3 col = mix( tex.rgb, shine_color * tex.a, band * 0.85 * clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, tex.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}

]]

return kernel


--[[

--]]
