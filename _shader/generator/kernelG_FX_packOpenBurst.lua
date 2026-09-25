
--[[
    Original implementation for this bank. A one-shot "reward reveal"
    burst for pack/chest/loot-opening moments: an expanding thin ring,
    twelve radiating light rays that shoot out and fade, and a handful
    of hashed sparkle points that pop and twinkle - all keyed off
    Progress (0 = trigger instant, 1 = fully settled), not
    CoronaTotalTime, so it plays once per Lua-driven tween rather than
    looping.

    Checked against all existing kernels first: kernelG_FX_starburst
    and kernelG_FX_radiantHalo are steady, continuously-glowing looks
    with no trigger/decay envelope - they don't "happen" at a moment,
    they just are; kernelG_FX_confetti keeps falling continuously
    rather than expanding-and-settling once. This is the only kernel
    here built specifically as a triggered, self-completing reveal
    moment rather than an ambient loop.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "packOpenBurst"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Center_X','Center_Y','Max_Radius',
            'Ring_Width','Color_R','Color_G','Color_B',
            'Sparkle_Amount','Seed','Aspect_Ratio','',
            '','','','',
        },
        default = {
            0,.5,.5,.55,
            .012,1,.9,.5,
            .6,0,1,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.1,
            .003,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            .05,1,1,1,
            1.5,50,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress       = u_UserData0[0][0];
vec2  Center         = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Max_Radius     = u_UserData0[0][3];
float Ring_Width     = u_UserData0[1][0];
vec3  Burst_Color    = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Sparkle_Amount = u_UserData0[2][0];
float Seed           = u_UserData0[2][1];
float Aspect_Ratio   = u_UserData0[2][2];

const float PI = 3.14159265;
const float TAU = 6.28318530718;

//----------------------------------------------

P_RANDOM float pack_hash( float n )
{
    return fract( sin( n * 61.7 ) * 34689.234 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 d = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( d );
    float ang = atan( d.y, d.x );

    float ringR = Max_Radius * smoothstep( 0.0, 0.6, Progress );
    float ring = smoothstep( Ring_Width, 0.0, abs( dist - ringR ) ) * ( 1.0 - smoothstep( 0.5, 1.0, Progress ) );

    float rayReach = Max_Radius * 1.3 * smoothstep( 0.0, 0.35, Progress );
    float rayFade = 1.0 - smoothstep( 0.15, 0.8, Progress );
    float rays = 0.0;
    for ( int i = 0; i < 12; i++ )
    {
        float a = float( i ) / 12.0 * TAU;
        float angDiff = abs( mod( ang - a + PI, TAU ) - PI );
        float rayMask = smoothstep( 0.12, 0.0, angDiff * dist ) * step( dist, rayReach );
        rays = max( rays, rayMask );
    }
    rays *= rayFade;

    float sparkle = 0.0;
    for ( int i = 0; i < 8; i++ )
    {
        float fi = float( i );
        float sAng = pack_hash( fi + Seed ) * TAU;
        float sDist = Max_Radius * ( 0.3 + 0.7 * pack_hash( fi + Seed + 5.0 ) );
        vec2 sPos = vec2( cos( sAng ), sin( sAng ) ) * sDist * smoothstep( 0.0, 0.5, Progress );
        float startT = pack_hash( fi + Seed + 9.0 ) * 0.4;
        float twinkle = smoothstep( startT, startT + 0.1, Progress ) * ( 1.0 - smoothstep( startT + 0.2, 1.0, Progress ) );
        float sd = length( d - sPos );
        sparkle = max( sparkle, exp( -( sd * sd ) / 0.0008 ) * twinkle );
    }
    sparkle *= Sparkle_Amount;

    float alpha = clamp( ring + rays + sparkle, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( Burst_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
