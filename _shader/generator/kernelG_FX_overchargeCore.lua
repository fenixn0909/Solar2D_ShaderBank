
--[[
    Original implementation for this bank. An "ability charging up" energy
    core - a bright center that grows and sprouts increasingly unstable
    corona spikes as a Charge value climbs toward 1 - is a staple of
    action-game special-attack windups; built here from a simple additive
    stack of angle-based sine harmonics (rather than a texture or particle
    system) so the corona's jitter scales continuously and cheaply with
    Charge instead of needing separate LOD/particle-count tuning at
    different charge levels.

    Charge is meant to be driven by your own gameplay timer each frame
    (0 = not charging, 1 = fully charged/ready to release) - this shader
    only renders the buildup state; trigger your own burst/explosion VFX
    separately when Charge reaches 1. Pure generator, transparent
    background. Aspect_Ratio convention matches the rest of this bank
    (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "overchargeCore"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Charge','Max_Core_Size','Corona_Reach','Jitter_Speed',
            'Brightness','Color_R','Color_G','Color_B',
            'Aspect_Ratio','','','',
            '','','','',
        },
        default = {
            .5,.22,2.2,6,
            1.3,.4,.7,1,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            0,.02,.5,0,
            0,0,0,0,
            .2,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.4,5,20,
            3,1,1,1,
            5,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Charge         = u_UserData0[0][0];
float Max_Core_Size  = u_UserData0[0][1];
float Corona_Reach   = u_UserData0[0][2];
float Jitter_Speed   = u_UserData0[0][3];
float Brightness     = u_UserData0[1][0];
vec3  Color          = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Aspect_Ratio   = u_UserData0[2][0];

const int SPIKE_OCTAVES = 3;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float rad = length( uv );
    float ang = atan( uv.y, uv.x );

    float coreSize = mix( 0.03, Max_Core_Size, Charge );
    float core = exp( -rad * rad * ( 3.0 / max( coreSize, 0.01 ) ) );

    float spikeNoise = 0.0;
    for ( int octave = 0; octave < SPIKE_OCTAVES; octave++ ) {
        float fo = float( octave );
        float freq = 6.0 + fo * 7.0;
        spikeNoise += sin( ang * freq + CoronaTotalTime * Jitter_Speed * ( 1.0 + fo * 0.7 ) + fo * 3.1 ) / ( fo + 1.0 );
    }
    spikeNoise = spikeNoise * 0.5 + 0.5;

    float spikeLen = coreSize * ( 1.0 + spikeNoise * Charge * Corona_Reach );
    float corona = exp( -pow( max( rad - coreSize, 0.0 ) / max( spikeLen - coreSize, 0.001 ), 2.0 ) ) * step( coreSize, rad );
    corona *= Charge;

    float flicker = 1.0 + sin( CoronaTotalTime * ( 8.0 + Charge * 30.0 ) ) * 0.15 * Charge;

    vec3 hot = mix( Color, vec3( 1.0 ), clamp( Charge * 1.2, 0.0, 1.0 ) );
    vec3 rgb = ( hot * core * 1.5 + Color * corona * 1.1 ) * Brightness * flicker;
    float alpha = clamp( ( core + corona ) * Brightness * flicker, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
