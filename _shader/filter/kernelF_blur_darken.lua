--[[
    https://godotshaders.com/shader/darkened-blur/
    LambBrainz Aug 25, 2024
    Fixed (round 2): the previous fix assigned to `uniform` globals
    inside the fragment (illegal GLSL - uniforms are read-only) and used
    dynamic loop bounds, so it failed to compile = black sprite. Now
    uses locals only and a constant-bound box blur. The dead Lod param
    became Process (original -> dark blur).
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "darken"
kernel.isTimeDependent = false

kernel.vertexData = {
  { name = "Process",  default = 1,   min = 0, max = 1, index = 0, },
  { name = "Strength", default = 2,   min = 1, max = 6, index = 1, },
  { name = "Mix",      default = 0.3, min = 0, max = 1, index = 2, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Process  = CoronaVertexUserData.x;
    int   Strength = int( CoronaVertexUserData.y + 0.5 );
    float Mix      = CoronaVertexUserData.z;

    float sf = clamp( float( Strength ), 1.0, 6.0 );
    vec2 px = CoronaTexelSize.zw;

    // constant-bound box blur, taps gated by Strength
    vec4 acc = vec4( 0.0 );
    float cnt = 0.0;
    for ( int ox = -6; ox <= 6; ox++ )
    {
        for ( int oy = -6; oy <= 6; oy++ )
        {
            if ( abs( float( ox ) ) <= sf && abs( float( oy ) ) <= sf )
            {
                acc += texture2D( CoronaSampler0, UV + vec2( float( ox ), float( oy ) ) * px );
                cnt += 1.0;
            }
        }
    }
    vec4 blurred = acc / max( cnt, 1.0 );

    vec4 orig = texture2D( CoronaSampler0, UV );
    vec4 dark = mix( blurred, vec4( 0.0, 0.0, 0.0, blurred.a ), clamp( Mix, 0.0, 1.0 ) );
    vec4 outc = mix( orig, dark, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
