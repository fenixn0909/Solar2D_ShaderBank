
--[[

  https://www.shadertoy.com/view/3dBcR1

  # This shader take 2 noise textures

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "BG"
kernel.name = "cloudWavy" -- Use 2 cloud texture

kernel.isTimeDependent = true

kernel.textureWrap = 'repeat'


kernel.vertexData =
{
  { name = "ResX",     default = 1, min = 0.1, max = 5, index = 0, },
  { name = "ResY",     default = 1, min = 0.1, max = 5, index = 1, },
  { name = "Speed",    default = 1, min = 0, max = 5, index = 2, },
  { name = "Scale",    default = 0.5, min = 0.1, max = 2, index = 3, },
}



kernel.fragment =
[[


float ResX = CoronaVertexUserData.x;
float ResY = CoronaVertexUserData.y;

P_UV vec2 iResolution = vec2( ResX, ResY );

//----------------------------------------------

#define TIME_FACTOR .001  // .1

#define SKY_COLOR vec3(.05, .4, 1.)
#define CLOUD_COLOR vec3(1, 1, 1)
#define CLOUD_DARK_COLOR vec3(.4, .5, .4)

//cloud properties
#define LAYERS 4      //more layers = less fluffy
#define CLOUD_INTENSITY 1.4 //amount of clouds
#define DISTANCE .2   //scale factor of first layer
#define ROUGHNESS .75     //amount contribution per each successive layer

const float div = 1. / (float(LAYERS) * ROUGHNESS);

//----------------------------------------------
float FractalCloud(vec2 position, vec2 delta)
{
    float step = DISTANCE;
    float mul = CLOUD_INTENSITY;
    float p = 0.;
    for (int i = 0; i < LAYERS; i++)
    {
        vec2 coord = position * step + delta * sqrt(step);
        p = p + texture2D(CoronaSampler0, coord).r * mul;
        step *= 1.75;
        mul *= ROUGHNESS;
    }
  return p * div;
}


#define MASK_LAYERS 3
float CloudMask(vec2 position, vec2 delta)
{
    float step = .15;
    float p = .25;
    float mul = 1.;
    for (int i = 0; i < MASK_LAYERS; i++)
    {
        vec2 coord = (position) * step + delta;// + sqrt(delta);
        float k = texture2D(CoronaSampler1, coord).r;
        //k = cos(k * TAU);
        p += k * mul;
        mul = mul * -.5;
        step = step * 2.;
    }
  return p;
}

//----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);
//P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  
  P_UV vec2 fragCoord = UV / iResolution;

  P_DEFAULT float iTime = CoronaTotalTime * 100;
  //P_DEFAULT float iTime = sin(CoronaTotalTime*0.1)*1000;
  //P_DEFAULT float alpha = abs(sin(CoronaTotalTime)) -0.15;
  //----------------------------------------------
  
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    float time = iTime * TIME_FACTOR;

    // Scale UV
    float _scale = 0.5;
    uv = (uv - 0.5) * _scale + 0.5;

    //fractal clouds
    float cloudIntensity = sin(time * .5 + uv.x * 1.5);
    cloudIntensity = 1.25 + cloudIntensity * .75;
    
    float p = FractalCloud(uv, vec2(time * .3, time * -.15));
    p *= (.5 + CloudMask(uv, vec2(time * .15, time * .05)) * cloudIntensity);
    p = smoothstep(0., 2., p) * 2.;
    
    float dark = max(p - 1., 0.);
    dark =log(1. + dark);
    float light = min(p, 1.);
    /*
    fragColor = vec4(mix(
        mix(SKY_COLOR, CLOUD_COLOR, smoothstep(0.,1.,light)), 
        CLOUD_DARK_COLOR, smoothstep(0.,1.,dark)),
        1.);
    */

  //----------------------------------------------
  
  COLOR = vec4(mix(
        mix(SKY_COLOR, CLOUD_COLOR, smoothstep(0.,1.,light)), 
        CLOUD_DARK_COLOR, smoothstep(0.,1.,dark)),
        1.);
  //COLOR.a = alpha;
  

  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


