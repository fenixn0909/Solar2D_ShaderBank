

--[[
  Origin Author: Owl
  https://godotshaders.com/shader/white-balance-shader/
  
  the shader make the white balance effect that look samiler to the unity effect
  where the effect is wraping between 2 gradient colors (warm, cool)
  warm is 1
  cool is -1

  you can add the shader to ColorRect node and it will work fine for any thing under it
  I just edit the GDQuest Gradient Map Shader video so i can use it in any scene 
  without adding it for every single sprite and in the same time it wrabs between 2 colors

  you need to add the gradient colors by your self and put it in the shader param
  (you can learn how to make the colors from this video )
  then change the mix_amount value to 1 for warm or -1 for cool


--]]


local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "whiteBalance"

kernel.vertexData =
{
  {
    name = "intensity",
    default = 0.7,
    min = 0,
    max = 1,
    index = 0, -- v_UserData.x
  },
}

kernel.isTimeDependent = true


kernel.fragment =
[[
P_COLOR float tweener;
//----------------------------------------------
uniform vec4 warm_color = vec4(0.5, 0.2, 0, 0); //: hint_black;
uniform vec4 cool_color = vec4(0, 0.5, 1, 0); //: hint_black;
float temperature = 0;


//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  //P_UV vec2 UV_Pix = (CoronaTexelSize.zw * 0.5) + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw );
  P_COLOR vec4 COLOR;

  float intensity = CoronaVertexUserData.x;
  temperature = sin(CoronaTotalTime*1) * intensity;
  //temperature = 0.5;
  //----------------------------------------------
  vec4 input_color = texture2D( CoronaSampler0, UV, 0.0 );
    if (input_color.a < 0.01) { P_COLOR vec4 COLOR = input_color; return CoronaColorScale(COLOR); }
    
  float grayscale_value = dot(input_color.rgb, vec3(0.299, 0.587, 0.114));
  vec3 sampled_color;
  if (temperature > 0.0){
    //sampled_color = texture(warm_color, vec2(grayscale_value, 0.0)).rgb;
    sampled_color = warm_color.rgb;
    //COLOR.rgb = mix(input_color.rgb, sampled_color, temperature);

    COLOR.rgb = input_color.rgb + sampled_color * temperature;
  }
  else{
    //sampled_color = texture(cool_color, vec2(grayscale_value, 0.0)).rgb;
    sampled_color = cool_color.rgb;
    //COLOR.rgb = mix(input_color.rgb, sampled_color, temperature * -1.0);
    COLOR.rgb = input_color.rgb + sampled_color * abs(temperature);
  }
  COLOR.a = input_color.a;
  
  //----------------------------------------------

  return CoronaColorScale( COLOR );
}
]]

return kernel