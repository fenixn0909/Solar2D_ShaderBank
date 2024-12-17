
--[[
  
  Origin Author:  flyingrub
  https://www.shadertoy.com/view/Wtl3zs

  escher texture

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG" 
kernel.name = "linesEsher"


kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Speed",      default = 2.5, min = -10, max = 10, index = 0, },
  { name = "Width",          default = 0.2, min = -0.3, max = 5, index = 1, },
  { name = "Grids",         default = 20, min = 0, max = 100, index = 2, },
  { name = "Smooth_Edge",   default = 0.2, min = 0, max = .65, index = 3, },
} 

kernel.fragment =
[[

uniform sampler2D OVERLAY;

float Speed = CoronaVertexUserData.x;
float Width = CoronaVertexUserData.y;
lowp float Grids = CoronaVertexUserData.z;   
float Smooth_Edge = CoronaVertexUserData.w;  // 0.2
//----------------------------------------------

vec4 Col_Stripe = vec4( 1.0, .5, .5, .8);


//----------------------------------------------
#define TAU 6.28318530718

//----------------------------------------------
float easeInOut(float t) {
  if ((t *= 2.0) < 1.0) {
      return 0.5 * t * t;
  } else {
      return -0.5 * ((t - 1.0) * (t - 3.0) - 1.0);
  }
}

float linearstep(float begin, float end, float t) {
  return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float stroke(float d, float size, float width) {
return smoothstep(Width,0.0,abs(d-size)-width/2.);
}

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


// -----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);
float TIME = CoronaTotalTime * Speed;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    //----------------------------------------------
    vec2 uv = UV;
    uv.x *= Grids; 
    // Apply wavy on Y
    uv.y *= Grids; 
    
    vec2 id = floor(uv);
    vec2 gv = fract(uv)*2.-1.;

    float offset = simplex3d(vec3(uv*2., TIME))*.2;
    gv.x += offset;
    float width = .1+ simplex3d(vec3(uv*1.5, TIME))* .15;
    float col = smoothstep(Width+width,width,abs(gv.x));

    // Add color layer
    //col += step(0., gv.x); 

    COLOR = Col_Stripe * col;

    // Pure White & Black
    //COLOR = vec4(vec3(col),1.0);  
    
    //----------------------------------------------
    COLOR.rgb *= COLOR.a;


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


