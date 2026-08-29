
--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/tdBSRc

  fork of https://www.shadertoy.com/view/4sBBDK
  

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "PP" --Postprocess
kernel.name = "barrelChroma"


kernel.isTimeDependent = true

kernel.vertexData =
{

}


kernel.fragment =
[[
P_UV vec2 iResolution = vec2(1.,1.);
//----------------------------------------------
  float angle = 20.;    //const 
  float scale = 1000;     //const 
  float amount = 2.5;    //const   dot: 1~5, line 1~2.5
  float saturation = 1.2;     //const 
  const bool greyscale = false;

  #define LINE
  //#define DOT
  //#define SAMPLER

  float greyScale(in vec3 col) {
      return dot(col, vec3(0.2126, 0.7152, 0.0722));
  }

  mat2 rotate2d(float angle){
      return mat2(cos(angle), -sin(angle), sin(angle),cos(angle));
  }


// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 fragCoord = ( texCoord.xy / iResolution );
  P_COLOR vec4 COLOR;
  P_DEFAULT float iTime = CoronaTotalTime;

  //scale = sin(CoronaTotalTime*3) * 1000;
  //amount = abs(sin(CoronaTotalTime*1)) * 3 + 1.5; // For Dot
  //amount = abs(sin(CoronaTotalTime*1)) *2  + 1; // For Line
  //saturation = abs(sin(CoronaTotalTime)) * 1 + .7;
  
  //----------------------------------------------
  
    
    P_UV vec2 uv = ( texCoord.xy / iResolution );
        
    P_COLOR vec3 col = texture2D(CoronaSampler0, uv).rgb; 
    if (greyscale) col = vec3(greyScale(col));
    
    uv *= iResolution.xy;
    P_UV vec2 p = rotate2d(angle) * uv * scale; 
    
    P_UV float pattern;
    #ifdef LINE
    pattern = sin( p.x ) * amount;
    col = col * 10. * saturation - 5. + pattern;
    #endif

    #ifdef DOT
    pattern = sin( p.x ) * sin( p.y ) * amount;
    col = col * 10. * saturation - 5. + pattern;
    #endif
    
    #ifdef SAMPLER
    pattern = texture2D(CoronaSampler1, fragCoord  * 0.125 * textureRatio).r * 5 /5.;
    col = step(pattern, col*saturation/1.2); 
    #endif
  
    
    COLOR = vec4( col, 1.0 );
    
    
    return CoronaColorScale( COLOR );

  //----------------------------------------------
  //COLOR.a *= alpha;
  //COLOR.rgb *= COLOR.a;
  //COLOR.rgb = col2;

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


