
--[[
    https://godotshaders.com/shader/uv-stitching-and-scrolling/
    TsubakiLoL
    October 23, 2025

    paint1 = texture_1, paint2 = texture_2 (the two interleaved,
    oppositely-scrolling rows). Direct port, nothing dropped -
    screen_size read from CoronaTexelSize.zw instead of needing manual
    sync.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "uvStitchScroll"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Angle','Line_Distance','Texture_Distance','Texture_Width',
            'Scroll_Speed','Solid_Color_R','Solid_Color_G','Solid_Color_B',
            'Solid_Color_A','','','',
            '','','','',
        },
        default = { 0,.1,.1,.3,  .1,0,0,0,  0,0,0,0,  0,0,0,0, },
        min =     { -3.14159,0,0,.02,  -1,0,0,0,  0,0,0,0, 0,0,0,0, },
        max =     { 3.14159,1,1,1,     1,1,1,1,   1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Angle              = u_UserData0[0][0];
float Line_Distance      = u_UserData0[0][1];
float Texture_Distance   = u_UserData0[0][2];
float Texture_Width      = u_UserData0[0][3];
float Scroll_Speed       = u_UserData0[1][0];
vec4  Solid_Color         = vec4( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );

vec2 screen_size = CoronaTexelSize.zw;
float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float aspect_condition = step( screen_size.x, screen_size.y );
    float multi_width_x = mix( screen_size.y / screen_size.x, 1.0, aspect_condition );
    float multi_width_y = mix( 1.0, screen_size.x / screen_size.y, aspect_condition );

    float uv_x = UV.x / multi_width_x;
    float uv_y = UV.y / multi_width_y;

    float real_uv_x = uv_x * cos( Angle ) + uv_y * sin( Angle );
    float real_uv_y = -uv_x * sin( Angle ) + uv_y * cos( Angle );

    vec2 real_uv = vec2( real_uv_x, real_uv_y );
    float line_index = floor( real_uv.y / ( Texture_Width + Line_Distance ) );

    float line_local_y = fract( real_uv.y / ( Texture_Width + Line_Distance ) );

    float texture_selector = mod( line_index, 2.0 );
    float scroll_direction = ( texture_selector < 0.5 ) ? 1.0 : -1.0;

    float horizontal_scroll = TIME * Scroll_Speed * scroll_direction;

    float local_x = fract( real_uv.x / ( Texture_Width + Texture_Distance ) + horizontal_scroll );

    vec2 processed_uv = vec2( local_x, line_local_y );

    vec2 texture_uv = processed_uv * vec2(
        ( Texture_Distance + Texture_Width ) / Texture_Width,
        ( Texture_Width + Line_Distance ) / Texture_Width
    );

    vec4 color;
    if ( texture_uv.x > 1.0 || texture_uv.y > 1.0 ) {
        color = Solid_Color;
    } else if ( texture_selector < 0.5 ) {
        color = texture2D( CoronaSampler0, texture_uv );
    } else {
        color = texture2D( CoronaSampler1, texture_uv );
    }

    P_COLOR vec4 COLOR = ( color.a == 0.0 ) ? Solid_Color : color;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

