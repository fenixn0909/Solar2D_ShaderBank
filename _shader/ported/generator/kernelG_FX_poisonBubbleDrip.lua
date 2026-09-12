
--[[
    Original implementation for this bank. An RPG poison/toxin status
    aura: small bubbles rise from Origin on individually-hashed loops,
    wobbling side to side as they climb, then popping into a brief
    3-droplet splash near the top of their life rather than just
    fading out. Count masks off unused slots the same way this
    batch's earlier kernelG_FX_stunStarsOrbit and batch-6's
    butterflyDrift do, so it scales from a single bubble up to a small
    cluster.

    Checked against all existing kernels first: kernelG_BG_bubbles is
    an ambient full-background floating-bubble field with no
    attachment point and no pop event; kernelG_FX_geyserErupt is a
    cyclic eruption column (a burst-then-empty cycle, not continuous
    small rising bubbles); kernelG_FX_emberDrift rises embers/ash, a
    different particle entirely with no wobble-then-pop life cycle.
    None are a point-anchored status-effect bubble drip.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "poisonBubbleDrip"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Rise_Speed','Bubble_Size',
            'Color_R','Color_G','Color_B','Wobble',
            'Count','Seed','Aspect_Ratio','',
            '','','','',
        },
        default = {
            .5,.9,.18,.02,
            .45,.85,.2,.03,
            5,0,1,0,
            0,0,0,0,
        },
        min = {
            0,0,.03,.005,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,.5,5,
            1,1,1,.1,
            50,50,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Origin        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Rise_Speed    = u_UserData0[0][2];
float Bubble_Size   = u_UserData0[0][3];
vec3  Bubble_Color  = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Wobble        = u_UserData0[1][3];
float Count         = u_UserData0[2][0];
float Seed          = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float poison_hash( float n )
{
    return fract( sin( n * 67.9 ) * 51839.234 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 rel = ( UV - Origin ) * vec2( 1.0, Aspect_Ratio );

    float glow = 0.0;

    for ( int i = 0; i < 50; i++ )
    {
        float fi = float( i );
        float active = step( fi + 0.5, Count );
        float h1 = poison_hash( fi + Seed );
        float h2 = poison_hash( fi + Seed + 11.0 );
        float h3 = poison_hash( fi + Seed + 23.0 );

        float life = fract( CoronaTotalTime * Rise_Speed * ( 0.7 + 0.5 * h1 ) + h1 );
        float wob = sin( life * 20.0 + h2 * 10.0 ) * Wobble * life;
        vec2 pos = vec2( ( h2 - 0.5 ) * 0.15 + wob, -life * 0.55 );

        float d = length( rel - pos );
        float size = Bubble_Size * ( 0.6 + 0.6 * h3 );

        float bubble = smoothstep( size, size * 0.6, d ) - smoothstep( size * 0.6, size * 0.3, d ) * 0.5;
        float bubbleAlive = 1.0 - smoothstep( 0.82, 0.9, life );

        float popT = clamp( ( life - 0.82 ) / 0.12, 0.0, 1.0 );
        float pop = 0.0;
        for ( int k = 0; k < 3; k++ )
        {
            float fk = float( k );
            float pa = fk / 3.0 * 6.2832 + h3 * 10.0;
            vec2 ppos = pos + vec2( cos( pa ), sin( pa ) ) * popT * size * 3.0;
            float pd = length( rel - ppos );
            pop = max( pop, exp( -( pd * pd ) / max( size * size * 0.2, 0.00001 ) ) * ( 1.0 - popT ) );
        }

        glow = max( glow, ( bubble * bubbleAlive + pop * step( 0.82, life ) ) * active );
    }

    P_COLOR vec4 COLOR = vec4( Bubble_Color, clamp( glow, 0.0, 1.0 ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
