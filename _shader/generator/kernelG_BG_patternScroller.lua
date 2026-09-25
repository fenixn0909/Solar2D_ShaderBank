--[[
    Infinite procedural pattern scroller (stripes / brick / dots).
    Fixed: sampled an unbound `texture_to_scroll` sampler (compile fail)
    and only exposed boring resolutionX/Y. Now the pattern is fully
    procedural and Speed / Angle / Repeat / Style are real-time.
    Creator: phoenixongogo       License: MIT
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "patternScroller"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Speed",  default = 0.25, min = 0, max = 2,   index = 0, },
  { name = "Angle",  default = 45,   min = 0, max = 360, index = 1, },
  { name = "Repeat", default = 6,    min = 1, max = 20,  index = 2, },
  { name = "Style",  default = 0,    min = 0, max = 2,   index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Speed  = CoronaVertexUserData.x;
    float Angle  = CoronaVertexUserData.y;
    float Repeat = max( CoronaVertexUserData.z, 1.0 );
    int   Style  = int( CoronaVertexUserData.w + 0.5 );

    vec2 dir = vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) );
    vec2 p = UV * Repeat - dir * CoronaTotalTime * Speed * Repeat * 0.25;

    vec3 dark  = vec3( 0.10, 0.12, 0.20 );
    vec3 light = vec3( 0.95, 0.85, 0.60 );
    vec3 col;

    if ( Style == 0 )
    {
        // diagonal stripes
        float s = step( 0.5, fract( ( p.x + p.y ) * 0.5 ) );
        col = mix( dark, light, s );
    }
    else if ( Style == 1 )
    {
        // brick rows with offset
        float row = floor( p.y );
        float bx = fract( p.x + step( 0.5, fract( row * 0.5 ) ) * 0.5 );
        float by = fract( p.y );
        float mortar = step( bx, 0.08 ) + step( by, 0.12 );
        col = mix( light, dark * 0.6, clamp( mortar, 0.0, 1.0 ) );
    }
    else
    {
        // polka dots
        vec2 g = fract( p ) - vec2( 0.5 );
        float d = length( g );
        col = mix( light, dark, smoothstep( 0.32, 0.38, d ) );
    }

    P_COLOR vec4 COLOR = vec4( col, 1.0 );
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
