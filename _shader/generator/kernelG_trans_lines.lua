
--[[
  Origin Author: exuin
  https://godotshaders.com/author/exuin/

  Here is a simple lines screen transition. Change progress to change how far along the lines are.

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "trans"
kernel.name = "lines"


kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Lines','Thickness','Slant',
            'ColorA_R','ColorA_G','ColorA_B','ColorA_A',
            'ColorB_R','ColorB_G','ColorB_B','ColorB_A',
            'Glow','','','',
        },
        default = {
            .5,20,.5,0,
            1,1,1,1,
            0,1,0,1,
            .5,0,0,0,
        },
        min = {
            0,0,.05,-2,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1000,.95,2,
            1,1,1,1,
            1,1,1,1,
            2,0,0,0,
        },
    },
}


kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float progress = u_UserData0[0][0];
float num_lines = u_UserData0[0][1];
float thickness = u_UserData0[0][2];
float slant = u_UserData0[0][3];
vec4 line_color_a = vec4(u_UserData0[1][0],u_UserData0[1][1],u_UserData0[1][2],u_UserData0[1][3]);
vec4 line_color_b = vec4(u_UserData0[2][0],u_UserData0[2][1],u_UserData0[2][2],u_UserData0[2][3]);
float Glow = u_UserData0[3][0];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_COLOR vec4 finColor;

  // Slanted UVs so Angle/Slant adds diagonal interest.
  vec2 suv = texCoord;
  suv.x = fract( suv.x + suv.y * slant * 0.5 );

  vec2 tiled_uv = vec2(fract(suv.x * num_lines / 2.), suv.y);
  float edge = thickness;
  if (tiled_uv.x < edge){
    if(tiled_uv.y < progress){
      finColor = line_color_a;
    } else {
      finColor = vec4(0.0);
    }
  } else {
    if (tiled_uv.y > 1. - progress){
      finColor = line_color_b;
    } else {
      finColor = vec4(0.0);
    }
  }
  // Soft glow lift near the wipe frontier for extra interest.
  float frontier = min( abs( suv.y - progress ), abs( ( 1.0 - suv.y ) - progress ) );
  float glowBand = exp( -frontier * frontier * 220.0 ) * Glow;
  finColor.rgb += ( line_color_a.rgb + line_color_b.rgb ) * 0.5 * glowBand * step( 0.001, finColor.a + glowBand );
  finColor.a = max( finColor.a, clamp( glowBand, 0.0, 1.0 ) * 0.6 );
  //----------------------------------------------
  return CoronaColorScale(finColor);
}
]]

return kernel

--[[



--]]


