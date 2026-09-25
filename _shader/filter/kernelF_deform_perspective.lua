--[[
  Fake 3D perspective tilt for sprites.
  Improved: was a single Ratio param, sampled out-of-range UVs with
  clamp (streaky edges), and had a duplicated isTimeDependent line.
  Now Shift slides the vanishing point, Zoom reframes, out-of-range
  pixels go transparent instead of streaking, and Process blends
  original -> tilted.
--]]

local kernel = {}

kernel.language = "glsl"

kernel.category = "filter"
kernel.group = "deform"
kernel.name = "perspective"

kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process", default = 1,   min = 0,  max = 1,   index = 0, },
  { name = "Ratio",   default = 0.5, min = -8, max = 8,   index = 1, },
  { name = "Shift",   default = 0,   min = -1, max = 1,   index = 2, },
  { name = "Zoom",    default = 1,   min = 0.5, max = 2,  index = 3, },
}

kernel.fragment =
[[

P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Process = CoronaVertexUserData.x;
    float Ratio   = CoronaVertexUserData.y;
    float Shift   = CoronaVertexUserData.z;
    float Zoom    = CoronaVertexUserData.w;

    vec4 orig = texture2D( CoronaSampler0, UV );

    vec2 fragCoord = UV * iResolution;
    vec2 res = iResolution.xy;
    vec2 pos = fragCoord - res * 0.5;

    vec2 uv = pos / ( res - pos * Ratio ).y + 0.5;
    uv = ( uv - vec2( 0.5 ) ) / max( Zoom, 0.1 ) + vec2( 0.5, 0.5 + Shift );

    vec4 warped;
    if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 )
    {
        warped = vec4( 0.0 );
    }
    else
    {
        warped = texture2D( CoronaSampler0, uv );
    }

    vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel
