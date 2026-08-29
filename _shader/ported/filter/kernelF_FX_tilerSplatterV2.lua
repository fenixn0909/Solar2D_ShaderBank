--[[
    https://godotshaders.com/shader/tiler-pseudo-splatter/
    ProfesorShader
    July 19, 2026

    V2 variant of the bank's existing kernelF_FX_tilerSplatter.lua
    (filter.FX.tilerSplatter) - same source, same URL. The original
    defines #define USE_ROTATION 1 and #define USE_COLOR_MODULATION 1
    at compile time; the existing port always leaves both on and
    exposes rotation speeds via uniforms. This V2 fixes rotation OFF
    (no per-tile spinning) and keeps color modulation, so you get a
    cheaper, static-splatter variant useful when you want the scatter
    without the spin - compare side-by-side in the viewer.

    If you want the rotating version, use the original tilerSplatter;
    if you want no color tint either, set Color_A == Color_B or edit this
    file to drop the color lerp.

    CC0.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "tilerSplatterV2"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Random_Seed','Grid_Size_X','Grid_Size_Y','Cell_Offset_X',
            'Cell_Offset_Y','Speed_X','Speed_Y','Draw_Size_Min',
            'Draw_Size_Max','','','',
            '','','','',
        },
        default = {
            0, 12, 7, 0,
            0, 0, 0, .12,
            .45, 0,0,0,
            0,0,0,0,
        },
        min = {
            0, 1, 1, -4,
            -4, -2, -2, .01,
            .01, 0,0,0,
            0,0,0,0,
        },
        max = {
            100, 40, 40, 4,
            4, 2, 2, 1,
            1, 1,1,1,
            1,1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Color_A_R','Color_A_G','Color_A_B','Color_A_A',
            'Color_B_R','Color_B_G','Color_B_B','Color_B_A',
            '','','','',
            '','','','',
        },
        default = {
            1,1,1,0,
            1,1,1,1,
            0,0,0,0,
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

float Random_Seed   = u_UserData0[0][0];
vec2  Grid_Size     = vec2( u_UserData0[0][1], u_UserData0[0][2] );
vec2  Cell_Offset   = vec2( u_UserData0[0][3], u_UserData0[1][0] );
vec2  Speed         = vec2( u_UserData0[1][1], u_UserData0[1][2] );
float Draw_Size_Min = u_UserData0[1][3];
float Draw_Size_Max = u_UserData0[2][0];

vec4 Color_A = vec4( u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2], u_UserData1[0][3] );
vec4 Color_B = vec4( u_UserData1[1][0], u_UserData1[1][1], u_UserData1[1][2], u_UserData1[1][3] );

float TIME = CoronaTotalTime;

//----------------------------------------------

float random( vec2 xy )
{
    return fract( sin( dot( xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );
}

vec4 draw_tile( vec4 default_color, vec2 local_uv, vec2 center, float size, vec4 color )
{
    vec2 tile_uv_map = ( local_uv - center ) / size + 0.5;
    // V2: rotation disabled - no rotateUV call (saves a mat2 + sin/cos per tile)
    if ( tile_uv_map.x < 0.0 || tile_uv_map.x > 1.0 ||
         tile_uv_map.y < 0.0 || tile_uv_map.y > 1.0 ) {
        return default_color;
    }
    vec4 s = texture2D( CoronaSampler0, tile_uv_map );
    return s * color;
}

vec4 draw_layer( vec4 default_color, vec2 uv )
{
    vec2 grid_uv = ( uv * Grid_Size ) - ( Speed * TIME ) + Cell_Offset;
    vec2 cell_num = floor( grid_uv );
    vec2 local_pos = fract( grid_uv );

    vec2 random_offset = Random_Seed + cell_num;
    float draw_size = mix( Draw_Size_Min, Draw_Size_Max, random( random_offset ) );
    float edge_margin = draw_size * 0.5;

    vec2 draw_center = vec2(
        mix( edge_margin, 1.0 - edge_margin, random( cell_num + 3.0 ) ),
        mix( edge_margin, 1.0 - edge_margin, random( cell_num + 4.0 ) )
    );

    vec4 tile_color = vec4( 1.0 );
    tile_color.rgb = mix( Color_A.rgb, Color_B.rgb, random( cell_num + 5.0 ) );
    tile_color.a = mix( Color_A.a, Color_B.a, random( cell_num + 6.0 ) );

    return draw_tile( default_color, local_pos, draw_center, draw_size, tile_color );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = draw_layer( vec4( 0.0 ), UV );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
--]]
