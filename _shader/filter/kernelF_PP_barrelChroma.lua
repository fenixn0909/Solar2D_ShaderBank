--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/tdBSRc

  fork of https://www.shadertoy.com/view/4sBBDK

  Params wired to real sliders (were hardcoded constants before, and
  kernel.vertexData was an empty table) and alpha preserved instead of
  hardcoded to 1.0 (was making transparent-backed areas render as
  opaque black) - same fix already applied to this file's DOT-pattern
  twin, kernelF_PP_dotLineDither.

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "PP" --Postprocess
kernel.name = "barrelChroma"


kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Angle",      default = 20,  min = 0,   max = 90,  index = 0, },
  { name = "Scale",      default = 1000, min = 100, max = 3000, index = 1, },
  { name = "Amount",     default = 2.5, min = 0.5, max = 5,   index = 2, },
  { name = "Saturation", default = 1.2, min = 0,   max = 3,   index = 3, },
}


kernel.fragment =
[[
P_UV vec2 iResolution = vec2(1.,1.);
//----------------------------------------------
  float angle = radians( CoronaVertexUserData.x );
  float scale = CoronaVertexUserData.y;
  float amount = CoronaVertexUserData.z;
  float saturation = CoronaVertexUserData.w;
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
        
    P_COLOR vec4 srcSample = texture2D(CoronaSampler0, uv);
    P_COLOR vec3 col = srcSample.rgb; 
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
  
    
    COLOR = vec4( col, srcSample.a );
    COLOR.rgb *= COLOR.a;
    
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


