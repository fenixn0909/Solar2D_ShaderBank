
--[[
    https://godotshaders.com/shader/hex-grid-transition-shader/
    muzi1983
    January 23, 2026

    filter: fades sprite alpha by hex mask (the outgoing/incoming scene
    snapshots, matching the original's usage notes exactly). Direct
    port, nothing dropped - screen_size is read from CoronaTexelSize.zw
    instead of being derived from SCREEN_PIXEL_SIZE, same value either way.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "trans"
kernel.name = "hexGrid"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Hex_Size','Randomness','Edge_Softness',
            'Transition_Speed','','','',
            '','','','',
            '','','','',
        },
        default = { 0,.08,.05,.01,  .3,0,0,0,  0,0,0,0,  0,0,0,0, },
        min =     { 0,.01,0,0,      .05,0,0,0, 0,0,0,0,  0,0,0,0, },
        max =     { 1,.5,1,.2,      1,1,1,1,   1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Progress          = u_UserData0[0][0];
float Hex_Size           = u_UserData0[0][1];
float Randomness         = u_UserData0[0][2];
float Edge_Softness      = u_UserData0[0][3];
float Transition_Speed   = u_UserData0[1][0];

//----------------------------------------------

float hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

vec2 hextile( inout vec2 p )
{
    const vec2 s = vec2( 1.0, 1.7320508 );
    const vec2 hs = s * 0.5;

    vec2 a = mod( p, s ) - hs;
    vec2 b = mod( p - hs, s ) - hs;

    vec2 c = dot( a, a ) < dot( b, b ) ? a : b;
    vec2 id = ( c - p + hs ) / s;

    p = c;
    return floor( id );
}

float hexDist( vec2 p, float r )
{
    p = abs( p );
    return max( p.x * 0.866025 + p.y * 0.5, p.y ) - r;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    // filter version: fade sprite with hex shape (1 = visible, 0 = transparent)
    P_COLOR vec4 final_color = texture2D( CoronaSampler0, uv );

    if ( Progress > 0.0 ) {
        vec2 screen_size = CoronaTexelSize.zw;
        vec2 p = uv - 0.5;
        float aspect = screen_size.x / screen_size.y;
        p.x *= aspect * 0.9;
        vec2 hp = p / Hex_Size;
        vec2 id = hextile( hp );

        float delay = ( uv.x + uv.y ) * 0.5;
        float hex_progress = Progress >= 1.0 ? 1.0 : smoothstep(
            delay - Transition_Speed,
            delay + Transition_Speed,
            Progress * ( 1.0 + Transition_Speed )
        );
        hex_progress = clamp( hex_progress, 0.0, 1.0 );

        float r = hash( id );
        float t = Progress >= 1.0 ? 1.0 : clamp( hex_progress - r * Randomness, 0.0, 1.0 );
        float h = hexDist( hp, t * 0.9 );
        float mask = smoothstep( Edge_Softness, -Edge_Softness, h );
        mask = Progress >= 1.0 ? 1.0 : mask;

        vec3 from_col = texture2D( CoronaSampler0, uv ).rgb;
        vec3 to_col = vec3(0.0);
        vec3 col = mix( from_col, to_col, mask );

        final_color = vec4( col, final_color.a * mask );
    }

    if ( Progress >= 1.0 ) {
        final_color.a = 0.0;
    }

    P_COLOR vec4 COLOR = final_color;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

