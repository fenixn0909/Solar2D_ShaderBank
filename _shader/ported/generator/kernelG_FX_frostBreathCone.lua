
--[[
    Original implementation for this bank. A directional icy breath-
    attack cone (boss/monster ability) - same cone-shape math family as
    this batch's kernelG_FX_flashlightDustCone, but deliberately
    different content: fast elongated streaks racing outward along the
    cone axis (motion-stretched, not soft floating points) over a cold
    fogged gradient base, read as an expelled blast rather than ambient
    suspended dust.

    Checked against all existing kernels first: kernelG_FX_
    frozenBreathFog (batch 5) is explicitly a small looping *personal*
    breath puff with no direction/spread/attack framing - this is a
    directional, longer-range attack cone, a different use case and
    scale entirely; kernelF_FX_frostbite is a screen-space overlay
    (voronoi cracking + vignette), not an emitted directional cone.
    Not related to this bank's icicleDrip/iceShardBurst either (both
    are stationary ice-shape effects, not a moving breath blast).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "frostBreathCone"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Aim_Angle','Spread',
            'Length','Speed','Color_R','Color_G',
            'Color_B','Streak_Amount','Opacity','Aspect_Ratio',
            '','','','',
        },
        default = {
            .5,.5,0,.3,
            .6,2.2,.75,.92,
            1,.7,.8,1,
            0,0,0,0,
        },
        min = {
            0,0,0,.05,
            .1,.2,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            1,1,6.28318,1,
            1.2,6,1,1,
            1,1.5,1,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Origin        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Aim_Angle     = u_UserData0[0][2];
float Spread        = u_UserData0[0][3];
float Length_       = u_UserData0[1][0];
float Speed         = u_UserData0[1][1];
vec3  Frost_Color   = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Streak_Amount = u_UserData0[2][1];
float Opacity       = u_UserData0[2][2];
float Aspect_Ratio  = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float frostc_hash( float n )
{
    return fract( sin( n * 39.41 ) * 21983.6 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 dir = vec2( cos( Aim_Angle ), sin( Aim_Angle ) );
    vec2 side = vec2( -dir.y, dir.x );
    vec2 rel = ( UV - Origin ) * vec2( 1.0, Aspect_Ratio );

    float along = dot( rel, dir );
    float across = dot( rel, side );

    float halfWidth = Spread * clamp( along / max( Length_, 0.0001 ), 0.0, 1.0 );
    float coneMask = smoothstep( halfWidth + 0.03, halfWidth - 0.05, abs( across ) ) * step( 0.0, along ) * smoothstep( Length_, Length_ * 0.7, along );
    float fog = coneMask * ( 1.0 - clamp( along / max( Length_, 0.0001 ), 0.0, 1.0 ) * 0.5 );

    float streaks = 0.0;
    for ( int i = 0; i < 10; i++ )
    {
        float fi = float( i );
        float h1 = frostc_hash( fi + 1.0 );
        float h2 = frostc_hash( fi + 2.0 );

        float life = fract( CoronaTotalTime * Speed + h1 );
        float streakAlong = life * Length_;
        float streakAcross = ( h2 - 0.5 ) * 2.0 * Spread * clamp( streakAlong / max( Length_, 0.0001 ), 0.0, 1.0 );

        float dAlong = along - streakAlong;
        float dAcross = across - streakAcross;
        float streak = exp( -( dAcross * dAcross ) / 0.00025 ) * smoothstep( 0.05, -0.02, dAlong ) * smoothstep( -0.12, -0.04, dAlong );
        streaks = max( streaks, streak );
    }

    float alpha = clamp( fog * 0.45 + streaks * Streak_Amount, 0.0, 1.0 ) * Opacity;

    P_COLOR vec4 COLOR = vec4( Frost_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
