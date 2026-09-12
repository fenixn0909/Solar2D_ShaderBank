
--[[
    Original implementation for this bank. Twin engine-exhaust flame
    plumes streaming from two nozzle points along Aim_Angle, built from
    a 3-octave fbm advected along the exhaust direction so the flame
    body writhes rather than just scrolling; a hot white-blue core near
    the nozzle fades to orange at the tips via a cascaded color ramp,
    and overall length flickers with a slower secondary noise term so
    the plume visibly gutters rather than holding a static silhouette.

    Checked against all existing kernels first: kernelG_FX_torchFlame
    is a single upward-drifting candle/campfire flame (buoyant, not
    directional-exhaust shaped, no twin-nozzle framing);
    kernelF_FX_fire2D/fire2DV2 recolor an existing mask *texture*
    rather than generating flame from nothing; kernelG_generator
    lava/noiseAnimLava kernels are static ground-texture noise, not a
    directional jet. Nothing else in the bank is a directional dual-
    nozzle exhaust plume.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "nitroFlameTrail"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Nozzle1_X','Nozzle1_Y','Nozzle2_X','Nozzle2_Y',
            'Aim_Angle','Flame_Length','Flicker_Speed','Turbulence',
            'Core_R','Core_G','Core_B','Tip_R',
            'Tip_G','Tip_B','Intensity','Aspect_Ratio',
        },
        default = {
            .4,.5,.6,.5,
            3.14159,.3,3,2.2,
            .85,.92,1,1,
            .45,.05,1,1,
        },
        min = {
            0,0,0,0,
            0,.05,0,0,
            0,0,0,0,
            0,0,0,.2,
        },
        max = {
            1,1,1,1,
            6.28318,.7,8,6,
            1,1,1,1,
            1,1,2,5,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Nozzle1        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
vec2  Nozzle2        = vec2( u_UserData0[0][2], u_UserData0[0][3] );
float Aim_Angle      = u_UserData0[1][0];
float Flame_Length   = u_UserData0[1][1];
float Flicker_Speed  = u_UserData0[1][2];
float Turbulence     = u_UserData0[1][3];
vec3  Core_Color     = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
vec3  Tip_Color      = vec3( u_UserData0[2][3], u_UserData0[3][0], u_UserData0[3][1] );
float Intensity      = u_UserData0[3][2];
float Aspect_Ratio   = u_UserData0[3][3];

//----------------------------------------------

P_RANDOM float nitro_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 51.3, 97.1 ) ) ) * 43758.5453123 );
}

P_RANDOM float nitro_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( nitro_hash( i ), nitro_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( nitro_hash( i + vec2( 0.0, 1.0 ) ), nitro_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float nitro_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.55;
    for ( int i = 0; i < 3; i++ )
    {
        total += nitro_noise( p ) * amp;
        p *= 2.1;
        amp *= 0.5;
    }
    return total;
}

float nitro_plume( vec2 uv, vec2 nozzle, float seed )
{
    vec2 dir = vec2( cos( Aim_Angle ), sin( Aim_Angle ) );
    vec2 side = vec2( -dir.y, dir.x );

    vec2 rel = ( uv - nozzle ) * vec2( 1.0, Aspect_Ratio );
    float along = dot( rel, dir );
    float across = dot( rel, side );

    float flicker = 0.75 + 0.25 * sin( CoronaTotalTime * Flicker_Speed + seed * 6.0 );
    float len = Flame_Length * flicker;

    float t = clamp( along / max( len, 0.0001 ), 0.0, 1.0 );
    // Wide core tapering to a point at the tip for a natural jet look.
    float width = mix( 0.16, 0.0, pow( t, 0.75 ) );

    vec2 noiseUV = vec2( along * 6.0 - CoronaTotalTime * Flicker_Speed * 2.0, across * 10.0 + seed * 20.0 );
    float n = nitro_fbm( noiseUV ) - 0.5;
    float wobble = n * Turbulence * 0.05 * t;

    float body = smoothstep( width + wobble, ( width + wobble ) * 0.2, abs( across - wobble * 0.5 ) );
    float lenMask = smoothstep( len, len * 0.9, along ) * step( 0.0, along );

    return body * lenMask;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float p1 = nitro_plume( UV, Nozzle1, 1.0 );
    float p2 = nitro_plume( UV, Nozzle2, 7.0 );
    float mask = max( p1, p2 );

    vec2 dir = vec2( cos( Aim_Angle ), sin( Aim_Angle ) );
    float along1 = dot( ( UV - Nozzle1 ) * vec2( 1.0, Aspect_Ratio ), dir );
    float along2 = dot( ( UV - Nozzle2 ) * vec2( 1.0, Aspect_Ratio ), dir );
    float t1 = clamp( along1 / max( Flame_Length, 0.0001 ), 0.0, 1.0 );
    float t2 = clamp( along2 / max( Flame_Length, 0.0001 ), 0.0, 1.0 );
    float t = ( t1 * p1 + t2 * p2 ) / max( p1 + p2, 0.0001 );

    vec3 rgb = mix( Core_Color, Tip_Color, t ) * Intensity;
    float alpha = clamp( mask, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
