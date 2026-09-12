
--[[
    Original implementation for this bank. A directional spotlight
    cone (Origin, Aim_Angle, Spread, Length) with soft angular and
    distance falloff, plus small dust-mote points floating slowly and
    near-stationary inside the cone (barely drifting, low motion) so
    it reads as ambient suspended dust catching the beam rather than
    a stream of moving particles - the opposite motion character from
    this batch's kernelG_FX_frostBreathCone, which streaks particles
    fast along its cone axis. Same cone-shape math family, deliberately
    different content and motion inside it.

    Checked against all existing kernels first: kernelG_ray_holy fans
    multiple rays from a source at Spread/Falloff (a divine-light rig,
    no discrete dust motes, no single-cone spotlight framing);
    kernelC_FX_heatHazeShimmer only distorts UVs. Nothing else in the
    bank is a spotlight cone with suspended dust.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "flashlightDustCone"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Aim_Angle','Spread',
            'Length','Color_R','Color_G','Color_B',
            'Dust_Amount','Dust_Speed','Opacity','Aspect_Ratio',
            '','','','',
        },
        default = {
            .5,0,1.5708,.35,
            .8,1,.97,.85,
            .5,.05,.55,1,
            0,0,0,0,
        },
        min = {
            0,0,0,.05,
            .1,0,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            1,1,6.28318,1,
            1.5,1,1,1,
            1.5,.3,1,5,
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
vec3  Cone_Color    = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Dust_Amount   = u_UserData0[2][0];
float Dust_Speed    = u_UserData0[2][1];
float Opacity       = u_UserData0[2][2];
float Aspect_Ratio  = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float dust_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 44.7, 91.3 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 dir = vec2( cos( Aim_Angle ), sin( Aim_Angle ) );
    vec2 rel = ( UV - Origin ) * vec2( 1.0, Aspect_Ratio );

    float along = dot( rel, dir );
    vec2 side = vec2( -dir.y, dir.x );
    float across = dot( rel, side );

    float halfWidth = Spread * clamp( along / max( Length_, 0.0001 ), 0.0, 1.0 );
    float coneMask = smoothstep( halfWidth + 0.03, halfWidth - 0.05, abs( across ) ) * step( 0.0, along ) * smoothstep( Length_, Length_ * 0.6, along );

    float dust = 0.0;
    for ( int i = 0; i < 10; i++ )
    {
        float fi = float( i );
        float h1 = dust_hash( vec2( fi, 1.0 ) );
        float h2 = dust_hash( vec2( fi, 2.0 ) );
        float h3 = dust_hash( vec2( fi, 3.0 ) );

        float motePos = h1 * Length_;
        float moteAcross = ( h2 - 0.5 ) * 2.0 * Spread * clamp( motePos / max( Length_, 0.0001 ), 0.0, 1.0 );
        vec2 drift = vec2( sin( CoronaTotalTime * Dust_Speed + h3 * 20.0 ), cos( CoronaTotalTime * Dust_Speed * 0.7 + h3 * 15.0 ) ) * 0.02;

        vec2 motePosVec = dir * motePos + side * moteAcross + drift;
        float d = length( rel - motePosVec );
        float twinkle = 0.5 + 0.5 * sin( CoronaTotalTime * 2.0 + h3 * 30.0 );
        dust = max( dust, exp( -( d * d ) / 0.00004 ) * twinkle );
    }

    float alpha = clamp( coneMask * 0.5 + dust * Dust_Amount, 0.0, 1.0 ) * Opacity;

    P_COLOR vec4 COLOR = vec4( Cone_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
