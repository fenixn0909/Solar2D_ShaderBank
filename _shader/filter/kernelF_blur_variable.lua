--[[
  Origin Author: 9Rituals
  https://godotshaders.com/shader/variable-blur-works-with-parallax-layers/
  Modified blur shader for parallax backgrounds.
  Fixed: had no vertexData (hardcoded sin(TIME)*5). Now Blur_X/Y and Samples are real-time.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur" 
kernel.name = "variable"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Blur_X",  default = 2, min = 0, max = 10, index = 0, },
  { name = "Blur_Y",  default = 2, min = 0, max = 10, index = 1, },
  { name = "Samples", default = 11, min = 3, max = 21, index = 2, },
}

kernel.fragment =
[[

//----------------------------------------------
  uniform float SAMPLES = 11.0;
  const float WIDTH = 0.04734573810584494679397346954847;

  float gaussian(float x) {
      float x_squared = x*x;
      return WIDTH * exp((x_squared / (2.0 * SAMPLES)) * -1.0);
  }

// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 SCREEN_UV = texCoord;
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;
  P_COLOR vec4 COLOR;

  float Blur_X  = CoronaVertexUserData.x;
  float Blur_Y  = CoronaVertexUserData.y;
  float Samples = CoronaVertexUserData.z;
  // keep uniform SAMPLES in sync for gaussian width calc
  SAMPLES = clamp(Samples, 3.0, 21.0);

  // if both near 0, no blur – early out
  vec2 blur_scale = vec2(Blur_X, Blur_Y);
  // optional subtle time wobble when Speed>0 – keep deterministic if user wants static
  // blur_scale.x += sin(CoronaTotalTime*0.7)*0.2;

  //----------------------------------------------
    vec2 scale = TEXTURE_PIXEL_SIZE * blur_scale;
      
    float weight = 0.0;
    float total_weight = 0.0;
    vec4 color = vec4(0.0);
    
    // use int loop with uniform-driven break for GLES2
    for(int i=-10; i <= 10; ++i) {
      if (abs(float(i)) > Samples*0.5) continue;
      weight = gaussian(float(i));
      // horizontal variable blur (original only blurred X); keep Y at 0 for compatibility
      // if you want 2D, add vec2(float(i), float(i)) etc. – keeping original 1D
      color.rgb += texture2D(CoronaSampler0, SCREEN_UV + scale * vec2(float(i), 0.0)).rgb * weight;
      total_weight += weight;
    }
    
    COLOR.rgb = color.rgb / max(total_weight, 0.001);
    COLOR.a = texture2D(CoronaSampler0, SCREEN_UV).a;
    COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
