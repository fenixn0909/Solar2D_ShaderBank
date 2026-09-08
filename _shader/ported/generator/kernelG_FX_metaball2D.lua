
--[[
    Original implementation for this bank. Metaballs are a well-documented
    generic technique (field summation + threshold - see e.g. HuvaaKoodia's
    "2DMetaballs" and Bronson Zgeb's "Particle Metaballs in Unity using URP
    and Shader Graph" series, both popular reference implementations of the
    same underlying math), not owned by any single source, so this is a
    fresh implementation rather than a port of any of them: up to 6 blobs
    (compile-time constant loop bound, required for broad GLSL ES 1.00
    compatibility - same reason kernelF_FX_outlineUniversal.lua and
    kernelC_FX_stylizedWaterV2.lua in this bank use fixed-size loops
    instead of uniform-driven ones), each with an inverse-square falloff
    field, summed and thresholded with a smoothstep edge. Blob_Count lets
    you dial back how many of the 6 are actually active without changing
    the loop bound itself (each iteration's contribution is zeroed via a
    step() test instead of branching out of the loop).

    Every blob's orbit/phase/radius is procedurally seeded from its own
    index (hash-based), so this drops in and self-animates with zero
    external control - nudge Seed to reshuffle the arrangement. Good for
    slime/goo enemies, magic orb charge-ups, lava-lamp UI backdrops, or
    an ability-ready pulse. Aspect_Ratio convention matches the rest of
    this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "metaball2D"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Blob_Count','Blob_Radius','Speed','Threshold',
            'Edge_Softness','Rim_Width','Color_R','Color_G',
            'Color_B','Rim_Color_R','Rim_Color_G','Rim_Color_B',
            'Wander','Aspect_Ratio','Seed','',
        },
        default = {
            5,.11,.5,1,
            .12,.22,.85,.25,
            .65,1,.85,.95,
            .32,1,0,0,
        },
        min = {
            0,.02,-2,.2,
            .01,0,0,0,
            0,0,0,0,
            0,.2,0,0,
        },
        max = {
            6,.3,2,3,
            .6,.6,1,1,
            1,1,1,1,
            .6,5,50,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Blob_Count    = u_UserData0[0][0];
float Blob_Radius   = u_UserData0[0][1];
float Speed         = u_UserData0[0][2];
float Threshold     = u_UserData0[0][3];
float Edge_Softness = u_UserData0[1][0];
float Rim_Width     = u_UserData0[1][1];
vec3  Color         = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
vec3  Rim_Color     = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float Wander        = u_UserData0[3][0];
float Aspect_Ratio  = u_UserData0[3][1];
float Seed          = u_UserData0[3][2];

const int BLOB_MAX = 6;
const float TAU = 6.28318530718;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}
P_RANDOM vec2 hash2( float seedVal )
{
    return vec2( hash1( seedVal ), hash1( seedVal + 17.13 ) );
}

P_DEFAULT float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.y /= Aspect_Ratio;

    float field = 0.0;

    for ( int blobIndex = 0; blobIndex < BLOB_MAX; blobIndex++ ) {
        float fi = float( blobIndex ) + Seed * 7.0;
        float active = step( float( blobIndex ) + 0.5, Blob_Count );

        vec2 seedVec = hash2( fi * 3.17 + 11.0 );
        float angle = seedVec.x * TAU + TIME * Speed * ( 0.5 + seedVec.y * 0.7 );
        float orbit = Wander * ( 0.4 + 0.6 * hash1( fi * 7.31 ) );

        vec2 center = vec2( cos( angle ), sin( angle ) * 0.8 ) * orbit;
        center += 0.18 * Wander * vec2(
            sin( TIME * Speed * 1.7 + fi * 5.0 ),
            cos( TIME * Speed * 1.3 + fi * 2.0 )
        );

        float blobR = Blob_Radius * ( 0.7 + 0.6 * hash1( fi * 2.03 ) );
        float d2 = dot( uv - center, uv - center );

        field += active * ( blobR * blobR ) / max( d2, 0.0001 );
    }

    float edge = max( Edge_Softness, 0.0001 );
    float mask = smoothstep( Threshold - edge, Threshold + edge, field );
    float rimHi = mask;
    float rimLo = smoothstep( Threshold + Rim_Width - edge, Threshold + Rim_Width + edge, field );
    float rim = clamp( rimHi - rimLo, 0.0, 1.0 );

    vec3 rgb = Color * mask + Rim_Color * rim;

    P_COLOR vec4 COLOR = vec4( rgb, mask );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
