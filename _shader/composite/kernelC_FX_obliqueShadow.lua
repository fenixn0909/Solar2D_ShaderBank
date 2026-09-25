
--[[
    https://godotshaders.com/shader/2d-top-down-oblique-shadow/
    inno
    April 16, 2026

    paint1 = albedo_map (the sprite's own color/alpha), paint2 =
    height_map (greyscale, R channel = height). Core raymarch/occlusion
    logic ported as-is, including the compile-time-constant MAX_STEPS
    loop with a uniform-driven early break (that pattern is GLES2-safe;
    a uniform directly as a loop bound is not, which is why MAX_STEPS
    exists in the original too).
    Dropped: source_uv_scale/carrier_scale (existed together to let
    the shadow draw beyond the sprite's own bounds via vertex-kernel
    geometry expansion - same "size your object larger yourself" note
    as the wall-destruction port), shadow_ray_offset_px (minor
    anti-artifact tweak), alpha_cutoff as a tunable (fixed at 0.01,
    matching the original's own default), and the use_albedo_alpha_mask
    / shadow_aa_enabled toggles (folded into always-on / "radius > 0"
    respectively, to fit the param budget).
    Re-derived in pure UV-space rather than pixel-space (no reliable
    per-texture texel size for a composite kernel's two independent
    textures) - Step_Uv/Shadow_Aa_Radius_Uv are fractions of UV width
    instead of pixel counts. The height-gained-per-distance-travelled
    math is scale-invariant to that swap, so the shadow-length/height
    calibration carries over unchanged.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "obliqueShadow"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Height_Uv_Scale','Sun_Dir_X','Sun_Dir_Y','Sun_Dir_Z',
            'Height_Scale','Step_Uv','Steps','Shadow_Softness',
            'Shadow_Aa_Radius_Uv','Shadow_Strength','Shadow_Tint_R','Shadow_Tint_G',
            'Shadow_Tint_B','Shadow_Tint_A','Draw_Shadow_On_Transparent','Draw_Albedo',
        },
        default = {
            1, .6, .4, 1,
            1, .01, 32, .08,
            .006, .65, 0,0,
            0,1, 1, 1,
        },
        min = {
            .1, -1, -1, .05,
            0, .002, 1, .01,
            0, 0, 0,0,
            0,0, 0, 0,
        },
        max = {
            4, 1, 1, 2,
            4, .05, 96, .5,
            .05, 1, 1,1,
            1,1, 1, 1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Height_Uv_Scale             = u_UserData0[0][0];
vec3  Sun_Dir                     = vec3( u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3] );
float Height_Scale                = u_UserData0[1][0];
float Step_Uv                     = u_UserData0[1][1];
float Steps                       = u_UserData0[1][2];
float Shadow_Softness             = u_UserData0[1][3];
float Shadow_Aa_Radius_Uv         = u_UserData0[2][0];
float Shadow_Strength             = u_UserData0[2][1];
vec4  Shadow_Tint                 = vec4( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0], u_UserData0[3][1] );
float Draw_Shadow_On_Transparent  = u_UserData0[3][2];
float Draw_Albedo                 = u_UserData0[3][3];

const int MAX_STEPS = 96;
const float ALPHA_CUTOFF = 0.01;

//----------------------------------------------

float sample_height( vec2 uv )
{
    if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 ) {
        return 0.0;
    }

    vec2 huv = ( uv - vec2( 0.5 ) ) * max( Height_Uv_Scale, 1e-4 ) + vec2( 0.5 );
    huv = clamp( huv, vec2( 0.0 ), vec2( 1.0 ) );

    float h = texture2D( CoronaSampler1, huv ).r * Height_Scale;
    float mask_alpha = texture2D( CoronaSampler0, huv ).a;
    h *= step( ALPHA_CUTOFF, mask_alpha );
    return h;
}

float trace_shadow_occlusion( vec2 start_uv, float start_h, vec2 step_uv, float ray_rise_per_step, float edge_softness )
{
    float occlusion = 0.0;
    float ray_h = start_h;
    vec2 uv = start_uv;

    for ( int i = 0; i < MAX_STEPS; i++ ) {
        if ( float( i ) >= Steps ) {
            break;
        }

        uv -= step_uv;
        ray_h += ray_rise_per_step;

        if ( uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 ) {
            break;
        }

        float h = sample_height( uv );
        float occ_step = smoothstep( 0.0, edge_softness, h - ray_h );
        occlusion = max( occlusion, occ_step );
        if ( occlusion > 0.999 ) {
            break;
        }
    }

    return occlusion;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec4 base = vec4( 0.0 );
    if ( Draw_Albedo > 0.5 ) {
        base = texture2D( CoronaSampler0, UV );
    }

    float h0 = sample_height( UV );

    vec3 L = normalize( Sun_Dir );
    float sun_xy_len = max( length( L.xy ), 1e-5 );
    float sun_z = max( L.z, 1e-4 );

    vec2 dir_uv = normalize( L.xy );
    vec2 step_uv = dir_uv * Step_Uv;

    float ray_rise_per_step = ( sun_z / sun_xy_len ) * ( Step_Uv * 2.0 );

    vec2 start_uv = UV;
    float edge_softness = max( Shadow_Softness, 1e-4 );

    float occlusion = trace_shadow_occlusion( start_uv, h0, step_uv, ray_rise_per_step, edge_softness );

    if ( Shadow_Aa_Radius_Uv > 0.0 ) {
        vec2 perp_uv = vec2( -dir_uv.y, dir_uv.x ) * Shadow_Aa_Radius_Uv;

        float h_p05 = sample_height( UV + perp_uv * 0.5 );
        float h_n05 = sample_height( UV - perp_uv * 0.5 );
        float h_p15 = sample_height( UV + perp_uv * 1.5 );
        float h_n15 = sample_height( UV - perp_uv * 1.5 );

        float occ_p05 = trace_shadow_occlusion( start_uv + perp_uv * 0.5, h_p05, step_uv, ray_rise_per_step, edge_softness );
        float occ_n05 = trace_shadow_occlusion( start_uv - perp_uv * 0.5, h_n05, step_uv, ray_rise_per_step, edge_softness );
        float occ_p15 = trace_shadow_occlusion( start_uv + perp_uv * 1.5, h_p15, step_uv, ray_rise_per_step, edge_softness );
        float occ_n15 = trace_shadow_occlusion( start_uv - perp_uv * 1.5, h_n15, step_uv, ray_rise_per_step, edge_softness );

        occlusion = ( occlusion + occ_p05 + occ_n05 + occ_p15 + occ_n15 ) / 5.0;
    }

    float shadow = Shadow_Strength * occlusion;

    // shadow behind sprite, not on it – keep albedo intact where opaque
    P_COLOR vec4 COLOR = vec4( 0.0 );
    if ( base.a > ALPHA_CUTOFF ) {
        COLOR = base;
    } else if ( Draw_Shadow_On_Transparent > 0.5 && shadow > 0.0 ) {
        COLOR = Shadow_Tint;
        COLOR.a *= shadow;
    } else if ( shadow > 0.001 ) {
        // fallback dark shadow on transparent when tint is black and Draw_Shadow_On_Transparent is off
        // keep transparent so background shows through – caller can composite shadow behind
        COLOR = vec4( 0.0 );
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

