
--[[
    Original implementation for this bank. A continuous spray of hot
    sparks launching from a fixed contact point within a cone
    (Spread_Angle around Aim_Angle), each on its own looping lifetime
    with a hashed launch speed/angle and a simple parabolic gravity
    arc, fading out near end of life. Reads as a grinding/drifting
    contact-point spark shower (car drifting, metal-on-metal grinding,
    sword scraping stone) rather than an ambient environmental effect.

    Checked against all existing kernels first: kernelG_FX_meteorShower
    streaks fall from off-screen at the top with tapered tails (no
    launch point, no gravity arc, not cone-constrained);
    kernelG_BG_starFall is a background-wide falling-star field, not a
    point-source emitter. Nothing else in the bank emits a gravity-
    arced particle cone from a fixed contact point.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "driftSparkShower"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Aim_Angle','Spread_Angle',
            'Speed','Gravity','Spark_Life','Color_R',
            'Color_G','Color_B','Size','Seed',
            'Aspect_Ratio','Emit_Rate','','',
        },
        default = {
            .5,.5,0,.7,
            .5,1.2,.6,1,
            .7,.25,.012,0,
            1,1,0,0,
        },
        min = {
            0,0,0,.05,
            .05,0,.1,0,
            0,0,.003,0,
            .2,.1,0,0,
        },
        max = {
            1,1,6.28318,3.14159,
            2,4,2,1,
            1,1,.03,50,
            5,5,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Origin        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Aim_Angle     = u_UserData0[0][2];
float Spread_Angle  = u_UserData0[0][3];
float Speed         = u_UserData0[1][0];
float Gravity       = u_UserData0[1][1];
float Spark_Life    = u_UserData0[1][2];
vec3  Spark_Color   = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Size          = u_UserData0[2][2];
float Seed          = u_UserData0[2][3];
float Aspect_Ratio  = u_UserData0[3][0];
float Emit_Rate     = u_UserData0[3][1]; // life-cycle speed: higher = faster emission

//----------------------------------------------

P_RANDOM float drift_hash( float n )
{
    return fract( sin( n * 78.233 ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 rel = ( UV - Origin ) * vec2( 1.0, Aspect_Ratio );

    float glow = 0.0;
    for ( int i = 0; i < 10; i++ )
    {
        float fi = float( i );
        float h1 = drift_hash( fi + Seed );
        float h2 = drift_hash( fi + Seed + 13.7 );
        float h3 = drift_hash( fi + Seed + 29.1 );

        float life = fract( ( CoronaTotalTime * Emit_Rate / max( Spark_Life, 0.05 ) ) * ( 0.8 + 0.4 * h3 ) + h1 );
        float launchAngle = Aim_Angle + ( h2 - 0.5 ) * Spread_Angle;
        vec2 dir = vec2( cos( launchAngle ), sin( launchAngle ) );
        float spd = Speed * ( 0.5 + 0.8 * h1 );

        vec2 pos = dir * spd * life;
        pos.y += 0.5 * Gravity * life * life;

        float d = length( rel - pos );
        float sparkSize = Size * ( 1.0 - life * 0.6 );
        float fade = 1.0 - smoothstep( 0.6, 1.0, life );
        float spark = exp( -( d * d ) / max( sparkSize * sparkSize, 0.00001 ) ) * fade;

        glow = max( glow, spark );
    }

    P_COLOR vec4 COLOR = vec4( Spark_Color, clamp( glow, 0.0, 1.0 ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
