
--[[
    Original implementation for this bank. Modeled on the "corruption /
    void" character-transform category from commercial character
    shader bundles - nothing was copied from any of them (all paid,
    closed-source). Builds on a standard noise-threshold dissolve (the
    same base mechanic as this bank's dissolve family) but adds a
    second, higher-frequency noise layer sampled with a slow downward
    drift right at the dissolve boundary, masked to a thin band there -
    that band reads as wispy tendrils curling and drifting away from
    the disappearing edge rather than the boundary just fading, and
    everything is tinted toward a dark violet void rather than the
    warm ash/ember palette this bank's other dissolves use.

    Checked against all existing kernels first: kernelF_FX_dissolve/
    dissolveMistOG/dissolveNoise3D and kernelF_FX_turnToDust all key off
    a single noise threshold with a warm ember/dust edge treatment and
    no second drifting-wisp layer; kernelG_FX_voidRiftTear (per its own
    header, a batch-4 kernel) is a standalone generator - a tear/rift
    shape drawn from nothing, not a dissolve applied to a sprite's own
    silhouette. This bank's own kernelG_FX_curseAuraWisp (batch 7) is a
    continuously-looping ambient aura with no Progress-driven dissolve
    of the sprite itself. None combine a violet-tinted dissolve with a
    drifting wisp band at the boundary.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "voidCorruptionDissolve"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Scale','Void_R','Void_G',
            'Void_B','Rim_R','Rim_G','Rim_B',
            'Wisp_Speed','Wisp_Amount','Seed','Opacity',
            '','','','',
        },
        default = {
            0,22,.08,.03,
            .12,.55,.15,.85,
            .5,.6,0,1,
            0,0,0,0,
        },
        min = {
            0,6,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,45,1,1,
            1,1,1,1,
            2,1.5,50,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress    = u_UserData0[0][0];
float Scale       = u_UserData0[0][1];
vec3  Void_Color  = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
vec3  Rim_Color   = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Wisp_Speed  = u_UserData0[2][0];
float Wisp_Amount = u_UserData0[2][1];
float Seed        = u_UserData0[2][2];
float Opacity     = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float void_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 33.9, 78.1 ) ) ) * 43758.5453123 );
}

P_RANDOM float void_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( void_hash( i ), void_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( void_hash( i + vec2( 0.0, 1.0 ) ), void_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float n = void_noise( UV * Scale + Seed );
    float dissolveMask = step( Progress, n );

    float rimBand = smoothstep( 0.1, 0.0, abs( n - Progress ) );
    vec3 rimGlow = Rim_Color * rimBand;

    vec2 wispUV = UV * Scale * 2.5 + vec2( 0.0, -CoronaTotalTime * Wisp_Speed );
    float wispNoise = void_noise( wispUV );
    float wispBand = smoothstep( 0.22, 0.0, abs( n - Progress - 0.04 ) ) * wispNoise * Wisp_Amount;

    vec3 baseRGB = tex.rgb * dissolveMask + rimGlow;
    vec3 finalRGB = clamp( baseRGB + Void_Color * wispBand, 0.0, 1.0 );
    float finalAlpha = clamp( tex.a * dissolveMask + wispBand * 0.6 + rimBand * tex.a, 0.0, 1.0 );

    finalRGB = mix( tex.rgb, finalRGB, Opacity );
    finalAlpha = mix( tex.a, finalAlpha, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
