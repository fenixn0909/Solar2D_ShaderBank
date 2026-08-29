
--[[
    https://godotshaders.com/shader/tiler-pseudo-splatter/
    ProfesorShader
    July 19, 2026

    Direct port - no textures beyond the object's own (tex_draw ->
    CoronaSampler0), no loops, same grid/random/rotation math as the
    original. Params packed across two mat4 blocks: block0 is
    grid/motion/rotation (12 of 16 slots used), block1 is the two
    random-mix colors (8 of 16 used).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "tilerSplatter"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Random_Seed','Grid_Size_X','Grid_Size_Y','Cell_Offset_X',
            'Cell_Offset_Y','Speed_X','Speed_Y','Draw_Size_Min',
            'Draw_Size_Max','Rot_Global_Speed','Rot_Min_Speed','Rot_Max_Speed',
            '','','','',
        },
        default = {
            0, 16, 9, 0,
            0, 0, 0, .1,
            .4, 1, .1, 1,
            0,0,0,0,
        },
        min = {
            0, 1, 1, -4,
            -4, -2, -2, .01,
            .01, 0, 0, 0,
            0,0,0,0,
        },
        max = {
            100, 40, 40, 4,
            4, 2, 2, 1,
            1, 10, 1, 1,
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

float Random_Seed      = u_UserData0[0][0];
vec2  Grid_Size        = vec2( u_UserData0[0][1], u_UserData0[0][2] );
vec2  Cell_Offset      = vec2( u_UserData0[0][3], u_UserData0[1][0] );
vec2  Speed            = vec2( u_UserData0[1][1], u_UserData0[1][2] );
float Draw_Size_Min    = u_UserData0[1][3];
float Draw_Size_Max    = u_UserData0[2][0];
float Rot_Global_Speed = u_UserData0[2][1];
float Rot_Min_Speed    = u_UserData0[2][2];
float Rot_Max_Speed    = u_UserData0[2][3];

vec4 Color_A = vec4( u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2], u_UserData1[0][3] );
vec4 Color_B = vec4( u_UserData1[1][0], u_UserData1[1][1], u_UserData1[1][2], u_UserData1[1][3] );

const float INV_SQRT2 = 0.70710678118;
float TIME = CoronaTotalTime;

//----------------------------------------------

float random( vec2 xy )
{
    return fract( sin( dot( xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453 );
}

vec2 rotateUV( vec2 uv, vec2 pivot, float angle )
{
    mat2 rotation = mat2( vec2( sin( angle ), -cos( angle ) ),
                           vec2( cos( angle ), sin( angle ) ) );
    uv -= pivot;
    uv = uv * rotation;
    uv += pivot;
    return uv;
}

vec4 draw_tile( vec4 default_color, vec2 local_uv, vec2 center, float size, float speed, vec4 color )
{
    vec2 tile_uv_map = ( local_uv - center ) / size + 0.5;
    tile_uv_map = rotateUV( tile_uv_map, vec2( 0.5 ), TIME * speed );

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
    float draw_size = mix( Draw_Size_Min, min( Draw_Size_Max, INV_SQRT2 ), random( random_offset ) );
    float edge_margin = draw_size * INV_SQRT2;
    float tile_rot_speed =
        Rot_Global_Speed *
        ( step( 0.5, random( cell_num + 1.0 ) ) * 2.0 - 1.0 ) *
        mix( Rot_Min_Speed, Rot_Max_Speed, random( cell_num + 2.0 ) );

    vec2 draw_center = vec2(
        mix( edge_margin, 1.0 - edge_margin, random( cell_num + 3.0 ) ),
        mix( edge_margin, 1.0 - edge_margin, random( cell_num + 4.0 ) )
    );

    vec4 tile_color = vec4( 1.0 );
    tile_color.rgb = mix( Color_A.rgb, Color_B.rgb, random( cell_num + 5.0 ) );
    tile_color.a = mix( Color_A.a, Color_B.a, random( cell_num + 6.0 ) );

    return draw_tile( default_color, local_pos, draw_center, draw_size, tile_rot_speed, tile_color );
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

