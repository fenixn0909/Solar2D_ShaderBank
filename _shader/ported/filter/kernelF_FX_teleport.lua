
--[[
    https://godotshaders.com/shader/teleport-effect/
    pend00
    February 17, 2021

    Direct port - no textures beyond the object's own (the original is
    fully procedural already). Same gradient-noise field multiplied by
    UV.y so the dissolve sweeps bottom-to-top as Progress rises, same
    hard step dissolve with a bright beam band of Beam_Size right at
    the leading edge. The original's Environment-glow setup (Godot
    WorldEnvironment bloom over HDR beam colors) has no Solar2D
    equivalent, so Glow_Boost scales the beam color directly instead -
    push it past 1 for the hot-cyan look from the post's gif.

    CC0.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "teleport"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Noise_Density','Beam_Size','Glow_Boost',
            'Beam_R','Beam_G','Beam_B','',
            '','','','',
            '','','','',
        },
        default = {
            .4,60,.07,1,
            0,1,1.15,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,5,.01,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,120,.2,3,
            2,2,2,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress      = u_UserData0[0][0];
float Noise_Density = u_UserData0[0][1];
float Beam_Size     = u_UserData0[0][2];
float Glow_Boost    = u_UserData0[0][3];
vec3  Beam_Color    = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );

//----------------------------------------------

P_RANDOM vec2 teleport_random( vec2 uv )
{
    uv = vec2( dot( uv, vec2( 127.1, 311.7 ) ),
               dot( uv, vec2( 269.5, 183.3 ) ) );
    return -1.0 + 2.0 * fract( sin( uv ) * 43758.5453123 );
}

P_RANDOM float teleport_noise( vec2 uv )
{
    vec2 uv_index = floor( uv );
    vec2 uv_fract = fract( uv );

    vec2 blur = smoothstep( 0.0, 1.0, uv_fract );

    return mix( mix( dot( teleport_random( uv_index + vec2( 0.0, 0.0 ) ), uv_fract - vec2( 0.0, 0.0 ) ),
                     dot( teleport_random( uv_index + vec2( 1.0, 0.0 ) ), uv_fract - vec2( 1.0, 0.0 ) ), blur.x ),
                mix( dot( teleport_random( uv_index + vec2( 0.0, 1.0 ) ), uv_fract - vec2( 0.0, 1.0 ) ),
                     dot( teleport_random( uv_index + vec2( 1.0, 1.0 ) ), uv_fract - vec2( 1.0, 1.0 ) ), blur.x ), blur.y ) * 0.5 + 0.5;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float field = teleport_noise( UV * Noise_Density ) * UV.y;

    float d1 = step( Progress, field );
    float d2 = step( Progress - Beam_Size, field );

    vec3 beam = vec3( d2 - d1 ) * Beam_Color * Glow_Boost;

    tex.rgb += beam;
    tex.a *= d2;

    P_COLOR vec4 COLOR = tex;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
