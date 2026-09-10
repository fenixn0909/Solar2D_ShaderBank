
--[[
    Original implementation for this bank. A one-shot radial burst driven
    by a single Progress uniform (0 = not yet triggered, 1 = fully
    dispersed - animate it with a transition.to on Progress from your own
    Lua code, same pattern as this batch's kernelG_FX_geyserErupt.lua uses
    internally via time instead). Each shard is a compile-time-bounded
    ("active" step-gated, same trick as kernelG_UI_radarSweep.lua) wedge
    built from three half-plane tests in a rotated local frame rather than
    a texture, so the jagged triangular silhouette costs nothing beyond a
    couple of `step` calls, and a slow per-shard tumble rotation is layered
    on top of its outward radial travel.

    Pure generator, transparent background - a shatter/crit-hit/ice-spell
    impact burst. Aspect_Ratio convention matches the rest of this bank
    (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "iceShardBurst"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Shard_Count','Speed','Travel',
            'Shard_Size','Color_R','Color_G','Color_B',
            'Aspect_Ratio','','','',
            '','','','',
        },
        default = {
            .4,8,1,.4,
            .05,.7,.9,1,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.2,.1,
            .01,0,0,0,
            .2,0,0,0,
            0,0,0,0,
        },
        max = {
            1,10,3,.8,
            .15,1,1,1,
            5,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress     = u_UserData0[0][0];
float Shard_Count  = u_UserData0[0][1];
float Speed        = u_UserData0[0][2];
float Travel       = u_UserData0[0][3];
float Shard_Size   = u_UserData0[1][0];
vec3  Color        = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Aspect_Ratio = u_UserData0[2][0];

const int SHARD_MAX = 10;
const float TAU = 6.28318530718;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float total = 0.0;

    for ( int shardIndex = 0; shardIndex < SHARD_MAX; shardIndex++ ) {
        float active = step( float( shardIndex ) + 0.5, Shard_Count );
        float fi = float( shardIndex );

        float shardAngle = ( fi / max( Shard_Count, 1.0 ) ) * TAU + hash1( fi * 3.1 ) * 0.5;
        float shardSpeed = ( 0.6 + hash1( fi * 5.5 ) * 0.8 ) * Speed;
        float shardDist = Progress * shardSpeed * Travel;
        float shardStartRad = hash1( fi * 7.7 ) * 0.05;

        vec2 center = vec2( cos( shardAngle ), sin( shardAngle ) ) * ( shardStartRad + shardDist );

        vec2 toShard = uv - center;
        float tumble = shardAngle + Progress * hash1( fi * 9.9 ) * 2.0;
        float cs = cos( -tumble );
        float sn = sin( -tumble );
        vec2 localP = vec2( toShard.x * cs - toShard.y * sn, toShard.x * sn + toShard.y * cs );

        float size = Shard_Size * ( 0.6 + 0.6 * hash1( fi * 2.2 ) );
        float wedge = step( abs( localP.y ), size * 0.4 - localP.x * 0.5 )
                    * step( localP.x, size )
                    * step( -size * 0.3, localP.x );

        float fadeOut = 1.0 - smoothstep( 0.6, 1.0, Progress );

        total += active * wedge * fadeOut;
    }

    total = clamp( total, 0.0, 1.0 );
    vec3 rgb = mix( Color, vec3( 1.0 ), 0.5 ) * total;

    P_COLOR vec4 COLOR = vec4( rgb, total );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
