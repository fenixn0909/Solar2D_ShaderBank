
--[[
    https://godotshaders.com/shader/diagonal-mask-border-edge/
    davidjvitale
    January 30, 2023
--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "maskDiagonal"

kernel.vertexData =
{
  { name = "Effect",         default = 0, min = -1, max = 1, index = 0, },
  { name = "Angle",     default = -1, min = -5, max = 0, index = 1, },
} 

kernel.fragment =
[[

float Effect = CoronaVertexUserData.x;
float Angle = CoronaVertexUserData.y;
//-----------------------------------------------

uniform sampler2D TEXTURE;

//-----------------------------------------------

float when_gt(float x, float y) { //greater than return 1
  return max(sign(x - y), 0.0);
}
//-----------------------------------------------

float TIME = CoronaTotalTime;

P_COLOR vec4 COLOR = vec4(0);

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    //-----------------------------------------------

    
    COLOR = texture2D( TEXTURE, UV );   // Pull in the texture
    vec4 color = texture2D( TEXTURE, UV );  // Need a copy for original alpha values
    COLOR.a = color.a * 0.0;    // Set everything to transparent
    
    float x0 = min(UV.x, 1.0 - UV.x);   // Map current point to first quadrant
    float y0 = min(UV.y, 1.0 - UV.y);
    
    // Compute diagonal line through UV.x,UV.y depending on the Effect
    float m = Angle;
    float m0 = -1.0 / m;
    float b0 = Effect + (y0 - m0 * x0);
    
    // Find x,y = intersection of edge through UV.x,UV.y
    float x = ( 0.5 - b0 ) / ( m0 - m );
    float y = m0 * x + b0;
    
    // Are we inside the diagonal box?
    COLOR.a = color.a * when_gt(x0,x) * when_gt(y0,y);

    //-----------------------------------------------
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]


return kernel




--[[



--]]





