
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

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'TexDiffRatioX','TexDiffRatioY','Level','Water_Opacity',
            'Water_Speed','Wave_Distortion','Wave_Multiplyer','Water_Texture_On',
            'Reflection_X_Offset','Reflection_Y_Offset','Water_Albedo_R','Water_Albedo_G',
            'Water_Albedo_B','Water_Albedo_A','','',
        },
        default = {
            1, 1, .5, .35,
            .05, .2, 7, 1,
            0, 0, .26, .23,
            .73, 1, 0,0,
        },
        min = {
            0, 0, 0, 0,
            0, 0, 1, 0,
            -.5, -.5, 0, 0,
            0, 0, 0,0,
        },
        max = {
            32, 32, 1, 1,
            .5, 1, 20, 1,
            .5, .5, 1, 1,
            1, 1, 1,1,
        },
    },
}


kernel.fragment =
[[
  uniform P_COLOR mat4 u_UserData0;

  vec2 texDiffRatio = vec2( u_UserData0[0][0], u_UserData0[0][1] );

//----------------------------------------------
  float level               = u_UserData0[0][2];
  float water_opacity        = u_UserData0[0][3];
  float water_speed          = u_UserData0[1][0];
  float wave_distortion      = u_UserData0[1][1];
  int   wave_multiplyer      = int( u_UserData0[1][2] );
  bool  water_texture_on     = u_UserData0[1][3] > 0.5;
  float reflection_X_offset  = u_UserData0[2][0];
  float reflection_Y_offset  = u_UserData0[2][1];
  vec4  water_albedo         = vec4( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0], u_UserData0[3][1] );

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





