
--[[
    Original implementation for this bank. Modeled on the "force
    field" sprite-bubble category that's a consistent top seller for
    Unity 2D shield VFX (FORGE3D's Force Field, Force Field Pro, the
    2DFX suite's Force Field: a translucent energy bubble hugging the
    sprite with a bright fresnel-like rim, scrolling scan bands and a
    breathing pulse) - nothing was copied from any of them (all paid,
    closed-source); this reimplements the same feature list as a plain
    fragment kernel: a 4-tap alpha-gradient rim (same CoronaTexelSize
    trick as this bank's outlineUniversal) that is strictly edge-only -
    zero inside the solid sprite and zero out in the empty background,
    so it never washes the backdrop - upward-scrolling scanlines
    masked by the sprite's own alpha, a procedural shimmer, and a
    sine pulse driving rim + fill together.

    NOTE: like any rim/outline effect, the halo can only draw where
    transparent pixels already exist - leave a few px of padding
    around the art or it clips at the texture edge (same caveat as
    outlineUniversal).

    Checked against all existing kernels first: plasmaShield is a
    full-screen procedural generator background, qiAura is a soft aura
    composite - neither is a sprite-hugging animated bubble filter.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "forceField"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Rim_Width','Scan_Freq','Scan_Speed','Pulse_Speed',
            'Shield_R','Shield_G','Shield_B','Opacity',
            'Rim_Boost','Scan_Amount','Shimmer','Pulse_Amount',
            '','','','',
        },
        default = {
            3,28,1.6,2.2,
            .25,.75,1,.85,
            1.8,.5,.35,.6,
            0,0,0,0,
        },
        min = {
            0,2,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            16,80,6,6,
            2,2,2,1,
            4,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Rim_Width    = u_UserData0[0][0];
float Scan_Freq    = u_UserData0[0][1];
float Scan_Speed   = u_UserData0[0][2];
float Pulse_Speed  = u_UserData0[0][3];
vec3  Shield_Color = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Opacity      = u_UserData0[1][3];
float Rim_Boost    = u_UserData0[2][0];
float Scan_Amount  = u_UserData0[2][1];
float Shimmer      = u_UserData0[2][2];
float Pulse_Amount = u_UserData0[2][3];

const float TAU = 6.28318530718;

//----------------------------------------------

P_RANDOM float field_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float field_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( field_hash( i ), field_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( field_hash( i + vec2( 0.0, 1.0 ) ), field_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 stepUV = max( Rim_Width, 0.0 ) * CoronaTexelSize.xy;
    float aL = texture2D( CoronaSampler0, clamp( UV - vec2( stepUV.x, 0.0 ), 0.0, 1.0 ) ).a;
    float aR = texture2D( CoronaSampler0, clamp( UV + vec2( stepUV.x, 0.0 ), 0.0, 1.0 ) ).a;
    float aD = texture2D( CoronaSampler0, clamp( UV - vec2( 0.0, stepUV.y ), 0.0, 1.0 ) ).a;
    float aU = texture2D( CoronaSampler0, clamp( UV + vec2( 0.0, stepUV.y ), 0.0, 1.0 ) ).a;
    // Edge-only rim: straddles the silhouette, exactly 0 in flat areas
    // (solid interior AND empty background) so the backdrop is untouched.
    float neighborAvg = ( aL + aR + aD + aU ) * 0.25;
    float rim = clamp( abs( neighborAvg - tex.a ) * 3.0, 0.0, 1.0 );
    rim *= step( 0.001, Rim_Width );

    float scans = 0.5 + 0.5 * sin( UV.y * Scan_Freq + CoronaTotalTime * Scan_Speed * TAU * 0.25 );
    float shimmer = field_noise( vec2( UV.x * 9.0, UV.y * 9.0 - CoronaTotalTime * Scan_Speed * 0.7 ) ) - 0.5;

    float pulse = 1.0 - Pulse_Amount * ( 0.5 + 0.5 * sin( CoronaTotalTime * Pulse_Speed * TAU * 0.25 ) );

    float fill = tex.a * ( scans * Scan_Amount + shimmer * Shimmer );
    float shield = clamp( rim * Rim_Boost + fill, 0.0, 1.5 ) * pulse;

    vec3 finalRGB = mix( tex.rgb, Shield_Color, clamp( shield, 0.0, 1.0 ) * Opacity );
    float finalAlpha = max( tex.a, rim * pulse * Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
