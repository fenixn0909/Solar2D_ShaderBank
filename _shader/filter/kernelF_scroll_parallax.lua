--[[
    PLACEHOLDER - not yet implemented.
    The vertex kernel below is currently an unmodified copy of
    filter.wobble.wind2 (cloned as a starting point, never finished).
    It was also declaring the same category.group.name as wind2, which
    collided in Solar2D's effect registry - fixed by renaming below.

    Reference for the parallax effect this was meant to become (ShaderToy,
    still needs porting to Solar2D fragment-kernel conventions):
    https://www.shadertoy.com/view/MlB3D3
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "scroll"
kernel.name = "parallax"

kernel.isTimeDependent = true


kernel.uniformData = 
{
    name = "worldMatrix",
    default = {
      10.0, 10.0, 0.0, 0.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 0.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 0.0
    },
    min = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    max = {
      10.0, 10.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
    type="mat4",
    index = 0, -- u_UserData0
}





kernel.vertex =
[[
#define SPEED 0.1

uniform P_COLOR mat4 u_UserData0; 
uniform P_COLOR mat4 u_UserData1; 

P_DEFAULT float speed = 0.1;
P_DEFAULT float minStrength = 0.02; //: hint_range(0.0, 1.0) 
P_DEFAULT float maxStrength = 0.05; //: hint_range(0.0, 1.0) 
P_DEFAULT float strengthScale = 185.0;
P_DEFAULT float interval = 0.1;
P_DEFAULT float detail = 100.0;
P_DEFAULT float distortion = 1.0; //: hint_range(0.0, 1.0)
P_DEFAULT float heightOffset = 0.0; //: hint_range(0.0, 1.0)
P_DEFAULT float offset = 0.0;


P_POSITION float getWind (P_POSITION vec2 vertex, P_UV vec2 uv, P_DEFAULT float time)
{
    P_DEFAULT float diff = pow(maxStrength - minStrength, 2.0);
    P_DEFAULT float strength = clamp(minStrength + diff + sin(time / interval) * diff, minStrength, maxStrength) * strengthScale;
    
    //P_DEFAULT float windSide = max(0.0, (1.0-uv.y) - heightOffset); // Blow Top
    P_DEFAULT float windSide = min(1.0, (0.0+uv.y) + heightOffset); // Blow Top
    P_RANDOM float wind = (sin(time) + cos(time * detail)) * strength * windSide;
    //P_DEFAULT float wind = (sin(time) + cos(time * detail)) * strength * windSide;
    

    return wind; 
}


P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{


    //With the offset value, you can if you want different moves for each asset. Just put a random value (1, 2, 3) in the editor. Don't forget to mark the material as unique if you use this
    
    speed = mod(5, 4) * 0.1;

    //P_DEFAULT float time = CoronaTotalTime * speed + offset;
    //P_UV vec4 pos = u_UserData0[0] * vec4(1.0, 1.0, 1.0, 1.0);
    P_DEFAULT float posX = u_UserData0[0][0];
    P_DEFAULT float posY = u_UserData0[0][1];
    P_DEFAULT float time = CoronaTotalTime * speed + posX * posY;// not working when moving...
    position.x += getWind(position.xy, CoronaTexCoord, time);


    return position;
}
]]


--[[
const float pixels =    4.00; // "fat pixel" size
const float radius =  128.00; // planar movement radius
const float xspeed =    0.25; // x speed
const float yspeed =    0.10; // y speed
const float zspeed =    0.10; // z speed
const int   layers =    3;    // parallax layers

////////////////////////////////////////////////////////////////////////////////////////////////////

vec4 sampleTexture(vec2 pixel, vec2 offset, float zoom)
{
    vec2  center = iResolution.xy / 2.0;
  float scale  = pixels * zoom;

    pixel = ((pixel + offset * zoom) - center) / scale + center;

    vec2 uv = floor(pixel) + 1.5 - clamp((1.0 - fract(pixel)) * scale, 0.0, 1.0);

    return texture(iChannel0, uv / iChannelResolution[0].xy);
}

vec4 mixColors(vec4 color1, vec4 color2)
{
    return mix(vec4(color1.rgb * color1.a, 1), vec4(color2.rgb * color2.a, 1), color2.a);
}

void mainImage(out vec4 color, in vec2 pixel)
{
  vec2  offset = vec2(cos(iTime * xspeed), sin(iTime * yspeed)) * radius;
    float zoom   = sin(iTime * zspeed) * 0.5 + 1.5;

    color = vec4(1);
    
    for (int i = 0; i < layers; i++)
    {
        color = mixColors(color, sampleTexture(pixel, offset, zoom));
        zoom *= 1.25;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

// original non-parallax subpixel aa shader:
// https://www.shadertoy.com/view/MlB3D3

////////////////////////////////////////////////////////////////////////////////////////////////////
--]]




return kernel