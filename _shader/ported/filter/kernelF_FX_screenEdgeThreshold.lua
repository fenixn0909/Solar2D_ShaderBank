
--[[
    https://godotshaders.com/shader/stylized-screen-edge-with-threshold-fx/
    TTien63
    March 30, 2026

    Geometry re-derived in normalized UV space instead of the original's
    raw pixel/FRAGCOORD space (which relied on Godot's SCREEN_PIXEL_SIZE) -
    same rotated-band test, just resolution-independent instead of
    width-pixel-based. `textureLod(..., 0.0)` (a plain base-level sample,
    no actual mip blur) is a plain texture2D() here.
    IMPORTANT: the invert/threshold branch samples CoronaSampler0 as "the
    screen" the same way Godot's hint_screen_texture auto-captures the
    backbuffer - Solar2D has no automatic equivalent, so feed this filter
    a snapshot/render-to-texture of what you want thresholded (or just
    leave Invert at 0 for plain fill-color bars, no capture needed).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "screenEdgeThreshold"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Roll','Rotate_Angle','Offset','Invert',
            'Threshold','Smoothness','Bw_Invert','Intensity',
            '','','','',
            '','','','',
        },
        default = {
            0, 0, .75, 0,
            .5, .05, 0, 1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -2, -3.14159, 0, 0,
            0, 0, 0, 0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            2, 3.14159, 1.2, 1,
            1, .5, 1, 1,
            1,1,1,1,
            1,1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Fill_Color_R','Fill_Color_G','Fill_Color_B','Fill_Color_A',
            'Bg_Color_R','Bg_Color_G','Bg_Color_B','Bg_Color_A',
            'Fg_Color_R','Fg_Color_G','Fg_Color_B','Fg_Color_A',
            '','','','',
        },
        default = {
            0,0,0,1,
            0,0,0,1,
            1,1,1,1,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
//----------------------------------------------

float Roll          = u_UserData0[0][0];
float Rotate_Angle   = u_UserData0[0][1];
float Offset         = u_UserData0[0][2];
float Invert         = u_UserData0[0][3];
float Threshold      = u_UserData0[1][0];
float Smoothness     = u_UserData0[1][1];
float Bw_Invert      = u_UserData0[1][2];
float Intensity      = u_UserData0[1][3];

vec4 Fill_Color = vec4( u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2], u_UserData1[0][3] );
vec4 Bg_Color   = vec4( u_UserData1[1][0], u_UserData1[1][1], u_UserData1[1][2], u_UserData1[1][3] );
vec4 Fg_Color   = vec4( u_UserData1[2][0], u_UserData1[2][1], u_UserData1[2][2], u_UserData1[2][3] );

//----------------------------------------------

bool is_inside( vec2 pos1, vec2 dir1, vec2 pos2, vec2 dir2, vec2 point )
{
    return ( dir1.x - pos1.x ) * ( point.y - pos1.y ) - ( dir1.y - pos1.y ) * ( point.x - pos1.x ) < 0.0 &&
           ( dir2.x - pos2.x ) * ( point.y - pos2.y ) - ( dir2.y - pos2.y ) * ( point.x - pos2.x ) > 0.0;
}

vec2 rotateUV( vec2 point, float angle )
{
    return vec2( point.x * cos( angle ) - point.y * sin( angle ),
                 point.x * sin( angle ) + point.y * cos( angle ) );
}

vec4 to_bw( vec4 screen_color )
{
    float luminance = dot( screen_color.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float value = smoothstep( Threshold - Smoothness, Threshold + Smoothness, luminance );
    vec4 final_color;
    if ( Bw_Invert > 0.5 ) {
        final_color = mix( Fg_Color, Bg_Color, value );
    } else {
        final_color = mix( Bg_Color, Fg_Color, value );
    }
    return mix( screen_color, final_color, Intensity );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 privot = vec2( 0.5, 0.5 );
    float half_size = Offset * 0.25;

    bool inside = is_inside(
        privot + rotateUV( vec2( 0.0, half_size ), Rotate_Angle ),
        privot + rotateUV( vec2( 0.0, half_size ) + vec2( 1.0, Roll ), Rotate_Angle ),
        privot - rotateUV( vec2( 0.0, half_size ), Rotate_Angle ),
        privot - rotateUV( vec2( 0.0, half_size ) + vec2( -1.0, Roll ), Rotate_Angle ),
        UV
    );

    P_COLOR vec4 COLOR;
    if ( inside ) {
        COLOR = vec4( 0.0, 0.0, 0.0, 0.0 );
    } else if ( Invert > 0.5 ) {
        vec4 screen = texture2D( CoronaSampler0, UV );
        COLOR = to_bw( screen );
    } else {
        COLOR = Fill_Color;
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

