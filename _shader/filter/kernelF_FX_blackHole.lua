--[[
    https://godotshaders.com/shader/2d-black-hole/
    Dan, February 21, 2026

    Gravitational lensing that sucks the sprite toward the center.
    Rebuilt: the old core sampled out-of-range UVs and forced alpha 1,
    painting an opaque BLACK disc; the debug toggle was useless.
    Now out-of-range pixels fade to transparent (no black anywhere -
    the hole is a see-through lens), and the slots hold fun stuff:
    Process (1st), Strength (pull), Spin (accretion swirl), Glow
    (photon-ring rim light).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "blackHole"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Process",  default = 1,   min = 0, max = 1, index = 0, },
  { name = "Strength", default = 0.9, min = 0, max = 3, index = 1, },
  { name = "Spin",     default = 0.8, min = 0, max = 4, index = 2, },
  { name = "Glow",     default = 0.6, min = 0, max = 2, index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Process  = CoronaVertexUserData.x;
    float Strength = CoronaVertexUserData.y;
    float Spin     = CoronaVertexUserData.z;
    float Glow     = CoronaVertexUserData.w;

    vec4 orig = texture2D( CoronaSampler0, UV );

    float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
    vec2 dir = ( UV - vec2( 0.5 ) ) * vec2( aspect, 1.0 );
    float dist = max( length( dir ), 0.0001 );

    // radial pull (lensing) + tangential accretion spin
    vec2 n = dir / dist;
    vec2 tangent = vec2( -n.y, n.x );
    float pull = pow( dist, -Strength ) * pow( max( 1.0 - dist, 0.0 ), 8.0 );
    float swirl = Spin * exp( -dist * 4.0 ) + CoronaTotalTime * 0.15 * Spin;
    vec2 warpDir = ( n * pull + tangent * swirl * 0.35 ) / vec2( aspect, 1.0 );
    vec2 warpUV = UV - warpDir;

    vec4 warped;
    if ( warpUV.x < 0.0 || warpUV.x > 1.0 || warpUV.y < 0.0 || warpUV.y > 1.0 )
    {
        warped = vec4( 0.0 ); // transparent, never black
    }
    else
    {
        warped = texture2D( CoronaSampler0, warpUV );
    }

    // photon-ring rim light just outside the throat
    float ring = exp( -pow( ( dist - 0.10 ) * 22.0, 2.0 ) ) * Glow;
    warped.rgb += vec3( 1.0, 0.85, 0.6 ) * ring * warped.a;

    vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
