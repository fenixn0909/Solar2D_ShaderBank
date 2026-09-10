
--[[
    Original implementation for this bank. Not related to this bank's
    existing kernelG_BG_fireFly.lua (a ShaderToy port by flyingrub with
    its own fixed overhead-scene pattern) - this is a from-scratch
    multi-agent version instead: a compile-time-bounded set of
    independent fireflies (same "active" step-based count trick as this
    batch's kernelG_UI_radarSweep.lua), each wandering on its own closed-
    form two-frequency path (cheap, no simulation state needed between
    frames - just evaluate the path function at the current time) and
    flashing on an independent hashed cycle - a quick brighten followed
    by a slow fade, matching how real fireflies actually flash rather
    than glowing continuously.

    Pure generator, transparent background - a summer-night ambience
    overlay. Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "fireflyDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Firefly_Count','Wander','Speed','Size',
            'Color_R','Color_G','Color_B','Brightness',
            'Aspect_Ratio','','','',
            '','','','',
        },
        default = {
            6,.35,1,.012,
            .75,1,.4,1.3,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            0,.05,0,.002,
            0,0,0,0,
            .2,0,0,0,
            0,0,0,0,
        },
        max = {
            8,.5,3,.05,
            1,1,1,3,
            5,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Firefly_Count = u_UserData0[0][0];
float Wander        = u_UserData0[0][1];
float Speed         = u_UserData0[0][2];
float Size          = u_UserData0[0][3];
vec3  Color         = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Brightness    = u_UserData0[1][3];
float Aspect_Ratio  = u_UserData0[2][0];

const int FIREFLY_MAX = 8;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float t = CoronaTotalTime * Speed;
    float total = 0.0;

    for ( int fireflyIndex = 0; fireflyIndex < FIREFLY_MAX; fireflyIndex++ ) {
        float active = step( float( fireflyIndex ) + 0.5, Firefly_Count );
        float fi = float( fireflyIndex );

        float freq1 = 0.3 + hash1( fi * 3.1 ) * 0.4;
        float freq2 = 0.2 + hash1( fi * 5.7 ) * 0.3;
        float phase1 = hash1( fi * 7.3 ) * 6.28318;
        float phase2 = hash1( fi * 2.9 ) * 6.28318;
        vec2 home = vec2( hash1( fi * 11.1 ) - 0.5, hash1( fi * 13.7 ) - 0.5 ) * 1.4 * Wander;

        vec2 pos = home + vec2( sin( t * freq1 + phase1 ), cos( t * freq2 + phase2 ) ) * Wander;

        float dist = length( uv - pos );
        float glow = exp( -dist * dist * ( 4.0 / max( Size, 0.005 ) ) );

        float flashPhase = hash1( fi * 4.4 ) * 10.0;
        float flashCycle = 3.0 + hash1( fi * 6.6 ) * 4.0;
        float flashT = mod( CoronaTotalTime + flashPhase, flashCycle );
        float flash = smoothstep( 0.0, 0.3, flashT ) * ( 1.0 - smoothstep( 0.5, 1.2, flashT ) );

        total += active * glow * flash;
    }

    vec3 rgb = Color * total * Brightness;
    float alpha = clamp( total * Brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
