
--[[
    https://godotshaders.com/shader/2d-water-for-topdown-games/
    Sir-Shroom
    July 9, 2025
    (uses modified parts of "Rainier mood" by RayL019 and "Neuronal
    Network Waves" by ahaugas, both godotshaders.com, per the original
    post's own credit)

    paint1 = shape mask (CoronaSampler0, its alpha marks "water exists
    here" - matches the original's use of the object's own TEXTURE.a
    as a boundary mask), paint2 = the backdrop to distort/tint
    (CoronaSampler1, stands in for the original's live screen capture -
    feed it a snapshot/render-texture of what should show through).

    Two changes from the original:
    1. Dropped the dFdx/dFdy-based specular normal term. Screen-space
       derivatives need the GL_OES_standard_derivatives extension,
       which nothing else in this bank relies on - not worth the risk
       for one small specular highlight when the 30-iteration wave
       pattern already carries most of the visual interest.
    2. Fixed a real bug from the original: wave_highlight's pow() could
       receive a negative base, which is undefined in GLSL. This is a
       documented issue in the post's own comment thread ("black
       patches" - several users confirmed it); the fix here (clamping
       the base to >= 0 before pow()) is the community-verified one
       from that thread, not something invented here.

    Added a Speed control (not in the original) - multiple commenters
    on the post asked for exactly this, and one posted the fix: scale
    every TIME reference by it.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "stylizedWaterV2"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = { 'Intensity','Highlight_Scale','Clarity','Speed', 'Water_Color_R','Water_Color_G','Water_Color_B','', '','','','', '','','','', },
        default =   { .5,1,.65,1,  .105,.15,.118,0,  0,0,0,0,  0,0,0,0, },
        min =       { 0,.1,0,0,    0,0,0,0,          0,0,0,0,  0,0,0,0, },
        max =       { 1,3,1,3,     1,1,1,1,          1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Intensity       = u_UserData0[0][0];
float Highlight_Scale = u_UserData0[0][1];
float Clarity         = u_UserData0[0][2];
float Speed            = u_UserData0[0][3];
vec3 Water_Color = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );

const int MAX_RADIUS = 2;
const float HASHSCALE1 = 0.1031;
const vec3 HASHSCALE3 = vec3(0.1031, 0.1030, 0.0973);
const float RIPPLE_FREQ = 31.0;
const float RIPPLE_STRENGTH = 0.1;
const float HIGHLIGHT_POW = 2.1;

float TIME = CoronaTotalTime;

//----------------------------------------------

mat2 rotate2D( float r )
{
    return mat2( vec2( cos( r ), sin( r ) ), vec2( -sin( r ), cos( r ) ) );
}

float hash12( vec2 p )
{
    vec3 p3 = fract( vec3( p.xyx ) * HASHSCALE1 );
    p3 += dot( p3, p3.yzx + 19.19 );
    return fract( ( p3.x + p3.y ) * p3.z );
}

vec2 hash22( vec2 p )
{
    vec3 p3 = fract( vec3( p.xyx ) * HASHSCALE3 );
    p3 += dot( p3, p3.yzx + 19.19 );
    return fract( ( p3.xx + p3.yz ) * p3.zy );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    float iTime = TIME * Speed;

    // --- RIPPLE EFFECT ---
    vec2 uv_scaled = uv * vec2( 10.0, 10.0 );
    vec2 base_cell = floor( uv_scaled );
    vec2 ripple_offset = vec2( 0.0 );

    for ( int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j ) {
        for ( int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i ) {
            vec2 cell = base_cell + vec2( float( i ), float( j ) );
            if ( fract( hash12( cell ) * 123.456 ) < Intensity ) {
                vec2 p = cell + hash22( cell );
                float t = fract( 0.3 * iTime + hash12( cell ) );
                vec2 v = p - uv_scaled;
                v.y *= 1.5;
                float d = length( v ) - ( float( MAX_RADIUS ) + 1.0 ) * t;
                float h = 1e-3;
                float d1 = d - h;
                float d2 = d + h;
                float p1 = sin( RIPPLE_FREQ * d1 ) * smoothstep( -0.6, -0.3, d1 ) * smoothstep( 0.0, -0.3, d1 );
                float p2 = sin( RIPPLE_FREQ * d2 ) * smoothstep( -0.6, -0.3, d2 ) * smoothstep( 0.0, -0.3, d2 );
                ripple_offset += 0.5 * normalize( v ) * ( ( p2 - p1 ) / ( 2.0 * h ) * pow( 1.0 - t, 2.0 ) );
            }
        }
    }

    ripple_offset /= float( ( MAX_RADIUS * 2 + 1 ) * ( MAX_RADIUS * 2 + 1 ) );
    ripple_offset *= RIPPLE_STRENGTH;

    // --- DISTORTION ---
    vec2 wave_offset = vec2( sin( uv.x * 10.0 + iTime ), cos( uv.y * 10.0 + iTime ) ) * 0.005;
    vec2 distortion = ripple_offset * Intensity + wave_offset * Speed;

    // --- BASE WATER COLOR (no dFdx/dFdy specular - see header) ---
    vec3 screen_color = texture2D( CoronaSampler1, uv + distortion ).rgb;
    vec3 blended_color = mix( screen_color, Water_Color, Clarity );
    vec3 water_color = blended_color * 1.2;

    // --- WAVE HIGHLIGHT CALCULATION ---
    vec2 wave_uv = ( uv * Highlight_Scale ) + distortion;
    vec2 wave_n = vec2( 0.0 );
    vec2 wave_sum = vec2( 0.0 );
    float S = 10.0;
    mat2 rot = rotate2D( 1.0 );

    for ( float j = 0.0; j < 30.0; ++j ) {
        wave_uv *= rot;
        wave_n *= rot;
        vec2 q = wave_uv * S + j + wave_n + iTime;
        wave_n += sin( q );
        wave_sum += cos( q ) / S;
        S *= 1.2;
    }

    float wave_len = max( length( wave_sum ), 0.001 );
    // clamped to >= 0 before pow() - community-verified fix, see header
    float highlight_input = max( ( wave_sum.x + wave_sum.y + 0.4 ) + 0.005 / wave_len, 0.0 );
    vec3 wave_highlight = vec3( 1.0 ) * pow( highlight_input, HIGHLIGHT_POW );

    // --- BLEND FACTOR ---
    float brightness = dot( wave_highlight, vec3( 0.299, 0.587, 0.114 ) );
    float blend_factor = smoothstep( 1.3, 1.301, brightness );

    // --- FINAL COMPOSITE ---
    vec3 final_color = mix( water_color, wave_highlight, blend_factor );
    float shape_alpha = texture2D( CoronaSampler0, UV ).a;

    P_COLOR vec4 COLOR = vec4( final_color, shape_alpha );
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

