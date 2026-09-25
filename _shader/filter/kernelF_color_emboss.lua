--[[
    Emboss (relief) filter.
    Fixed: used non-Solar2D API (u_FillSampler0/u_TexelSize/v_UserData/
    v_ColorScale) so it never rendered. Now uses CoronaSampler0,
    CoronaTexelSize, CoronaVertexUserData, CoronaColorScale.
    Fun tweakings: Strength (relief depth), Angle (light direction),
    Mono (0 = color emboss, 1 = gray relief), Process (original -> relief).
    Creator: phoenixongogo       License: MIT
]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "emboss"

kernel.isTimeDependent = false

kernel.vertexData =
{
    { name = "Process",  default = 1,   min = 0,   max = 1,   index = 0, },
    { name = "Strength", default = 1,   min = 0,   max = 4,   index = 1, },
    { name = "Angle",    default = 135, min = -180, max = 180, index = 2, },
    { name = "Mono",     default = 1,   min = 0,   max = 1,   index = 3, },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Process  = CoronaVertexUserData.x;
    float Strength = CoronaVertexUserData.y;
    float Angle    = CoronaVertexUserData.z;
    float Mono     = CoronaVertexUserData.w;

    vec2 dir = vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) )
             * CoronaTexelSize.zw;

    P_COLOR vec4 s0   = texture2D( CoronaSampler0, texCoord - dir );
    P_COLOR vec4 s1   = texture2D( CoronaSampler0, texCoord + dir );
    P_COLOR vec4 orig = texture2D( CoronaSampler0, texCoord );

    vec3 emb = ( s1.rgb - s0.rgb ) * Strength * 2.0 + vec3( 0.5 );
    float gray = dot( emb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 embCol = mix( emb, vec3( gray ), clamp( Mono, 0.0, 1.0 ) );

    float a = ( s0.a + s1.a ) * 0.5;
    vec3 col = mix( orig.rgb, embCol * a, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( col, orig.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
