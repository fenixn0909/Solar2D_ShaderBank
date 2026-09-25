
--[[
    https://godotshaders.com/shader/wall-destruction-block-break/
    Purga
    March 25, 2026

    Core grid-shatter/gravity/scatter/rotate/fade logic ported as-is.
    Two things dropped, both Godot-atlas/vertex-kernel specific:
    - REGION_RECT (atlas sub-region remapping) - assumes the object's
      own texture is the full block content, not an atlas sub-rect.
    - the original's `vertex() { VERTEX *= 1. + scale; }`, which grows
      the node's own geometry so scattered debris can fly outside the
      source silhouette. Solar2D vertex kernels can do the same thing,
      but that's a separate, riskier port than this fragment logic, so
      it's left out here - size your display object larger than the
      source art yourself if you want debris to travel past the edges,
      otherwise it will clip at the object's own bounds.

    Performance note carried over honestly: the original's own margins
    (y: -17..5, x: -8..8) mean up to 23x17 = 391 inner-loop iterations
    per pixel, each with 5 hash calls. That's what the original ships
    with (kept faithful rather than narrowed), but it's worth profiling
    on lower-end devices - reduce Grid_Size and/or the loop bounds
    below if it's too heavy.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "wallDestruction"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress_Fall','Progress_Rotation','Progress_Scatter','Progress_Fade',
            'Grid_Size_X','Grid_Size_Y','Gravity','Ground_Level',
            'Stack_Variation','Slide_On_Ground','','',
            '','','','',
        },
        default = {
            0, 0, 0, 0,
            10, 10, 6, .9,
            .15, .3, 0,0,
            0,0,0,0,
        },
        min = {
            0, 0, 0, 0,
            1, 1, 0, 0,
            0, 0, 0,0,
            0,0,0,0,
        },
        max = {
            1, 10, 6, 1,
            40, 40, 20, 2,
            1, 1, 1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress_Fall     = u_UserData0[0][0];
float Progress_Rotation = u_UserData0[0][1];
float Progress_Scatter  = u_UserData0[0][2];
float Progress_Fade     = u_UserData0[0][3];
vec2  Grid_Size         = vec2( u_UserData0[1][0], u_UserData0[1][1] );
float Gravity           = u_UserData0[1][2];
float Ground_Level      = u_UserData0[1][3];
float Stack_Variation   = u_UserData0[2][0];
float Slide_On_Ground   = u_UserData0[2][1];

//----------------------------------------------

float rnd( vec2 co )
{
    return fract( sin( dot( co.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 local_uv = UV;

    vec4 final_color = vec4( 0.0 );
    vec2 my_cell = floor( local_uv * Grid_Size );
    bool found = false;

    for ( int y = -17; y <= 5; y++ ) {
        for ( int x = -8; x <= 8; x++ ) {
            vec2 check_cell = my_cell + vec2( float( x ), float( y ) );

            if ( check_cell.x < 0.0 || check_cell.x >= Grid_Size.x ||
                 check_cell.y < 0.0 || check_cell.y >= Grid_Size.y ) {
                continue;
            }

            float r_delay   = rnd( check_cell ) * 0.2;
            float r_scatter = rnd( check_cell + vec2( 1.1, 0.0 ) );
            float r_rotate  = rnd( check_cell + vec2( 0.0, 1.1 ) );
            float r_stack   = rnd( check_cell + vec2( 1.1, 1.1 ) );
            float r_slide   = rnd( check_cell + vec2( 2.2, 0.0 ) );

            float p_fall = clamp( ( Progress_Fall - r_delay ) / 0.8, 0.0, 1.0 );
            float p_rot  = max( Progress_Rotation - r_delay, 0.0 );
            float p_scat = max( Progress_Scatter - r_delay, 0.0 );

            vec2 cell_center = ( check_cell + vec2( 0.5 ) ) / Grid_Size;

            float fall_dist = Gravity * p_fall * p_fall;
            float personal_ground = Ground_Level + ( r_stack - 0.5 ) * Stack_Variation;
            float final_y = min( cell_center.y + fall_dist, personal_ground );
            bool is_on_ground = ( cell_center.y + fall_dist ) >= personal_ground;

            float lateral_move = ( r_scatter - 0.5 ) * 0.4 * p_scat;
            float ground_slide_val = ( r_slide - 0.5 ) * Slide_On_Ground * ( is_on_ground ? p_scat : 0.0 );
            float final_x = cell_center.x + lateral_move + ground_slide_val;

            vec2 offset = vec2( final_x - cell_center.x, final_y - cell_center.y );

            float angle = ( r_rotate - 0.5 ) * 6.0 * p_rot;
            float c = cos( angle );
            float s = sin( angle );

            vec2 rel_uv = local_uv - cell_center - offset;
            vec2 rotated_rel_uv = vec2( rel_uv.x * c - rel_uv.y * s, rel_uv.x * s + rel_uv.y * c );
            vec2 orig_local_uv = cell_center + rotated_rel_uv;

            if ( floor( orig_local_uv * Grid_Size ) == check_cell ) {
                vec4 tex_color = texture2D( CoronaSampler0, orig_local_uv );
                if ( tex_color.a > 0.0 ) {
                    float local_fade = clamp( ( Progress_Fade - r_delay ) / 0.8, 0.0, 1.0 );
                    final_color = vec4( tex_color.rgb, tex_color.a * ( 1.0 - local_fade ) );
                    found = true;
                    break;
                }
            }
        }
        if ( found ) break;
    }

    P_COLOR vec4 COLOR = final_color;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

