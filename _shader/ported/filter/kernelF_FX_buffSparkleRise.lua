
--[[
    Original implementation for this bank. An RPG buff status: reads
    the input sprite's own alpha channel to find its silhouette edge
    (same rim-sampling approach as kernelF_FX_forceField), then
    scatters small twinkling motes that rise up along that edge and
    loop, rather than drawing a fixed shape - it works on a bar, a
    portrait, or a full character sprite equally since it only ever
    references CoronaSampler0's own alpha.

    Checked against all existing kernels first: kernelF_FX_forceField
    also reads sprite alpha for its rim, but renders a *steady* energy-
    bubble dome (scrolling scanlines, no rising motes, no per-mote
    twinkle-and-loop); kernelG_FX_gemSparkle twinkles fixed points on a
    standalone generated background, not sampling any input sprite's
    silhouette. Different content and different input dependency from
    both - this is the only kernel combining alpha-edge sampling with
    rising, looping sparkle motes.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "buffSparkleRise"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Rise_Speed','Density','Sparkle_Size','Rim_Width',
            'Color_R','Color_G','Color_B','Twinkle_Speed',
            'Opacity','Seed','','',
            '','','','',
        },
        default = {
            .3,10,.02,.03,
            1,.9,.45,4,
            .9,0,0,0,
            0,0,0,0,
        },
        min = {
            0,2,.005,.005,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,24,.05,.1,
            1,1,1,10,
            1,50,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Rise_Speed    = u_UserData0[0][0];
float Density       = u_UserData0[0][1];
float Sparkle_Size  = u_UserData0[0][2];
float Rim_Width     = u_UserData0[0][3];
vec3  Sparkle_Color = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Twinkle_Speed = u_UserData0[1][3];
float Opacity       = u_UserData0[2][0];
float Seed          = u_UserData0[2][1];

//----------------------------------------------

P_RANDOM float bsr_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 61.1, 24.7 ) ) ) * 33217.913 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    vec2 texel = CoronaTexelSize.xy * 2.0;

    float aC = tex.a;
    float aL = texture2D( CoronaSampler0, UV - vec2( texel.x, 0.0 ) ).a;
    float aR = texture2D( CoronaSampler0, UV + vec2( texel.x, 0.0 ) ).a;
    float aD = texture2D( CoronaSampler0, UV - vec2( 0.0, texel.y ) ).a;
    float aU = texture2D( CoronaSampler0, UV + vec2( 0.0, texel.y ) ).a;
    float edge = clamp( ( abs( aC - aL ) + abs( aC - aR ) + abs( aC - aD ) + abs( aC - aU ) ), 0.0, 1.0 );
    float rim = smoothstep( 0.0, Rim_Width, edge ) * step( 0.02, aC );

    float sparkle = 0.0;
    for ( int i = 0; i < 12; i++ )
    {
        float fi = float( i );
        float active = step( fi + 0.5, Density );
        float h1 = bsr_hash( vec2( fi, Seed ) );
        float h2 = bsr_hash( vec2( fi, Seed + 31.0 ) );
        float h3 = bsr_hash( vec2( fi, Seed + 67.0 ) );

        float life = fract( CoronaTotalTime * Rise_Speed * ( 0.6 + 0.6 * h1 ) + h1 );
        vec2 pos = vec2( h2, fract( h3 - life ) );

        float d = length( UV - pos );
        float twinkle = 0.5 + 0.5 * sin( CoronaTotalTime * Twinkle_Speed + h1 * 20.0 );
        float fade = smoothstep( 0.0, 0.15, life ) * ( 1.0 - smoothstep( 0.7, 1.0, life ) );

        sparkle = max( sparkle, exp( -( d * d ) / max( Sparkle_Size * Sparkle_Size, 0.0001 ) ) * twinkle * fade * active );
    }
    sparkle *= step( 0.02, aC );

    vec3 finalRGB = mix( tex.rgb, Sparkle_Color, rim * 0.8 ) + Sparkle_Color * sparkle;
    float finalAlpha = clamp( tex.a + rim * 0.4 * Opacity + sparkle * Opacity, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( mix( tex.rgb, finalRGB, Opacity ), finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
