
--[[
    Original implementation for this bank. Combines two standard building
    blocks for a blowing sand/dust storm: a hashed-cell particle layer
    (same single-tap-per-layer approach as this batch's own
    kernelG_FX_emberDrift.lua, but with an anisotropic distance metric -
    `length(localUV * vec2(1, k))` for k > 1 - so each speck reads as a
    horizontal streak instead of a round dot) plus a slow two-octave value-
    noise haze drifting sideways to sell suspended dust dimming everything
    behind it.

    Pure generator, transparent background - overlay across a desert scene
    for ambient blowing sand, or crank Brightness/Haze_Amount up for a
    full sandstorm whiteout. Wind_Angle (radians, 0 = toward +x) steers
    both the streak scroll and the haze drift; streaks stay elongated
    along the wind. Aspect_Ratio convention matches the rest of
    this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "sandstormDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Wind_Speed','Density','Size','Threshold',
            'Haze_Scale','Haze_Amount','Brightness','Color_R',
            'Color_G','Color_B','Aspect_Ratio','Wind_Angle',
            '','','','',
        },
        default = {
            .5,5,1,.18,
            1.5,.35,.9,.75,
            .62,.4,1,0,
            0,0,0,0,
        },
        min = {
            -3,1,.2,0,
            .2,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            50,20,3,1,
            6,1,3,1,
            1,1,5,6.28318,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Wind_Speed   = u_UserData0[0][0];
float Density      = u_UserData0[0][1];
float Size         = u_UserData0[0][2];
float Threshold    = u_UserData0[0][3];
float Haze_Scale   = u_UserData0[1][0];
float Haze_Amount  = u_UserData0[1][1];
float Brightness   = u_UserData0[1][2];
vec3  Color        = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Aspect_Ratio = u_UserData0[2][2];
float Wind_Angle   = u_UserData0[2][3]; // radians: 0 = blows toward +x, PI/2 = toward +y

const int STREAK_LAYERS = 3;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

P_RANDOM float hash21( vec2 p )
{
    p = fract( p * vec2( 123.34, 456.21 ) );
    p += dot( p, p + 45.32 );
    return fract( p.x * p.y );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash21( i );
    float b = hash21( i + vec2( 1.0, 0.0 ) );
    float c = hash21( i + vec2( 0.0, 1.0 ) );
    float d = hash21( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( a, b, u.x ), mix( c, d, u.x ), u.y );
}

float streakLayer( vec2 uv, float layerIndex )
{
    float speed = Wind_Speed * ( 0.6 + layerIndex * 0.4 );
    float scale = Density * ( 1.0 + layerIndex * 0.3 );

    // Wind basis: streaks elongate along the wind, scroll with it.
    // Angle 0 reproduces the original horizontal drift exactly.
    vec2 windDir = vec2( cos( Wind_Angle ), sin( Wind_Angle ) );
    vec2 perpDir = vec2( -windDir.y, windDir.x );
    vec2 rel = uv - windDir * ( CoronaTotalTime * speed * 0.2 );
    vec2 scrolled = vec2( dot( rel, windDir ), dot( rel, perpDir ) ) * scale;
    vec2 cell = floor( scrolled );
    vec2 localUV = fract( scrolled ) - 0.5;

    float hA = hash1( dot( cell, vec2( 19.19, 61.7 ) ) + layerIndex * 41.0 );
    float hB = hash1( dot( cell, vec2( 71.3, 27.1 ) ) + layerIndex * 23.0 );

    float size = mix( 0.15, 0.45, hB ) * Size;
    float dist = length( localUV * vec2( 1.0, 3.5 ) );
    float streak = 1.0 - smoothstep( size * 0.5, size, dist );
    float visible = step( 1.0 - Threshold, hA );

    return streak * visible;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float streaks = 0.0;
    for ( int layerIndex = 0; layerIndex < STREAK_LAYERS; layerIndex++ ) {
        streaks += streakLayer( uv, float( layerIndex ) );
    }
    streaks = clamp( streaks, 0.0, 1.0 );

    vec2 windDir = vec2( cos( Wind_Angle ), sin( Wind_Angle ) );
    float haze = valueNoise( uv * Haze_Scale + windDir * ( CoronaTotalTime * Wind_Speed * 0.05 ) ) * 0.5
               + valueNoise( uv * Haze_Scale * 2.3 - windDir * ( CoronaTotalTime * Wind_Speed * 0.08 ) ) * 0.5;
    haze = clamp( haze, 0.0, 1.0 ) * Haze_Amount;

    vec3 rgb = Color * ( streaks * Brightness + haze * 0.5 );
    float alpha = clamp( streaks * Brightness + haze * 0.6, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
