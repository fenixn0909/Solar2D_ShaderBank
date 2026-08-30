
--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/3dBSRD

  SHAKE ME Screenshake me! https://www.shadertoy.com/view/wsBXWW

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "PP" 
kernel.name = "scanline"


kernel.isTimeDependent = true

kernel.vertexData =
{
  {
    name = "texWidth",
    default = 4,
    min = 1,
    max = 9999,
    index = 0,    
  },
  {
    name = "texHeight",
    default = 4,
    min = 1,
    max = 9999,     
    index = 1,    
  },
}


kernel.fragment =
[[
P_UV vec2 iResolution = vec2(1. ,1.);
P_UV vec2 texSize = vec2( CoronaVertexUserData.x, CoronaVertexUserData.y );


//----------------------------------------------
  
  #define isTween

  float density = 2.3; // 1.3  incr for thiner and more
  float opacityScanline = .05;  // .3  decr for intensity
  float opacityNoise = .1; // .2 incr for brighter
  float flickering = 0.02;  // .03 blink freq and shine

  float count = texSize.y * density;

  float twnCnt = 150;

  float random (vec2 st) {
      return fract(sin(dot(st.xy,
                           vec2(12.9898,78.233)))*
          43758.5453123);
  }

  float blend(const in float x, const in float y) {
    return (x < 0.5) ? (2.0 * x * y) : (1.0 - 2.0 * (1.0 - x) * (1.0 - y));
  }

  vec3 blend(const in vec3 x, const in vec3 y, const in float opacity) {
    vec3 z = vec3(blend(x.r, y.r), blend(x.g, y.g), blend(x.b, y.b));
    return z * opacity + x * (1.0 - opacity);
  }


// -----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 fragCoord = ( texCoord.xy / iResolution );
  P_COLOR vec4 COLOR;
  P_DEFAULT float iTime = CoronaTotalTime;


  #ifdef isTween
    count += sin(CoronaTotalTime*.25)*twnCnt; //50
    opacityScanline += abs(sin(CoronaTotalTime)) * .5  ; //50
  #endif
  //----------------------------------------------
    vec4 src = texture2D( CoronaSampler0,uv);
    vec3 col = src.rgb;

    
    vec2 sl = vec2(sin(uv.y * count), cos(uv.y * count));
    vec3 scanlines = vec3(sl.x, sl.y, sl.x);

    col += col * scanlines * opacityScanline;
    col += col * vec3(random(uv*iTime)) * opacityNoise;
    col += col * sin(110.0*iTime) * flickering;

    COLOR = vec4(col, src.a);
    COLOR.rgb *= COLOR.a;
  //----------------------------------------------
  //COLOR.a = (COLOR.a+COLOR.g+COLOR.b)/3;
  //COLOR.a *= alpha;
  //COLOR.rgb *= COLOR.a;
  
  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


