
--[[
    Original implementation for this bank, not a port of any single file -
    "GLSL caustics" is a whole genre of near-identical ShaderToy/Unity/
    Godot snippets built on layered sine interference, with no single
    clear owner left to attribute (see e.g. the many Unity URP tutorials
    on the technique - Cyanilux's water shader breakdown, Alan Zucconi's
    caustics articles, ameye.dev's realtime caustics notes - all
    converging on the same family of approach: overlapping moving wave
    patterns, sharpened into thin bright veins). Rather than reproduce any
    one of those, this uses its own construction: per-octave plane waves
    built from dot(uv, rotatedDirection), each octave rotated/seeded by a
    hash of its own index rather than a fixed rotation, summed and then
    power-sharpened into veins.

    Pure generator - no input texture, so it drops straight into the
    generator/water tab next to kernelG_water_toonTorrent.lua and
    kernelG_water_windWalk2D.lua. Background_A defaults to 0 so it behaves
    as a transparent overlay you place on top of existing underwater
    art/gameplay (the real-world use case per every caustics tutorial
    above: project caustics onto whatever's already there, don't replace
    it) - raise Background_A if you want it to double as a standalone
    dark-water backdrop instead. Aspect_Ratio convention matches the rest
    of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "water"
kernel.name = "caustics2D"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed','Scale','Sharpness','Brightness',
            'Color_R','Color_G','Color_B','Background_R',
            'Background_G','Background_B','Background_A','Aspect_Ratio',
            '','','','',
        },
        default = {
            .4,3.5,3.5,1.8,
            .65,.95,1,0,
            0,0,0,1,
            0,0,0,0,
        },
        min = {
            -3,.5,1,0,
            0,0,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            3,12,10,4,
            1,1,1,1,
            1,1,1,5,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Speed         = u_UserData0[0][0];
float Scale         = u_UserData0[0][1];
float Sharpness     = u_UserData0[0][2];
float Brightness    = u_UserData0[0][3];
vec3  Color         = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Background    = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Background_A  = u_UserData0[2][2];
float Aspect_Ratio  = u_UserData0[2][3];

const int CAUSTIC_LAYERS = 3;
const float TAU = 6.28318530718;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.y /= Aspect_Ratio;

    float timeVal = CoronaTotalTime * Speed;
    float pattern = 0.0;
    float freq = Scale;
    float amp = 1.0;
    float ampSum = 0.0;

    for ( int layerIndex = 0; layerIndex < CAUSTIC_LAYERS; layerIndex++ ) {
        float fi = float( layerIndex );
        float angle = fi * 2.399963 + hash1( fi + 4.7 ) * TAU;
        vec2 dirA = vec2( cos( angle ), sin( angle ) );
        vec2 dirB = vec2( -dirA.y, dirA.x );

        float waveA = sin( dot( uv, dirA ) * freq + timeVal * ( 1.0 + fi * 0.35 ) );
        float waveB = sin( dot( uv, dirB ) * freq * 1.37 - timeVal * ( 0.8 + fi * 0.2 ) + fi * 1.9 );

        pattern += waveA * waveB * amp;
        ampSum += amp;
        freq *= 1.85;
        amp *= 0.55;
    }

    pattern /= max( ampSum, 0.0001 );
    float veins = pow( clamp( pattern * 0.5 + 0.5, 0.0, 1.0 ), Sharpness );
    float causticA = clamp( veins * Brightness, 0.0, 1.0 );

    vec3 straightRGB = Background + Color * veins * Brightness;
    float straightA = clamp( Background_A + causticA, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( straightRGB, straightA );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
