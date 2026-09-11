
--[[
    Original implementation for this bank. A full sky backdrop that
    cycles through night -> dawn -> sunrise -> day -> sunset -> dusk ->
    night as a single continuous loop, driven by "phase" = fract(
    CoronaTotalTime * Cycle_Speed + Time_Offset ). Two independently-
    keyed 8-stop gradients (zenith and horizon) are blended vertically,
    plus one procedural celestial disc that arcs across the sky, warm
    near the horizon and pale near its peak, dimming out naturally as
    it nears either horizon crossing rather than needing separate sun/
    moon logic. Sparse stars fade in as the disc dims.

    Dual-mode by design: leave Cycle_Speed > 0 for a self-playing sky
    (no Lua driving needed), or set Cycle_Speed = 0 and write
    Time_Offset from game code every frame (0-1 = your own time-of-day
    state) for a game-driven sky - same pattern this bank already uses
    for other live-value uniforms (see kernelG_FX_energyShieldDome's
    Impact_Time header note).

    Checked against all existing kernels first: kernelG_BG_
    steppedGradient/steppedGradient4 are static banded gradients with
    no time-of-day cycling or celestial body; nothing else in the bank
    builds a day-night sky cycle.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "dayNightCycle"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Cycle_Speed','Time_Offset','Horizon_Y','Sun_Size',
            'Sun_Glow','Sun_Arc_Height','Star_Amount','Saturation',
            'Brightness','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .02,0,.7,.035,
            .08,.35,.6,1,
            1,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.2,.01,
            0,.1,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            .2,1,.95,.1,
            .3,.7,1,1.5,
            1.5,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cycle_Speed    = u_UserData0[0][0];
float Time_Offset    = u_UserData0[0][1];
float Horizon_Y      = u_UserData0[0][2];
float Sun_Size       = u_UserData0[0][3];
float Sun_Glow       = u_UserData0[1][0];
float Sun_Arc_Height = u_UserData0[1][1];
float Star_Amount    = u_UserData0[1][2];
float Saturation     = u_UserData0[1][3];
float Brightness     = u_UserData0[2][0];
float Aspect_Ratio   = u_UserData0[2][1];

const float PI = 3.14159265;

//----------------------------------------------

P_RANDOM float sky_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 91.3, 47.7 ) ) ) * 31548.5453 );
}

vec3 sky_zenith( float ph )
{
    vec3 c0 = vec3( 0.02, 0.02, 0.08 );
    vec3 c1 = vec3( 0.05, 0.05, 0.15 );
    vec3 c2 = vec3( 0.25, 0.35, 0.55 );
    vec3 c3 = vec3( 0.35, 0.55, 0.85 );
    vec3 c4 = vec3( 0.25, 0.55, 0.95 );
    vec3 c5 = vec3( 0.30, 0.50, 0.85 );
    vec3 c6 = vec3( 0.35, 0.25, 0.45 );
    vec3 c7 = vec3( 0.08, 0.06, 0.18 );

    vec3 col = mix( c0, c1, smoothstep( 0.0, 0.22, ph ) );
    col = mix( col, c2, smoothstep( 0.22, 0.30, ph ) );
    col = mix( col, c3, smoothstep( 0.30, 0.42, ph ) );
    col = mix( col, c4, smoothstep( 0.42, 0.50, ph ) );
    col = mix( col, c5, smoothstep( 0.50, 0.58, ph ) );
    col = mix( col, c6, smoothstep( 0.58, 0.70, ph ) );
    col = mix( col, c7, smoothstep( 0.70, 0.80, ph ) );
    col = mix( col, c0, smoothstep( 0.80, 1.0, ph ) );
    return col;
}

vec3 sky_horizon( float ph )
{
    vec3 c0 = vec3( 0.05, 0.05, 0.12 );
    vec3 c1 = vec3( 0.15, 0.10, 0.25 );
    vec3 c2 = vec3( 0.95, 0.55, 0.35 );
    vec3 c3 = vec3( 0.65, 0.75, 0.85 );
    vec3 c4 = vec3( 0.55, 0.75, 0.95 );
    vec3 c5 = vec3( 0.75, 0.70, 0.65 );
    vec3 c6 = vec3( 0.90, 0.45, 0.30 );
    vec3 c7 = vec3( 0.15, 0.08, 0.20 );

    vec3 col = mix( c0, c1, smoothstep( 0.0, 0.22, ph ) );
    col = mix( col, c2, smoothstep( 0.22, 0.30, ph ) );
    col = mix( col, c3, smoothstep( 0.30, 0.42, ph ) );
    col = mix( col, c4, smoothstep( 0.42, 0.50, ph ) );
    col = mix( col, c5, smoothstep( 0.50, 0.58, ph ) );
    col = mix( col, c6, smoothstep( 0.58, 0.70, ph ) );
    col = mix( col, c7, smoothstep( 0.70, 0.80, ph ) );
    col = mix( col, c0, smoothstep( 0.80, 1.0, ph ) );
    return col;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float phase = fract( CoronaTotalTime * Cycle_Speed + Time_Offset );

    vec3 zenith = sky_zenith( phase );
    vec3 horizon = sky_horizon( phase );
    float vgrad = smoothstep( Horizon_Y - 0.35, Horizon_Y + 0.35, 1.0 - UV.y );
    vec3 rgb = mix( horizon, zenith, vgrad );

    float sunHeight = sin( clamp( phase, 0.0, 1.0 ) * PI );
    float sunX = phase;
    float sunY = Horizon_Y - Sun_Arc_Height * sunHeight;
    float sunVisible = smoothstep( 0.0, 0.3, sunHeight );
    vec3 sunTint = mix( vec3( 1.0, 0.55, 0.25 ), vec3( 1.0, 0.97, 0.85 ), smoothstep( 0.15, 0.6, sunHeight ) );

    vec2 dSun = ( UV - vec2( sunX, sunY ) ) * vec2( 1.0, Aspect_Ratio );
    float distSun = length( dSun );
    float sunDisc = smoothstep( Sun_Size, Sun_Size * 0.3, distSun );
    float sunHalo = exp( -( distSun * distSun ) / max( Sun_Glow * Sun_Glow, 0.0001 ) ) * 0.6;

    rgb = mix( rgb, sunTint, sunDisc * sunVisible );
    rgb += sunTint * sunHalo * sunVisible * 0.5;

    float nightAmt = 1.0 - sunVisible;
    vec2 starCell = floor( UV * 90.0 );
    float starHash = sky_hash( starCell );
    float star = step( 0.985, starHash ) * ( 0.5 + 0.5 * sin( CoronaTotalTime * 2.0 + starHash * 60.0 ) );
    rgb += vec3( 1.0 ) * star * nightAmt * Star_Amount;

    rgb *= Brightness;
    float g = dot( rgb, vec3( 0.299, 0.587, 0.114 ) );
    rgb = mix( vec3( g ), rgb, Saturation );

    P_COLOR vec4 COLOR = vec4( clamp( rgb, 0.0, 1.0 ), 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
