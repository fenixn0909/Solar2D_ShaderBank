
--[[
    Original implementation for this bank. The inverse narrative beat
    from this bank's existing petrify effect: instead of flesh turning
    to stone, this starts from a desaturated stone-gray base (same
    "read as carved rock" luminance treatment as kernelF_FX_stone) and,
    as Progress rises, grows a glowing Voronoi crack network (F2-F1
    ridge, 3x3 constant-bound cell search - same GLES2-safe technique
    family as this bank's crackOverlay/frostbite) outward from hashed
    seed points, pulsing with energy color and letting a little of the
    original color bleed back through the brightest, most-grown cracks
    - a statue breaking open from within, not a person calcifying.

    Checked against all existing kernels first: kernelF_FX_stone (batch
    3) runs the *opposite* direction (Progress 0 -> 1 goes flesh to
    statue, no cracks, no glow, no growth network); kernelF_FX_
    crackOverlay grows cracks that render "near-black with an ember
    Glow band" as damage on top of the sprite's own existing colors -
    it never starts from a fully-desaturated stone base or lets color
    bleed back through as cracks widen. This is the only kernel
    combining a stone base with an awakening glow-crack reveal.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "statueAwakenCrackGlow"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Scale','Crack_Width','Stone_Tint',
            'Energy_R','Energy_G','Energy_B','Pulse_Speed',
            'Color_Restore','Seed','Opacity','',
            '','','','',
        },
        default = {
            0,12,.05,.35,
            1,.7,.25,3,
            .3,0,1,0,
            0,0,0,0,
        },
        min = {
            0,4,.01,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,26,.15,1,
            1,1,1,8,
            .6,50,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress       = u_UserData0[0][0];
float Scale          = u_UserData0[0][1];
float Crack_Width    = u_UserData0[0][2];
float Stone_Tint     = u_UserData0[0][3];
vec3  Energy_Color   = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Pulse_Speed    = u_UserData0[1][3];
float Color_Restore  = u_UserData0[2][0];
float Seed           = u_UserData0[2][1];
float Opacity        = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float awaken_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 51.7, 23.9 ) ) ) * 43758.5453123 );
}

float awaken_voronoi( vec2 p )
{
    vec2 base = floor( p );
    float f1 = 8.0;
    float f2 = 8.0;

    for ( int oy = -1; oy <= 1; oy++ )
    {
        for ( int ox = -1; ox <= 1; ox++ )
        {
            vec2 cell = base + vec2( float( ox ), float( oy ) ) + Seed;
            vec2 pt = cell + vec2( awaken_hash( cell ), awaken_hash( cell + 31.0 ) );
            float d = length( p - pt );
            if ( d < f1 ) { f2 = f1; f1 = d; }
            else if ( d < f2 ) { f2 = d; }
        }
    }
    return f2 - f1;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 stoneBase = mix( vec3( lum ), tex.rgb, 0.12 ) * mix( 1.0, 0.75, Stone_Tint );

    float crackDist = awaken_voronoi( UV * Scale );
    float crackLine = smoothstep( Crack_Width, 0.0, crackDist );
    float crackActive = step( crackDist, Progress * 0.45 );

    float pulse = 0.6 + 0.4 * sin( CoronaTotalTime * Pulse_Speed + crackDist * 20.0 );
    vec3 glow = Energy_Color * crackLine * crackActive * pulse;

    vec3 finalRGB = stoneBase + glow;
    finalRGB = mix( finalRGB, tex.rgb, crackActive * Progress * Color_Restore );
    finalRGB = mix( tex.rgb, clamp( finalRGB, 0.0, 1.0 ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
