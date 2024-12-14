
--[[
  Origin Author: laithnasa
  https://godotshaders.com/shader/2d-water-with-reflections/

  Highly customizable reflective 2D water.

  inspired by “Kingdom Two Crowns”.

  How to use:

  – Add a ColorRect (make sure it is at the bottom of the scren tree).

  – Add the shader to the ColorRect.

  – For the parameter “noise_texture” just use a default simplex noise texture.

  –  For the parameter “noise_texture2” (used for the water texture, which can be turned off) use a simplex noise texture with the parameters shown in the screenshot below.

  – Tweak the parameters to your liking and that’s it.

   

  After applying the shader to the ColorRect, it will, by default, be split vertically into two sections:

  – the upper section: which is what will be reflected in the bottom section. *

  – the bottom section: which contains the water and the reflection of the upper section.

   

  * Make sure that what you want to be reflected is inside of the upper layer of the ColorRect.

--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "deform"
kernel.name = "reflection"
kernel.isTimeDependent = true

-- Expose effect parameters using vertex data
kernel.vertexData   = {
  {
    name = "texDiffRatioX",
    default = 1,
    min = 0,
    max = 32,  
    index = 0,    
  },
  {
    name = "texDiffRatioY",
    default = 1,
    min = 0,
    max = 32,  
    index = 1,    
  },
  
}


kernel.fragment =
[[
  vec2 texDiffRatio = vec2( CoronaVertexUserData.x, CoronaVertexUserData.y );

//----------------------------------------------
  uniform float level = 0.5; // : hint_range(0.0, 1.0)
  uniform vec4 water_albedo = vec4(0.26, 0.23, 0.73, 1.0); // : hint_color
  uniform float water_opacity = 0.35; // : hint_range(0.0, 1.0)
  uniform float water_speed = 0.05;
  uniform float wave_distortion = 0.2;
  uniform int wave_multiplyer = 7; // 7.
  uniform bool water_texture_on = true;
  uniform float reflection_X_offset = 0.0;
  uniform float reflection_Y_offset = 0.0;

  float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
  }

  float getNoise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
      mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
      mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
  }

//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    // Pixelization
    P_UV vec2 FRAGCOORD = ( CoronaTexelSize.zw * 0.5 + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw ) );
    //P_UV vec2 SCREEN_UV = FRAGCOORD; // Pixelization

    P_UV vec2 UV = texCoord;
    P_UV vec2 SCREEN_UV = texCoord;
    P_UV float TIME = CoronaTotalTime;
    P_COLOR vec4 COLOR;

    
    //----------------------------------------------

      vec2 uv = UV;
      COLOR = vec4(0.0);
      
      if (uv.y >= level) {
        COLOR.a = 1.0;
        
        // distorted reflections
        vec2 water_uv = vec2(uv.x, uv.y * float(wave_multiplyer));
        water_uv *= texDiffRatio;

        float noise = texture2D( CoronaSampler1, vec2(water_uv.x + TIME * water_speed, water_uv.y)).x * wave_distortion;
        noise -= (0.5 * wave_distortion);
        
        // water texture
        if (water_texture_on) {
          float water_texture_limit = 0.35;
          vec4 water_texture = texture2D( CoronaSampler1, uv * vec2(0.5, .5) + vec2(noise, 0.0));
          float water_texture_value = (water_texture.x < water_texture_limit) ? 1.0 : 0.0;  
          COLOR.xyz = vec3(water_texture_value);

          //vec4 water_texture = vec4( getNoise( uv ) );
          //float water_texture_value = (water_texture.x < water_texture_limit) ? 1.0 : 0.0;  
          //COLOR.xyz = vec3(water_texture_value);
          


          
        }
      
        // putting everything toghether 
        vec4 current_texture = texture2D( CoronaSampler0, vec2(SCREEN_UV.x + noise + reflection_X_offset, 1.0 - SCREEN_UV.y - (level - 0.5) * 2.0 + reflection_Y_offset));
        COLOR = mix(COLOR, current_texture, 0.5);
        COLOR = mix(COLOR, water_albedo, water_opacity);
      }

    //----------------------------------------------
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel


--[[

--]]





