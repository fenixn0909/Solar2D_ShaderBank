
--[[
    https://godotshaders.com/shader/frostbite/
    TTien63
    July 3, 2026

    Core structure ported as-is: superellipse vignette growth, Voronoi
    ice-cell cracking (SEARCH_RADIUS is a compile-time const in the
    original too, so the 3x3 cell search is already GLES2-safe),
    per-cell timing variation, edge highlight, ice tint, and crack-based
    UV displacement.
    Simplified out, to keep this both compileable and within the
    16-slot param budget:
    - `textureLod` mip-based frost blur -> a fixed 6-tap jittered
      average at the base mip (no `textureLod`/GL_EXT_shader_texture_lod
      dependency, since nothing else in this bank uses it). Reads
      softer/noisier than a true mip blur at high blur amounts, not
      identical.
    - Chromatic aberration and the per-pixel sparkle glint - both
      dropped entirely rather than approximated, to keep this shader
      verifiable.
    - `frost_samples` (was a uniform-driven loop count - not GLES2-safe
      as a loop bound) is now the fixed FROST_TAPS constant above.
    - `edge_displacement_bias` fixed at the original's own default
      (0.75) rather than exposed, to fit the param budget.
    CoronaSampler0 stands in for the original's screen-space capture
    (hint_screen_texture) - feed this filter a snapshot/render-to-
    texture of what should frost over, same as any other screen-space
    effect in Solar2D (no automatic backbuffer access like Godot's).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "frostbite"

kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Freeze_Progress','Pieces_X','Pieces_Y','Point_Jitter',
            'Frost_Blur','Frost_Scatter_Radius','Displacement_Strength','Edge_Thickness',
            'Edge_Brightness','Ice_Tint_R','Ice_Tint_G','Ice_Tint_B',
            'Ice_Tint_A','Ice_Tint_Strength','Growth_Edge_Bias','Delay_Variation',
        },
        default = {
            0, 8, 5, .38,
            3.2, .008, .018, .006,
            1.1, .72, .88, 1.0,
            1.0, .28, 1.2, .35,
        },
        min = {
            0, 2, 2, 0,
            0, 0, 0, .0005,
            0, 0,0,0,
            0, 0, 0, 0,
        },
        max = {
            1, 24, 24, .48,
            6, .02, .05, .04,
            3, 1,1,1,
            1, 1, 2, .8,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Freeze_Progress       = u_UserData0[0][0];
vec2  Pieces                = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Point_Jitter          = u_UserData0[0][3];
float Frost_Blur            = u_UserData0[1][0];
float Frost_Scatter_Radius  = u_UserData0[1][1];
float Displacement_Strength = u_UserData0[1][2];
float Edge_Thickness        = u_UserData0[1][3];
float Edge_Brightness       = u_UserData0[2][0];
vec4  Ice_Tint               = vec4( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0] );
float Ice_Tint_Strength     = u_UserData0[3][1];
float Growth_Edge_Bias      = u_UserData0[3][2];
float Delay_Variation       = u_UserData0[3][3];

const float EDGE_DISPLACEMENT_BIAS = 0.75;
const int SEARCH_RADIUS = 1;
const int FROST_TAPS = 6;

//----------------------------------------------

float hash12( vec2 p )
{
    vec3 p3 = fract( vec3( p.xyx ) * 0.1031 );
    p3 += dot( p3, p3.yzx + 33.33 );
    return fract( ( p3.x + p3.y ) * p3.z );
}

vec2 hash22( vec2 p )
{
    return vec2(
        hash12( p + vec2( 1.23, 4.56 ) ),
        hash12( p + vec2( 7.89, 0.12 ) )
    );
}

mat2 rot2( float a )
{
    float s = sin( a );
    float c = cos( a );
    return mat2( vec2( c, -s ), vec2( s, c ) );
}

vec2 cell_point( vec2 cell_id )
{
    vec2 h = hash22( cell_id );
    return cell_id + 0.5 + ( h - 0.5 ) * ( Point_Jitter * 2.0 );
}

void voronoi_info( vec2 p, out vec2 owner_cell, out vec2 owner_point, out float edge_dist )
{
    vec2 base = floor( p );
    float best_d = 1e20;
    float second_d = 1e20;
    vec2 best_cell = vec2( 0.0 );
    vec2 best_point = vec2( 0.0 );

    for ( int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++ ) {
        for ( int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++ ) {
            vec2 c = base + vec2( float( i ), float( j ) );
            vec2 pt = cell_point( c );
            float d = distance( p, pt );
            if ( d < best_d ) {
                second_d = best_d;
                best_d = d;
                best_cell = c;
                best_point = pt;
            } else if ( d < second_d ) {
                second_d = d;
            }
        }
    }
    owner_cell = best_cell;
    owner_point = best_point;
    edge_dist = second_d - best_d;
}

vec4 sample_frost( vec2 uv, float blur_amount )
{
    vec4 col = vec4( 0.0 );
    for ( int i = 0; i < FROST_TAPS; i++ ) {
        vec2 jitter_seed = uv + vec2( float( i ) * 0.371, float( i ) * 0.618 );
        vec2 offset = ( hash22( jitter_seed * 31.7 ) - 0.5 ) * 2.0 * Frost_Scatter_Radius * Frost_Blur * blur_amount;
        col += texture2D( CoronaSampler0, clamp( uv + offset, vec2( 0.0 ), vec2( 1.0 ) ) );
    }
    return col / float( FROST_TAPS );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    vec2 grid = Pieces;

    vec2 q = abs( uv - 0.5 );
    float superellipse_pow = mix( 2.0, 10.0, clamp( Growth_Edge_Bias / 2.0, 0.0, 1.0 ) );
    float sdf = pow( pow( q.x, superellipse_pow ) + pow( q.y, superellipse_pow ), 1.0 / superellipse_pow );

    float vignette = clamp( sdf / 0.5, 0.0, 1.0 );
    float pixel_freeze = clamp( vignette * 0.5 + Freeze_Progress * 1.2 - 0.2, 0.0, 1.0 );

    vec2 p_now = uv * grid;
    vec2 now_cell, now_point;
    float now_edge;
    voronoi_info( p_now, now_cell, now_point, now_edge );

    float rnd_cell = hash12( now_cell );
    float cell_offset = ( rnd_cell - 0.5 ) * Delay_Variation * 0.4;
    float cell_t = clamp( ( pixel_freeze - cell_offset ) / max( 0.0001, 1.0 - abs( cell_offset ) ), 0.0, 1.0 );
    cell_t = smoothstep( 0.0, 1.0, cell_t );

    float edge_factor = 1.0 - smoothstep( 0.0, Edge_Thickness, now_edge );

    vec2 cell_center_uv = now_point / grid;
    vec2 displace_dir = normalize( uv - cell_center_uv + vec2( 0.0001 ) );
    float displace_amount = mix(
        Displacement_Strength * cell_t * 0.3,
        Displacement_Strength * cell_t,
        edge_factor * EDGE_DISPLACEMENT_BIAS
    );
    float rnd_angle = ( hash12( now_cell + 3.7 ) - 0.5 ) * 0.8;
    displace_dir = rot2( rnd_angle ) * displace_dir;
    vec2 warped_uv = clamp( uv + displace_dir * displace_amount, vec2( 0.0 ), vec2( 1.0 ) );

    float frost_blend = smoothstep( 0.2, 1.0, cell_t );

    vec4 col_base = texture2D( CoronaSampler0, warped_uv );
    vec4 col_frost = sample_frost( warped_uv, cell_t );

    vec4 col = mix( col_base, col_frost, frost_blend );

    col.rgb = mix( col.rgb, Ice_Tint.rgb * ( col.r * 0.2 + col.g * 0.5 + col.b * 0.3 + 0.4 ), Ice_Tint_Strength * cell_t );

    vec3 edge_color = mix( vec3( 1.0 ), Ice_Tint.rgb, 0.3 ) * Edge_Brightness;
    col.rgb += edge_factor * edge_color * cell_t;

    vec4 original = texture2D( CoronaSampler0, uv );
    col = mix( original, col, cell_t );

    P_COLOR vec4 COLOR = col;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

