--[[
  Origin Author: Owl
  https://godotshaders.com/shader/white-balance-shader/

  Warm / cool white balance grade.
  Rebuilt: temperature was a hardcoded `sin(TIME)*intensity` sweep, so
  the single slider couldn't hold a look. Now Temperature (-1 cool ..
  +1 warm) holds still, Speed adds an optional slow drift around it,
  Intensity scales the grade, and Process blends original -> graded.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "whiteBalance"

kernel.vertexData =
{
  { name = "Process",     default = 1,   min = 0,  max = 1, index = 0, },
  { name = "Temperature", default = 0.4,  min = -1, max = 1, index = 1, },
  { name = "Speed",       default = 0,    min = 0,  max = 5, index = 2, },
  { name = "Intensity",   default = 0.7,  min = 0,  max = 1, index = 3, },
}

kernel.isTimeDependent = true

kernel.fragment =
[[
const P_COLOR vec4 warm_color = vec4(0.5, 0.2, 0.0, 0.0);
const P_COLOR vec4 cool_color = vec4(0.0, 0.5, 1.0, 0.0);

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );

  float Process     = CoronaVertexUserData.x;
  float Temperature = CoronaVertexUserData.y;
  float Speed       = CoronaVertexUserData.z;
  float Intensity   = CoronaVertexUserData.w;

  // manual grade + optional drift; Speed = 0 holds perfectly still
  float temp = Temperature;
  if ( Speed > 0.01 ) { temp += sin( CoronaTotalTime * Speed ) * 0.35; }
  temp = clamp( temp, -1.0, 1.0 ) * clamp( Intensity, 0.0, 1.0 );

  vec3 graded;
  if ( temp > 0.0 )
  {
      graded = orig.rgb + warm_color.rgb * temp;
  }
  else
  {
      graded = orig.rgb + cool_color.rgb * abs( temp );
  }

  vec3 col = mix( orig.rgb, graded, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
