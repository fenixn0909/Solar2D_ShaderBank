--[[
    https://godotshaders.com/shader/shining-sprite-effect/
    CasualGarageCoder
    December 4, 2022

]]
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "bright"
kernel.name = "shine"
kernel.isTimeDependent = true

kernel.uniformData = 
{
    {
    name = "matAimC",
    type="mat4",
    index = 0,
    paramName = {
      'Speed','Span','','',
      '','','','',
      '','','','',
      '','','','',
    },
    default = {
      0.5, 0.2, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
    min = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    max = {
      10.0, 10.0, 10.0, 10.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
  },
  {
    name = "matToC",
    type="mat4",
    index = 1,
    paramName = {
      '','','','',
      '','','','',
      '','','','',
      '','','','',
    },
    default = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    min = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    max = {
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
  },
}

kernel.fragment =
[[
#define PI 3.141516

uniform P_COLOR mat4 u_UserData0; 
//uniform P_COLOR mat4 u_UserData1;

P_DEFAULT float speed = u_UserData0[0][0];
P_DEFAULT float span = u_UserData0[0][1];

P_COLOR vec4 tintColor = vec4( 0.9, 0.6, 0.2, 1.0 );


P_DEFAULT float luminance(P_COLOR vec4 colour) {
  return 1.0 - sqrt(0.299*colour.r*colour.r + 0.587*colour.g*colour.g + 0.114*colour.b*colour.b);
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  P_COLOR vec4 texColor = texture2D( CoronaSampler0, texCoord ); 
  
  //P_DEFAULT float timer = CoronaTotalTime * PI * speed;
  P_DEFAULT float timer = mod(CoronaTotalTime * PI , 1 )  * speed;

  //Tween Color
  //tintColor.r = max(sin(CoronaTotalTime * 3), 0.5);
  //tintColor.g = max(sin(CoronaTotalTime * 7), 0.5);
  //tintColor.b = max(sin(CoronaTotalTime * 5), 0.5);

  //Tween UV Color
  //tintColor.r = max(sin(CoronaTotalTime * 3), 0.15) + UV.x*1;
  //tintColor.g = max(cos(CoronaTotalTime * 7), 0.15) + UV.y*1;
  //tintColor.b = max(sin(CoronaTotalTime * 5), 0.15) + sqrt(UV.x*UV.y)*1;

  //UV Color
  //tintColor.r = max(0.5, tintColor.r * UV.x*1);
  //tintColor.g = max(0.5, tintColor.g * UV.y*1);
  //tintColor.b = max(0.5, tintColor.b * sqrt(UV.x*UV.y)*1);

  //Corss Color UV
  //tintColor.r = sqrt( tintColor.r * texColor.r * UV.x*2 + 0.35);
  //tintColor.g = sqrt( tintColor.g * texColor.g * UV.y*2 + 0.35);
  //tintColor.b = sqrt( tintColor.b * texColor.b * sqrt(UV.x*UV.y)*2 + 0.35);

  
  //Corss Color
  //tintColor.r = min( 1.0, sqrt( tintColor.r * (1-texColor.r) ) * tintColor.r+0.1 );
  //tintColor.g = min( 1.0, sqrt( tintColor.g * (1-texColor.g) ) * tintColor.g+0.1 );
  //tintColor.b = min( 1.0, sqrt( tintColor.b * (1-texColor.b) ) * tintColor.b+0.1 );

  //Corss Color - Great
  //tintColor.r = min( 1.0, sqrt( tintColor.r * (1-texColor.g) ) * tintColor.g+0.1 );
  //tintColor.g = min( 1.0, sqrt( tintColor.g * (1-texColor.b) ) * tintColor.b+0.1 );
  //tintColor.b = min( 1.0, sqrt( tintColor.b * (1-texColor.r) ) * tintColor.r+0.1 );

  //Corss Color UV 
  //float rtUv = 0.7;
  //tintColor.r = min( 1.0, sqrt( tintColor.r * (1-texColor.g) ) * tintColor.g + UV.x*rtUv );
  //tintColor.g = min( 1.0, sqrt( tintColor.g * (1-texColor.b) ) * tintColor.b - UV.y*rtUv );
  //tintColor.b = min( 1.0, sqrt( tintColor.b * (1-texColor.r) ) * tintColor.r + sqrt(UV.x*UV.y)*rtUv );

  //Corss Color UV 
  float rtUv = 0.7;
  tintColor.r = min( 1.0, sqrt( tintColor.r * (1-texColor.r) ) * tintColor.r + UV.x*rtUv );
  tintColor.g = min( 1.0, sqrt( tintColor.g * (1-texColor.g) ) * tintColor.g - UV.y*rtUv );
  tintColor.b = min( 1.0, sqrt( tintColor.b * (1-texColor.b) ) * tintColor.b + sqrt(UV.x*UV.y)*rtUv );


  //P_DEFAULT float target = abs(sin( timer ) * (1.0 + span));
  //P_DEFAULT float target = max( abs(sin( timer ) * (1.0 + span)), 0.0);
  P_DEFAULT float target = max( abs(sin( timer ) * (1.0 + span)), 0.0);
  
  if(texColor.a > 0.0) {
    P_DEFAULT float lum = luminance(texColor);
    P_DEFAULT float diff = abs(lum - target);
    P_DEFAULT float blendRatio = clamp( 1.0 - diff / span, 0.0, 1.0);
    //texColor = vec4(mix(texColor.rgb, tintColor.rgb, blendRatio), texColor.a);
    texColor = mix( texColor, tintColor, blendRatio);
  }

  return CoronaColorScale(texColor);
}
]]

return kernel

