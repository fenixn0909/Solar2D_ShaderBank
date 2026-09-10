
--[[
    Original implementation for this bank. A fixed number of rings (the
    same "active" step-gated compile-time loop as elsewhere in this
    batch), each evenly phase-offset around one shared Pulse_Interval so
    they emerge staggered rather than all at once, expanding linearly
    from the center and fading out as they grow - the same general shape
    as a sonar ping, but tuned toward soft organic teal/cyan light rather
    than a hard-edged HUD line (see kernelG_UI_radarSweep.lua for the
    sweep-line version of a similar idea) and with no rotation component
    at all, closer to a jellyfish or magic-core heartbeat than a scanning
    sensor.

    Pure generator, transparent background. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "bioluminescentPulse"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Ring_Count','Pulse_Interval','Max_Radius','Ring_Width',
            'Core_Brightness','Color_R','Color_G','Color_B',
            'Aspect_Ratio','','','',
            '','','','',
        },
        default = {
            3,2.5,.42,.03,
            .5,.25,.9,.85,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            1,.5,.05,.005,
            0,0,0,0,
            .2,0,0,0,
            0,0,0,0,
        },
        max = {
            5,8,.6,.1,
            2,1,1,1,
            5,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Ring_Count      = u_UserData0[0][0];
float Pulse_Interval  = u_UserData0[0][1];
float Max_Radius      = u_UserData0[0][2];
float Ring_Width      = u_UserData0[0][3];
float Core_Brightness = u_UserData0[1][0];
vec3  Color           = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Aspect_Ratio    = u_UserData0[2][0];

const int RING_MAX = 5;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;
    float rad = length( uv );

    float total = 0.0;

    for ( int ringIndex = 0; ringIndex < RING_MAX; ringIndex++ ) {
        float active = step( float( ringIndex ) + 0.5, Ring_Count );
        float fi = float( ringIndex );

        float phaseOffset = fi / max( Ring_Count, 1.0 ) * Pulse_Interval;
        float t = mod( CoronaTotalTime + phaseOffset, Pulse_Interval ) / Pulse_Interval;

        float ringRadius = t * Max_Radius;
        float ringWidth = Ring_Width * ( 1.0 - t * 0.3 );
        float dist = abs( rad - ringRadius );
        float ring = ( 1.0 - smoothstep( 0.0, max( ringWidth, 0.001 ), dist ) ) * ( 1.0 - t );

        total += active * ring;
    }

    float coreGlow = exp( -rad * rad * ( 5.0 / max( Max_Radius, 0.05 ) ) ) * Core_Brightness;

    vec3 rgb = Color * ( total + coreGlow );
    float alpha = clamp( total + coreGlow, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
