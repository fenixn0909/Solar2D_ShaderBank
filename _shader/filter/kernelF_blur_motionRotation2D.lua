--[[
  Original Author : hayden
  https://godotshaders.com/author/hayden/

  Rotational (spin) motion blur for sprites.
  Fixed (round 2): the old version scaled the mesh in a custom vertex
  shader, animated the pivot with a hardcoded sin(TIME) test line, had a
  junk paletteRowCols param, and used a dynamic loop bound (GLES compile
  risk). Rebuilt as a fragment-only blur: no vertex stage, no overrides,
  constant-bound taps. Params: Angle (total spin spread in degrees),
  Samples (tap count), Center_X / Center_Y (spin pivot), Process
  (sharp -> spinning).
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "motionRotation2D"
kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Angle','Samples','',
            'Center_X','Center_Y','','',
            '','','','',
            '','','','',
        },
        default = {
            1,24,8,0,
            0.5,0.5,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,2,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,120,16,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Process  = u_UserData0[0][0];
float Angle    = u_UserData0[0][1];
float SamplesF = u_UserData0[0][2];
vec2  Pivot    = vec2( u_UserData0[1][0], u_UserData0[1][1] );

vec2 rotate_mr( vec2 uv, vec2 p, float angle )
{
  float c = cos( angle );
  float s = sin( angle );
  mat2 rotation = mat2( vec2( c, -s ), vec2( s, c ) );
  uv -= p;
  uv = uv * rotation;
  uv += p;
  return uv;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  vec4 orig = texture2D( CoronaSampler0, texCoord );

  int Samples = int( clamp( SamplesF + 0.5, 2.0, 16.0 ) );
  float stepA = radians( Angle ) / float( Samples );

  vec3 acc = orig.rgb;
  float acA = orig.a;
  // constant-bound taps, gated by Samples
  for ( int i = 1; i <= 16; i++ )
  {
      if ( i > Samples ) break;
      float a = stepA * float( i );
      vec4 s1 = texture2D( CoronaSampler0, rotate_mr( texCoord, Pivot, a ) );
      vec4 s2 = texture2D( CoronaSampler0, rotate_mr( texCoord, Pivot, -a ) );
      acc += s1.rgb + s2.rgb;
      acA += s1.a + s2.a;
  }
  float n = float( Samples ) * 2.0 + 1.0;
  vec4 blurred = vec4( acc / n, acA / n );

  vec4 outc = mix( orig, blurred, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = outc;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel
