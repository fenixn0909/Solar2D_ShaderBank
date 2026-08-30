
--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/wdBXD1

  simplex noise from : https://www.shadertoy.com/view/XsX3zB

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX" 
kernel.name = "dissolveNoise3D"


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
  #define pixel_width 3./texSize.y

  // Is there a way to really antialias the simplex noise ?
  const float zoom = 2.;
  const float speed = 0.1;
  const float amount = .50;
  const float spaced = 1.2;

  /* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
  vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
  }

  /* skew constants for 3d simplex functions */
  const float F3 =  0.3333333;
  const float G3 =  0.1666667;

  /* 3d simplex noise */
  float simplex3d(vec3 p) {
     /* 1. find current tetrahedron T and it's four vertices */
     /* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
     /* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
     
     /* calculate s and x */
     vec3 s = floor(p + dot(p, vec3(F3)));
     vec3 x = p - s + dot(s, vec3(G3));
     
     /* calculate i1 and i2 */
     vec3 e = step(vec3(0.0), x - x.yzx);
     vec3 i1 = e*(1.0 - e.zxy);
     vec3 i2 = 1.0 - e.zxy*(1.0 - e);
      
     /* x1, x2, x3 */
     vec3 x1 = x - i1 + G3;
     vec3 x2 = x - i2 + 2.0*G3;
     vec3 x3 = x - 1.0 + 3.0*G3;
     
     /* 2. find four surflets and store them in d */
     vec4 w, d;
     
     /* calculate surflet weights */
     w.x = dot(x, x);
     w.y = dot(x1, x1);
     w.z = dot(x2, x2);
     w.w = dot(x3, x3);
     
     /* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
     w = max(0.6 - w, 0.0);
     
     /* calculate surflet components */
     d.x = dot(random3(s), x);
     d.y = dot(random3(s + i1), x1);
     d.z = dot(random3(s + i2), x2);
     d.w = dot(random3(s + 1.0), x3);
     
     /* multiply d by w^4 */
     w *= w;
     w *= w;
     d *= w;
     
     /* 3. return the sum of the four surflets */
     return dot(d, vec4(52.0));
  }

  /* const matrices for 3d rotation */
  const mat3 rot1 = mat3(-0.37, 0.36, 0.85,-0.14,-0.93, 0.34,0.92, 0.01,0.4);
  const mat3 rot2 = mat3(-0.55,-0.39, 0.74, 0.33,-0.91,-0.24,0.77, 0.12,0.63);
  const mat3 rot3 = mat3(-0.71, 0.52,-0.47,-0.08,-0.72,-0.68,-0.7,-0.45,0.56);

  float fractal_noise(vec3 m) {
      return   0.5333333*simplex3d(m*rot1)
        +0.2666667*simplex3d(2.0*m*rot2)
        +0.1333333*simplex3d(4.0*m*rot3)
        +0.0666667*simplex3d(8.0*m);
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
  
    vec2 p = fragCoord.xy/iResolution.x;
    vec3 p3 = vec3(p*zoom, iTime*speed)*8.0+8.0;
      
    vec2 uv = fragCoord/iResolution.xy;
    float red = fractal_noise(p3)*.5+.5;
    red = smoothstep(pixel_width,0.,red-amount);
      
    p3 = p3+spaced;
    float blue = fractal_noise(p3)*.5+.5;
    blue = smoothstep(pixel_width,0.,blue-amount);
   
    p3 = p3+spaced;
    float green = fractal_noise(p3)*.5+.5;
    green = smoothstep(pixel_width,0.,green-amount);

    vec4 srcSample = texture2D(CoronaSampler0,uv);
    vec3 color = srcSample.rgb;
    vec3 col = vec3(red,green,blue)*color;
    
    COLOR = vec4(vec3(col), srcSample.a);
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


