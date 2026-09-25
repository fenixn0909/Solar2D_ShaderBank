--[[
  Origin Author: 9Rituals
  https://godotshaders.com/shader/variable-blur-works-with-parallax-layers/
  Modified blur shader for parallax backgrounds.
  Fixed (round 2): assigned to a `uniform` global inside the fragment
  (illegal GLSL) so it failed to compile = black sprite. Now uses
  locals only. Blur_Y finally does something (separable vertical taps
  alongside horizontal), and Process blends original -> blurred.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "variable"

kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process", default = 1, min = 0, max = 1,  index = 0, },
  { name = "Blur_X",  default = 2, min = 0, max = 10, index = 1, },
  { name = "Blur_Y",  default = 2, min = 0, max = 10, index = 2, },
  { name = "Samples", default = 11, min = 3, max = 21, index = 3, },
}

kernel.fragment =
[[

const float WIDTH_VAR = 0.04734573810584494679397346954847;

float gaussian_var( float x, float samples )
{
    float x_squared = x * x;
    return WIDTH_VAR * exp( ( x_squared / ( 2.0 * samples ) ) * -1.0 );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 SCREEN_UV = texCoord;
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;

  float Process = CoronaVertexUserData.x;
  float Blur_X  = CoronaVertexUserData.y;
  float Blur_Y  = CoronaVertexUserData.z;
  float Samples = clamp( CoronaVertexUserData.w, 3.0, 21.0 );

  vec4 orig = texture2D( CoronaSampler0, SCREEN_UV );

  vec2 stepH = TEXTURE_PIXEL_SIZE * vec2( Blur_X, 0.0 );
  vec2 stepV = TEXTURE_PIXEL_SIZE * vec2( 0.0, Blur_Y );

  float w0 = gaussian_var( 0.0, Samples );
  vec3 acc = orig.rgb * w0;
  float total = w0;

  // constant-bound separable gaussian, taps gated by Samples
  for ( int i = 1; i <= 10; i++ )
  {
      if ( float( i ) > Samples * 0.5 ) break;
      float w = gaussian_var( float( i ), Samples );
      acc += texture2D( CoronaSampler0, SCREEN_UV + stepH * float( i ) ).rgb * w;
      acc += texture2D( CoronaSampler0, SCREEN_UV - stepH * float( i ) ).rgb * w;
      acc += texture2D( CoronaSampler0, SCREEN_UV + stepV * float( i ) ).rgb * w;
      acc += texture2D( CoronaSampler0, SCREEN_UV - stepV * float( i ) ).rgb * w;
      total += w * 4.0;
  }

  vec3 blurred = acc / max( total, 0.001 );
  vec3 col = mix( orig.rgb, blurred, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
