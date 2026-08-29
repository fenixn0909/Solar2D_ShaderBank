
--[[
    https://godotshaders.com/shader/double-dither-stylized-transparency-shadows-retro-masks/
    nojoule
    February 10, 2026

    Direct port, no texture needed - pure generator, matches the
    original. resolution is auto-computed from CoronaTexelSize.zw
    instead of needing manual sync.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "doubleDither"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Center_X','Center_Y','Radius','Pixel_Size',
            'Dither_Offset_X','Dither_Offset_Y','Bayer_Size','Interpolate',
            'Invert','Falloff','Color_R','Color_G',
            'Color_B','Color_A','','',
        },
        default = { .5,.5,.45,8,  2,0,0,1,  0,2.5,0,0,  0,1,0,0, },
        min =     { 0,0,0,1,      -10,-10,0,0, 0,.1,0,0, 0,0,0,0, },
        max =     { 1,1,10,100,   10,10,2,1,   1,10,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

vec2  Center           = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Radius            = u_UserData0[0][2];
float Pixel_Size        = u_UserData0[0][3];
vec2  Dither_Offset     = vec2( u_UserData0[1][0], u_UserData0[1][1] );
float Bayer_Size        = u_UserData0[1][2];
float Interpolate       = u_UserData0[1][3];
float Invert            = u_UserData0[2][0];
float Falloff           = u_UserData0[2][1];
vec4  Color              = vec4( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0], u_UserData0[3][1] );

vec2 resolution = CoronaTexelSize.zw;

const int bayer2[4] = int[4](
    0, 2,
    3, 1
);

const int bayer4[16] = int[16](
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5
);

const int bayer8[64] = int[64](
    0, 32,  8, 40,  2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
);

//----------------------------------------------

float get_bayer2( vec2 coord )
{
    int x = int( mod( coord.x, 2.0 ) );
    int y = int( mod( coord.y, 2.0 ) );
    int index = y * 2 + x;
    return ( float( bayer2[index] ) + 0.5 ) / 4.0;
}

float get_bayer4( vec2 coord )
{
    int x = int( mod( coord.x, 4.0 ) );
    int y = int( mod( coord.y, 4.0 ) );
    int index = y * 4 + x;
    return ( float( bayer4[index] ) + 0.5 ) / 16.0;
}

float get_bayer8( vec2 coord )
{
    int x = int( mod( coord.x, 8.0 ) );
    int y = int( mod( coord.y, 8.0 ) );
    int index = y * 8 + x;
    return ( float( bayer8[index] ) + 0.5 ) / 64.0;
}

float get_dither( vec2 uv, vec2 step_size )
{
    vec2 bayer_coord = floor( uv / step_size + 1.0e-5 );
    vec2 grid_uv = bayer_coord * step_size + step_size * 0.5;
    float dist = distance( grid_uv, Center );
    float t = pow( clamp( dist / Radius, 0.0, 1.0 ), Falloff );
    float threshold;
    if ( Bayer_Size < 0.5 ) {
        threshold = get_bayer2( bayer_coord );
    } else if ( Bayer_Size < 1.5 ) {
        threshold = get_bayer4( bayer_coord );
    } else {
        threshold = get_bayer8( bayer_coord );
    }
    return step( threshold, 1.0 - t );
}

float get_mask( vec2 uv, vec2 step_size, vec2 offset )
{
    float d1 = get_dither( uv, step_size );
    float d2 = get_dither( uv - offset, step_size );
    return max( d1, d2 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv_step = Pixel_Size / resolution;
    vec2 raw_offset_uv = round( Dither_Offset ) * uv_step;
    vec2 effective_offset = Interpolate > 0.5 ? raw_offset_uv * 0.5 : raw_offset_uv;
    vec2 centered_uv = UV + effective_offset * 0.5;
    float dither;

    if ( Interpolate > 0.5 ) {
        vec2 sub_step = uv_step * 0.5;
        vec2 quantized_uv = floor( centered_uv / uv_step ) * uv_step;

        vec2 q1 = vec2( uv_step.x * 0.25, uv_step.y * 0.25 );
        vec2 q3 = vec2( uv_step.x * 0.75, uv_step.y * 0.75 );

        float v1 = get_mask( quantized_uv + q1, sub_step, effective_offset );
        float v2 = get_mask( quantized_uv + vec2( q3.x, q1.y ), sub_step, effective_offset );
        float v3 = get_mask( quantized_uv + vec2( q1.x, q3.y ), sub_step, effective_offset );
        float v4 = get_mask( quantized_uv + q3, sub_step, effective_offset );

        dither = ( v1 + v2 + v3 + v4 ) * 0.25;
    } else {
        vec2 quantized_uv = floor( centered_uv / uv_step ) * uv_step;
        dither = get_mask( quantized_uv, uv_step, effective_offset );
    }

    P_COLOR vec4 COLOR = vec4( Color.rgb, Invert > 0.5 ? ( 1.0 - dither ) * Color.a : dither * Color.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

