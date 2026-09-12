
--[[
    Original implementation for this bank. A one-shot combat impact
    flash: eight spark lines radiate from a point at hashed angles and
    lengths, plus a bright core disc, both driven by Progress (0 = the
    instant of impact, 1 = fully faded) rather than CoronaTotalTime -
    same static/tweened pattern as this bank's other combat one-shots
    (kernelF_FX_teleport.lua's Progress, kernelF_FX_burnFromPoint.lua's
    Radius). Reach snaps out fast in the first ~15% of Progress, then
    the whole burst fades over the remainder, matching how a real hit-
    spark reads (near-instant extension, quick decay).

    Checked against all existing kernels first: kernelF_FX_shockwave is
    a radial UV-distortion + chromatic-aberration ring (bends the
    image, draws no spark geometry); kernelG_FX_starburst is a steady,
    continuously-glowing pulsar/sun with soft rounded spikes, not a
    decaying one-shot; kernelF_FX_forceField/kernelG_FX_
    overchargeCore are sustained energy looks, not an instant flash.
    Nothing else in the bank is a decaying radiating-line impact burst.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "hitSparkBurst"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Point_X','Point_Y','Spark_Length',
            'Flash_Size','Line_Width','Color_R','Color_G',
            'Color_B','Seed','Aspect_Ratio','',
            '','','','',
        },
        default = {
            0,.5,.5,.4,
            .12,.02,1,.95,
            .6,0,1,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.1,
            .02,.005,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            .4,.08,1,1,
            1,50,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress      = u_UserData0[0][0];
vec2  Point         = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Spark_Length  = u_UserData0[0][3];
float Flash_Size    = u_UserData0[1][0];
float Line_Width    = u_UserData0[1][1];
vec3  Spark_Color   = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Seed          = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

const float PI = 3.14159265;
const float TAU = 6.28318530718;

//----------------------------------------------

P_RANDOM float spark_hash( float n )
{
    return fract( sin( n * 91.34 ) * 47453.5453 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 d = ( UV - Point ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( d );
    float ang = atan( d.y, d.x );

    float reach = smoothstep( 0.0, 0.15, Progress );
    float fade = 1.0 - smoothstep( 0.12, 1.0, Progress );

    float lines = 0.0;
    for ( int i = 0; i < 8; i++ )
    {
        float fi = float( i );
        float baseAngle = fi / 8.0 * TAU + Seed;
        float jitter = ( spark_hash( fi + Seed ) - 0.5 ) * 0.5;
        float angle = baseAngle + jitter;
        float angDiff = abs( mod( ang - angle + PI, TAU ) - PI );
        float len = Spark_Length * ( 0.6 + 0.4 * spark_hash( fi + Seed + 10.0 ) ) * reach;

        float alongLine = smoothstep( len, len * 0.85, dist ) * step( 0.0, len - dist );
        float widthMask = smoothstep( Line_Width, Line_Width * 0.2, angDiff * dist );
        lines = max( lines, alongLine * widthMask );
    }

    float flash = exp( -( dist * dist ) / max( Flash_Size * Flash_Size, 0.0001 ) ) * ( 1.0 - smoothstep( 0.0, 0.3, Progress ) );

    float alpha = clamp( ( lines + flash ) * fade, 0.0, 1.0 );
    vec3 rgb = Spark_Color;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
