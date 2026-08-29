
--[[
    https://godotshaders.com/shader/highlight-shader-godot-4-5-compat/
    stnsk
    November 2, 2025

    Direct port, single texture (CoronaSampler0). The original
    discards fully-transparent pixels; this bank signals "invisible"
    via alpha = 0 instead, for consistency with everything else here.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "diagonalHighlight"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Line_Width','Pause_Duration','Offset',
            'Pixelate_Line','Line_Color_R','Line_Color_G','Line_Color_B',
            'Line_Color_A','','','',
            '','','','',
        },
        default = { 1,.15,.15,2,  1,1,1,1,  1,0,0,0,  0,0,0,0, },
        min =     { 0,0,0,.2,     0,0,0,0,  0,0,0,0,  0,0,0,0, },
        max =     { 5,.2,2,5,     1,1,1,1,  1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Speed          = u_UserData0[0][0];
float Line_Width      = u_UserData0[0][1];
float Pause_Duration  = u_UserData0[0][2];
float Offset           = u_UserData0[0][3];
float Pixelate_Line   = u_UserData0[1][0];
vec4  Line_Color        = vec4( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );

float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 base_texture = texture2D( CoronaSampler0, UV );

    if ( base_texture.a < 0.01 ) {
        P_COLOR vec4 COLOR = vec4( 0.0 );
        return CoronaColorScale( COLOR );
    }

    float cycle_duration = Offset + Pause_Duration;
    float adjusted_time = mod( TIME * Speed, cycle_duration );

    float line_position;
    if ( adjusted_time <= Offset ) {
        line_position = Offset - adjusted_time;
    } else {
        line_position = -0.3;
    }

    vec2 uv_for_line = UV;

    if ( Pixelate_Line > 0.5 ) {
        vec2 texture_size = CoronaTexelSize.zw;
        uv_for_line = floor( UV * texture_size ) / texture_size;
    }

    vec2 rotated_uv = vec2( uv_for_line.x + uv_for_line.y, uv_for_line.y - uv_for_line.x ) * 0.5;
    float dist = abs( rotated_uv.x - line_position );

    float line_intensity = smoothstep( Line_Width, 0.0, dist );

    vec3 final_color = mix( base_texture.rgb, Line_Color.rgb, line_intensity * Line_Color.a );

    P_COLOR vec4 COLOR = vec4( final_color, base_texture.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

