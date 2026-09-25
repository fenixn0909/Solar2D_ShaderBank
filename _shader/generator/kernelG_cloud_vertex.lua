
--[[

    https://www.shadertoy.com/view/msfXD8
    

    
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "cloud"
kernel.name = "vertex"


kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Speed",                         default = .25, min = -5, max = 5, index = 0, },
  { name = "Spread",                        default = 1, min = 0, max = 2, index = 1, },
  { name = "Density",                       default = 1, min = 0, max = 2.5, index = 2, },
  { name = "Brightness",                    default = 1, min = 0, max = 3, index = 3, },
} 

kernel.fragment =
[[

float Speed = CoronaVertexUserData.x;
float Spread = CoronaVertexUserData.y;
float Density = CoronaVertexUserData.z;
float Brightness = CoronaVertexUserData.w;
//----------------------------------------------

//P_COLOR vec4 Col_Sky = vec4(0.5, 0.7, 0.85, 0);
P_COLOR vec4 Col_Sky = vec4(0.0, 0.0, 0.0, 0);

//----------------------------------------------

mat2 r2d(float a) 
{
  float c = cos(a), s = sin(a);
    return mat2(
        c, s, 
        -s, c 
    );
}

float noise(vec2 uv)
{
    return fract(sin(uv.x * 113. + uv.y * 412.) * 6339.);
}

vec3 noiseSmooth(vec2 uv)
{
    vec2 index = floor(uv);
    
    vec2 pq = fract(uv);
    pq = smoothstep(0., 1., pq);
     
    float topLeft = noise(index);
    float topRight = noise(index + vec2(1, 0.));
    float top = mix(topLeft, topRight, pq.x);
    
    float bottomLeft = noise(index + vec2(0, 1));
    float bottomRight = noise(index + vec2(1, 1));
    float bottom = mix(bottomLeft, bottomRight, pq.x);
    
    return vec3(mix(top, bottom, pq.y));
}

vec3 genCloud(vec2 uv, vec2 orig, float bias)
{
    vec3 col = noiseSmooth(uv * 4.);
    
    col += noiseSmooth(uv * 8.) * 0.5;
    col += noiseSmooth(uv * 16.) * 0.25;
    col += noiseSmooth(uv * 32.) * 0.125;
    col += noiseSmooth(uv * 64.) * 0.0625;
    
    col *= distance(orig, vec2(0.))*bias;  
  
    col *= smoothstep(0.2, .8, col);   
   
    return col;
}


// -----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float iTime = CoronaTotalTime * Speed;


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    //----------------------------------------------
  
    vec2 uv = UV - 0.5;
    
    //vec4 sky = vec4(vec3(0.5, 0.7, 0.85) * ((1. - uv.y) + 1.5) / 2., 1.) / 2.1;
    vec4 sky = Col_Sky;

    vec2 orig = uv*Spread; 
    vec2 uv2 = uv;
    vec2 uv3 = uv;
        
    uv *= r2d(iTime - distance(uv, vec2(0.)));
    uv2 *= r2d(iTime*.5 - distance(uv, vec2(0.))*1.2);
    uv3 *= r2d(iTime*.333 - distance(uv, vec2(0.)));
    
    uv2 += 0.4;
    uv3 += 0.3;
    
    float l1 = fract((iTime) / 5.) + 1.;
    float l2 = fract((iTime + 0.6) / 2.) + 1.5;
        
    vec4 col = vec4(genCloud(uv, orig, 1.65 * Density), 0.);    
    col = mix(col, vec4(genCloud(uv2, orig, 3.8 * Density), 0.), 0.5);
    col = mix(col, vec4(genCloud(uv3, orig, 0.5 * Density), 0.), 0.3);

    col = mix(1. - (col * .2), sky, 1. - col);
    col.rgb *= Brightness;
        
    //----------------------------------------------
    COLOR = col;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


