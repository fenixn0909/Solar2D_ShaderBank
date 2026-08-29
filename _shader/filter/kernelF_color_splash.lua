
--[[
  Origin Author: Vildravn
  https://godotshaders.com/shader/color-splash-show-only-one-color/

  the shader makes the color splash effect
  where it shows only one color in an image 
  and the rest is gray (black and white values)

  add the shader to ColorRect node
  then from the shader prem chose the color you want
  and then make the ColorRect node in the top layer
  like that the effect will work in anything on the screen

  in the shader prem, there are 3 prems
  hide = so you can hide the effect to show anything under it
  color = to chose the color you want to show only
  strength = where you chose the color range to show


--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "splash"

--Test
kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Strength", default = 0.8, min = 0, max = 1, index = 0, },
  { name = "Blend",    default = 1,   min = 0, max = 1, index = 1, },
}


kernel.fragment =
[[
uniform bool hide = false;
uniform vec4 color = vec4(1,0,1,1); //: hint_color 
float strength;


//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  //P_UV vec2 UV_Pix = (CoronaTexelSize.zw * 0.5) + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw );

  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;
  P_COLOR vec4 COLOR;
  strength = CoronaVertexUserData.x;
  float Blend = CoronaVertexUserData.y;
  //----------------------------------------------

    vec4 pixel = texture2D(CoronaSampler0, UV);
    COLOR = pixel;
    if (hide == false){ 
      vec3 grayscale_value = vec3(dot(pixel.rgb, vec3(0.299, 0.587, 0.114)));
      float range = 1.0 - step(distance(pixel.rgb, color.rgb), strength);
      COLOR.rgb = mix(pixel.rgb, grayscale_value, range);
    }

  //----------------------------------------------
  

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


