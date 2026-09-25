
--[[
    https://godotshaders.com/shader/2d-wind-sway-tree-grass-motion-shader-2/
    Purga
    November 26, 2025

    Dropped: REGION_RECT (atlas sub-region remapping - assumes the
    object's own texture is the full content, same simplification as
    this bank's other Purga ports) and the original's
    `vertex() { VERTEX *= scale; }` geometry growth (same "size your
    object larger yourself if you need the extra margin" note as
    elsewhere in this bank). Everything else - the falloff curve,
    the sine sway, and the edge-fade border - ported as-is.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "wobble"
kernel.name = "windSway2D"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Wind_Start_Threshold", default = .1, min = 0, max = 1,  index = 0, },
  { name = "Wind_End_Threshold",   default = 2,  min = 0, max = 10, index = 1, },
  { name = "Wind_Strength",        default = .2, min = 0, max = 1.5, index = 2, },
  { name = "Wind_Speed",           default = 1,  min = .2, max = 5, index = 3, },
}

kernel.fragment =
[[

float Wind_Start_Threshold = CoronaVertexUserData.x;
float Wind_End_Threshold   = CoronaVertexUserData.y;
float Wind_Strength        = CoronaVertexUserData.z;
float Wind_Speed           = CoronaVertexUserData.w;

float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;

    float dist_amount = smoothstep(
        Wind_Start_Threshold * pow( 1.0 - uv.y, Wind_End_Threshold ),
        0.1,
        1.0 - uv.y
    );
    uv.x += sin( TIME * Wind_Speed ) * pow( 1.0 - uv.y, Wind_End_Threshold ) * dist_amount * Wind_Strength;

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, uv );

    vec2 border = step( vec2( 0.0 ), uv ) * step( uv, vec2( 1.0 ) );
    COLOR.a *= border.x * border.y;

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

