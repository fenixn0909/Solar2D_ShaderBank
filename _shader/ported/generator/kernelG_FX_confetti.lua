
--[[
    https://godotshaders.com/shader/confetti-colorrect-godot-4-5/
    RedKnack Interactive
    February 17, 2026

    Direct port, no texture needed - pure generator (120-particle
    const loop, GLES2-safe already since it's a compile-time constant,
    not uniform-driven). The 8-color palette is fixed to the original's
    defaults rather than exposed (32 scalars for colors alone, matching
    this bank's usual palette-fixing precedent - Balatro, TorchFlame).

    Performance note straight from the author's own reply on the post:
    "loops over all 120 particles for every single pixel on screen...
    mainly meant as a visual effect for menus or UI, not gameplay." A
    full-screen use of this at 120 particles is genuinely heavy -
    that's not a Solar2D-specific issue, it's inherent to the technique.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "confetti"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Sway_Strength','Sway_Speed','Spin_Speed',
            'Piece_Size','Aspect_Ratio','','',
            '','','','',
            '','','','',
        },
        default = { 120,60,1.4,3.5,  10,2,0,0,  0,0,0,0,  0,0,0,0, },
        min =     { 20,0,.1,0,       2,.2,0,0,  0,0,0,0,  0,0,0,0, },
        max =     { 500,200,5,10,    30,3,1,1,  1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

#define TAU 6.28318530718
#define PARTICLE_COUNT 120

uniform P_COLOR mat4 u_UserData0;

float Speed          = u_UserData0[0][0];
float Sway_Strength  = u_UserData0[0][1];
float Sway_Speed     = u_UserData0[0][2];
float Spin_Speed     = u_UserData0[0][3];
float Piece_Size     = u_UserData0[1][0];
float Aspect_Ratio   = u_UserData0[1][1];

vec4 col0 = vec4( 1.00, 0.20, 0.20, 1.0 );
vec4 col1 = vec4( 1.00, 0.75, 0.10, 1.0 );
vec4 col2 = vec4( 0.10, 0.80, 0.30, 1.0 );
vec4 col3 = vec4( 0.15, 0.55, 1.00, 1.0 );
vec4 col4 = vec4( 0.85, 0.20, 1.00, 1.0 );
vec4 col5 = vec4( 1.00, 0.40, 0.70, 1.0 );
vec4 col6 = vec4( 0.10, 0.90, 0.95, 1.0 );
vec4 col7 = vec4( 1.00, 1.00, 1.00, 1.0 );

vec2 resolution = CoronaTexelSize.zw;
float TIME = CoronaTotalTime;

//----------------------------------------------

float rand( float seed )
{
    return fract( sin( seed * 127.1 + 311.7 ) * 43758.5453 );
}

vec4 palette_color( float t )
{
    int idx = int( t * 8.0 ) - ( ( int( t * 8.0 ) / 8 ) * 8 );
    if ( idx == 0 ) return col0;
    if ( idx == 1 ) return col1;
    if ( idx == 2 ) return col2;
    if ( idx == 3 ) return col3;
    if ( idx == 4 ) return col4;
    if ( idx == 5 ) return col5;
    if ( idx == 6 ) return col6;
    return col7;
}

vec2 rotate2d( vec2 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    return vec2( c * v.x - s * v.y,
                s * v.x + c * v.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 px = UV * resolution;
    vec4 out_color = vec4( 0.0 );

    for ( int i = 0; i < PARTICLE_COUNT; i++ ) {
        float fi = float( i );

        float start_x  = rand( fi * 1.234 )  * resolution.x;
        float start_y  = -( rand( fi * 5.678 ) * resolution.y );
        float t_offset = rand( fi * 9.101 )  * ( resolution.y + Piece_Size * 2.0 ) / Speed;

        float my_speed      = Speed         * ( 0.5 + rand( fi * 2.222 ) );
        float my_sway_str   = Sway_Strength * ( 0.3 + rand( fi * 3.333 ) * 1.4 );
        float my_sway_spd   = Sway_Speed    * ( 0.5 + rand( fi * 4.444 ) * 1.5 );
        float my_sway_phase = rand( fi * 6.666 ) * TAU;
        float my_spin       = Spin_Speed    * ( 0.5 + rand( fi * 7.777 ) * 1.5 )
                              * ( rand( fi * 8.888 ) > 0.5 ? 1.0 : -1.0 );
        float my_size       = Piece_Size    * ( 0.5 + rand( fi * 0.123 ) * 1.0 );
        float my_ar         = Aspect_Ratio  * ( 0.7 + rand( fi * 0.456 ) * 0.6 );

        float t     = mod( TIME + t_offset, ( resolution.y + my_size * 2.0 ) / my_speed );
        float cy    = start_y + t * my_speed;
        float cx    = start_x + my_sway_str * sin( t * my_sway_spd + my_sway_phase );
        float angle = t * my_spin;

        vec2 delta = px - vec2( cx, cy );
        delta = rotate2d( delta, -angle );
        vec2 local = delta / vec2( my_size * my_ar, my_size );

        float inside = step( max( abs( local.x ), abs( local.y ) ), 1.0 );

        if ( inside > 0.5 ) {
            float shimmer = 0.5 + 0.5 * sin( t * my_spin * 2.0 );
            vec4 base_col = palette_color( rand( fi * 0.321 ) );
            vec4 lit_col  = mix( base_col * 0.5, base_col, shimmer );
            lit_col.a     = 1.0;
            out_color = mix( out_color, lit_col, inside );
        }
    }

    P_COLOR vec4 COLOR = out_color;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

