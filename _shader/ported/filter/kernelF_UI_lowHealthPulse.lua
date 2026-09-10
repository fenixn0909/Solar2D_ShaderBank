
--[[
    Original implementation for this bank. A single Health uniform (0-1,
    drive it from your own game state) controls three things at once: how
    visible the vignette is at all, how strong it gets, and how fast it
    pulses - so as Health drops toward 0 the whole effect both intensifies
    and speeds up rather than needing separate curves tuned by hand. The
    pulse itself sums two sine waves at a 2.1x frequency ratio rather than
    a single sine, giving a lub-dub heartbeat shape instead of a smooth
    breathing fade.

    Meant to be applied to a full-screen overlay rectangle (its own fill
    color doesn't matter - this shader outputs its own vignette color
    directly) rather than a game-world sprite, distinguishing it from this
    bank's existing static/positional vignette kernels
    (kernelG_Lit_vignette.lua, kernelG_Lit_vignetteN.lua,
    kernelF_FX_sideVignette.lua), none of which are health/urgency-driven.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "lowHealthPulse"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Health','Inner_Radius','Fade_Width','Pulse_Speed',
            'Base_Strength','Pulse_Strength','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .25,.25,.5,1,
            .35,.45,.75,.05,
            .05,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.1,.2,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,.6,1,3,
            1,1,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Health         = u_UserData0[0][0];
float Inner_Radius   = u_UserData0[0][1];
float Fade_Width     = u_UserData0[0][2];
float Pulse_Speed    = u_UserData0[0][3];
float Base_Strength  = u_UserData0[1][0];
float Pulse_Strength = u_UserData0[1][1];
vec3  Color          = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio   = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float urgency = 1.0 - clamp( Health, 0.0, 1.0 );
    float freq = Pulse_Speed * ( 1.0 + urgency * 2.0 ) * 6.28318;
    float heartbeat = max( sin( CoronaTotalTime * freq ), sin( CoronaTotalTime * freq * 2.1 - 1.0 ) * 0.6 );
    heartbeat = clamp( heartbeat, 0.0, 1.0 );

    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;
    float dist = length( uv );

    float vignetteMask = smoothstep( Inner_Radius, Inner_Radius + Fade_Width, dist );
    float intensity = vignetteMask * ( Base_Strength + heartbeat * Pulse_Strength ) * urgency;

    vec3 rgb = Color * intensity;
    float alpha = clamp( intensity, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
