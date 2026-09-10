
--[[
    Original implementation for this bank. Multi-point star-glint sparkle
    (a handful of small 4-spike flares scattered inside a disc, each
    twinkling on its own cycle) is the standard cheap stand-in real-time
    games use for "gem/diamond catching the light" wherever a full
    raytraced internal refraction would be overkill - implemented here as
    a compile-time-bounded loop (same GLES-safety reasoning as the other
    loop-based kernels in this batch) of independently hash-seeded glints,
    each a `cos`-based 4-point star SDF, plus a soft overall glow so the
    gem doesn't look completely dark between twinkles.

    Distinct from this batch's other point-light-ish effects: unlike
    kernelG_FX_radiantHalo.lua (one ring + radial spokes) this scatters
    several independent small sparkle points, and unlike
    kernelG_FX_magicRuneCircle.lua there are no rings/segments at all -
    just glints. Pure generator, transparent background - good as a loot-
    icon backdrop, a diamond/jewel prop, or an "item found" pickup glow.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "gemSparkle"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Sparkle_Count','Radius','Sparkle_Size','Spike_Sharpness',
            'Twinkle_Speed','Rotation_Speed','Color_R','Color_G',
            'Color_B','Brightness','Base_Glow','Seed',
            'Aspect_Ratio','','','',
        },
        default = {
            4,.35,.05,8,
            1.2,.5,.6,.85,
            1,1.3,.35,1,
            1,0,0,0,
        },
        min = {
            0,.05,.01,1,
            0,-3,0,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            6,.6,.2,20,
            5,3,1,1,
            1,3,1,50,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Sparkle_Count  = u_UserData0[0][0];
float Radius         = u_UserData0[0][1];
float Sparkle_Size   = u_UserData0[0][2];
float Spike_Sharpness= u_UserData0[0][3];
float Twinkle_Speed  = u_UserData0[1][0];
float Rotation_Speed = u_UserData0[1][1];
vec3  Color          = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Brightness     = u_UserData0[2][1];
float Base_Glow      = u_UserData0[2][2];
float Seed           = u_UserData0[2][3];
float Aspect_Ratio   = u_UserData0[3][0];

const int SPARKLE_MAX = 6;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

float starGlint( vec2 uv, vec2 center, float size, float spikePow, float angleOffset )
{
    vec2 d = uv - center;
    float dist = length( d );
    float ang = atan( d.y, d.x ) + angleOffset;

    float spike = pow( abs( cos( ang * 2.0 ) ), spikePow )
                + pow( abs( cos( ang * 2.0 + 1.5708 ) ), spikePow ) * 0.6;

    float radial = exp( -dist * dist * ( 3.0 / max( size, 0.01 ) ) );
    return radial * ( 0.3 + 0.7 * spike );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float total = 0.0;

    for ( int sparkleIndex = 0; sparkleIndex < SPARKLE_MAX; sparkleIndex++ ) {
        float active = step( float( sparkleIndex ) + 0.5, Sparkle_Count );
        float fi = float( sparkleIndex ) + Seed * 9.0;

        float rAngle = hash1( fi * 3.7 + 1.0 ) * 6.28318;
        float rRad = sqrt( hash1( fi * 5.1 + 7.0 ) ) * Radius * 0.85;
        vec2 center = vec2( cos( rAngle ), sin( rAngle ) ) * rRad;

        float phase = hash1( fi * 2.3 + 4.0 ) * 6.28318;
        float period = 1.0 + hash1( fi * 4.9 + 2.0 ) * 1.5;
        float twinkle = pow( 0.5 + 0.5 * sin( CoronaTotalTime * Twinkle_Speed * period + phase ), 3.0 );

        float angleOffset = CoronaTotalTime * Rotation_Speed * ( 0.5 + hash1( fi * 1.7 ) ) + phase;
        float size = Sparkle_Size * ( 0.7 + 0.6 * hash1( fi * 6.6 ) );

        total += active * twinkle * starGlint( uv, center, size, Spike_Sharpness, angleOffset );
    }

    float rad = length( uv );
    float baseGlow = exp( -rad * rad * ( 4.0 / max( Radius, 0.05 ) ) ) * Base_Glow;

    vec3 rgb = mix( Color, vec3( 1.0 ), 0.4 ) * total * Brightness + Color * baseGlow;
    float alpha = clamp( total * Brightness + baseGlow, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
