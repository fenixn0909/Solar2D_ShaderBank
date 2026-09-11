
--[[
    Original implementation for this bank. Up to six wandering
    butterflies, each rendered as a *pair* of soft glow blobs either
    side of a Lissajous-wander centerline, with the pair's separation
    oscillating (wing flutter) and a continuously-rotating cosine-
    palette hue per individual (iridescent wing shimmer) rather than a
    fixed color or a simple on/off flash. Count masks off unused
    slots so it scales from one stray butterfly up to a small flurry.

    Checked against all existing kernels first: kernelG_FX_fireflyDrift
    is described in this bank's own batch-5 notes as single soft point
    lights that flash on independent on/off cycles - no paired shape,
    no flutter, no hue rotation. kernelG_FX_spiritWisp (per batch-4's
    header) fakes a single trailing wisp with closed-form wander, also
    a single glow, not a two-blob flutter with color-shifting wings.
    kernelG_FX_sakuraPetals falls/tumbles rather than free-wandering,
    and uses flat petal color, not a hue cycle. This is the only one
    combining a two-part flutter silhouette with iridescent hue.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "butterflyDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Count','Speed','Wander_Amount','Size',
            'Flutter_Speed','Hue_Speed','Seed','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            4,.5,.3,.045,
            9,.15,0,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.01,
            2,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            6,2,.6,.1,
            25,.6,50,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Count         = u_UserData0[0][0];
float Speed         = u_UserData0[0][1];
float Wander_Amount = u_UserData0[0][2];
float Size          = u_UserData0[0][3];
float Flutter_Speed = u_UserData0[1][0];
float Hue_Speed     = u_UserData0[1][1];
float Seed          = u_UserData0[1][2];
float Opacity       = u_UserData0[1][3];

const float TAU = 6.28318530718;

//----------------------------------------------

P_RANDOM float bfly_hash( float n )
{
    return fract( sin( n * 127.1 ) * 43758.5453123 );
}

vec3 bfly_hue( float h )
{
    return 0.5 + 0.5 * cos( TAU * ( h + vec3( 0.0, 0.33, 0.67 ) ) );
}

vec4 bfly_one( vec2 uv, float seed )
{
    float t = CoronaTotalTime;
    float h0 = bfly_hash( seed );
    float h1 = bfly_hash( seed + 11.0 );
    float h2 = bfly_hash( seed + 23.0 );

    vec2 center = vec2( 0.5 ) + ( vec2( h0, h1 ) - 0.5 ) * 0.7;
    vec2 wander = Wander_Amount * vec2(
        sin( t * Speed * ( 0.7 + 0.6 * h0 ) + seed * 6.28 ),
        cos( t * Speed * ( 0.5 + 0.6 * h1 ) + seed * 4.0 ) );
    vec2 pos = center + wander;

    float flutter = 0.35 + 0.65 * abs( sin( t * Flutter_Speed + seed * 3.0 ) );
    float wingOffset = Size * ( 0.5 + 0.5 * flutter );

    vec2 dL = uv - ( pos - vec2( wingOffset, 0.0 ) );
    vec2 dR = uv - ( pos + vec2( wingOffset, 0.0 ) );
    float wingSize = Size * ( 0.55 + 0.35 * flutter );
    float glowL = exp( -dot( dL, dL ) / max( wingSize * wingSize, 0.0001 ) );
    float glowR = exp( -dot( dR, dR ) / max( wingSize * wingSize, 0.0001 ) );
    float glow = max( glowL, glowR ) * 0.65 + min( glowL, glowR ) * 0.35;

    float hue = fract( t * Hue_Speed + h2 );
    vec3 col = bfly_hue( hue );

    return vec4( col * glow, glow );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec3 rgb = vec3( 0.0 );
    float alpha = 0.0;

    for ( int i = 0; i < 6; i++ )
    {
        float active = step( float( i ) + 0.5, Count );
        vec4 b = bfly_one( UV, float( i ) * 17.0 + Seed );
        rgb += b.rgb * active;
        alpha = max( alpha, b.a * active );
    }

    P_COLOR vec4 COLOR = vec4( rgb, alpha * Opacity );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
