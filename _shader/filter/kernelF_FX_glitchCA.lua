--[[
  2D Sprite “Cartridge Tilting Glitch”

  Origin Author: sashatouille
  https://godotshaders.com/author/sashatouille/


  A small shader that can be attached to a sprite. 
  This shader will allow you to simulate the graphical glitches that we could see on the old consoles when we touched the cartridge in the middle of a game!
  Works event better with a sprite sheet animated sprite (see screenshots).

  

--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "glitchCT"
kernel.isTimeDependent = true


kernel.uniformData = {
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Red_Displacement','Green_Displacement','Blue_Displacement',
            'Intensity','Scan_Effect','Distortion_Effect','Negative_Effect',
            '','','','',
            '','','','',
        },
        default = { 1,.5,3,10,  100,.2,1,1,  0,0,0,0,  0,0,0,0, },
        min =     { 0,-1,-1,-1, 0,0,0,0,      0,0,0,0,  0,0,0,0, },
        max =     { 1,1,1,1,    300,1,1,1,    1,1,1,1,  1,1,1,1, },
    },
}
kernel.fragment = 
[[
uniform P_COLOR mat4 u_UserData0;

float Progress             = u_UserData0[0][0];
float red_displacement     = u_UserData0[0][1];
float green_displacement   = u_UserData0[0][2];
float blue_displacement    = u_UserData0[0][3];
float intensity             = u_UserData0[1][0];
float scan_effect           = u_UserData0[1][1];
float distortion_effect     = u_UserData0[1][2];
float negative_effect       = u_UserData0[1][3];
float ghost = 0.0;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_DEFAULT float TIME = CoronaTotalTime;
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 COLOR;

  float v_offRate = 0.2;
  float v_offSet = 0.1;

  ghost = abs(sin(CoronaTotalTime*50))*0.5;
  //scan_effect = abs(sin(CoronaTotalTime*5))*1;
  //negative_effect = abs(sin(CoronaTotalTime))*1;

  vec4 baseTexture = texture2D(CoronaSampler0, UV);
  vec4 color1 = texture2D(CoronaSampler0, UV+vec2(sin(TIME*0.2*intensity), tan(UV.y)));
  COLOR = (1.0-scan_effect)*baseTexture*0.75 + scan_effect*color1;
  
  vec4 color2 = texture2D(CoronaSampler0, UV+vec2(fract(TIME*0.01*intensity), cos(fract(TIME*intensity)*10.0)));
  COLOR = COLOR + ((1.0-distortion_effect)*baseTexture*0.75 + distortion_effect*color2);
  
  vec4 color3 = texture2D(CoronaSampler0, UV + vec2(fract(TIME*0.1*intensity), tan(TIME*0.02*intensity) ));
  COLOR = COLOR - ((1.0-negative_effect)*baseTexture*0.5 + negative_effect*color3);
  
  COLOR.r = (1.0-red_displacement)*baseTexture.r + red_displacement*texture2D(CoronaSampler0, UV-vec2(sin(TIME*intensity)*v_offRate - v_offSet, v_offSet) ).r;
  COLOR.g = (1.0-green_displacement)*baseTexture.g +  green_displacement*texture2D(CoronaSampler0, UV+vec2(- 0.05, sin(TIME*intensity) *v_offRate- 0.05 )  ).g;
  COLOR.b = (1.0-blue_displacement)*baseTexture.b + blue_displacement*texture2D(CoronaSampler0, UV+vec2(sin(TIME*intensity)*v_offRate - v_offSet, cos(TIME*intensity)*0.1) + v_offSet ).b;
  COLOR = COLOR + texture2D(CoronaSampler0, UV + UV*ghost)*ghost;
  COLOR = mix( baseTexture, COLOR, Progress );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale(COLOR);
}

]]
return kernel

--[[



--]]