
--[[
    Original implementation for this bank. A single looping puff (driven
    by `mod(time, Puff_Interval)`, no external trigger needed) that grows
    via `smoothstep`, drifts upward linearly, and fades in its second
    half, with its edge distance perturbed by one tap of value noise so
    the outline reads as soft condensation rather than a hard-edged
    circle. Deliberately small and simple compared to this bank's bigger
    weather/smoke kernels - meant to sit right at a character's mouth for
    a cold-breath beat, not fill the screen.

    Pure generator, transparent background. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "frozenBreathFog"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Puff_Interval','Max_Size',
            'Drift_Amount','Opacity','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .5,.5,2.5,.18,
            .15,.55,.88,.93,
            .98,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.5,.02,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,1,6,.4,
            .4,1,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Origin_X      = u_UserData0[0][0];
float Origin_Y      = u_UserData0[0][1];
float Puff_Interval = u_UserData0[0][2];
float Max_Size      = u_UserData0[0][3];
float Drift_Amount  = u_UserData0[1][0];
float Opacity       = u_UserData0[1][1];
vec3  Color         = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];

P_RANDOM float hash21( vec2 p )
{
    p = fract( p * vec2( 123.34, 456.21 ) );
    p += dot( p, p + 45.32 );
    return fract( p.x * p.y );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash21( i );
    float b = hash21( i + vec2( 1.0, 0.0 ) );
    float c = hash21( i + vec2( 0.0, 1.0 ) );
    float d = hash21( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( a, b, u.x ), mix( c, d, u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( Origin_X, Origin_Y );
    uv.x *= Aspect_Ratio;

    float t = mod( CoronaTotalTime, Puff_Interval ) / Puff_Interval;

    vec2 puffPos = vec2( 0.0, -t * Drift_Amount );
    float distFromPuff = length( uv - puffPos );

    float size = Max_Size * smoothstep( 0.0, 0.4, t );
    float fade = 1.0 - smoothstep( 0.4, 1.0, t );

    float noiseVal = valueNoise( uv * 8.0 + t * 3.0 );
    float edgeNoise = size * ( 0.8 + 0.4 * noiseVal );

    float puffMask = ( 1.0 - smoothstep( edgeNoise * 0.6, max( edgeNoise, 0.001 ), distFromPuff ) ) * fade;

    vec3 rgb = Color;
    float alpha = clamp( puffMask * Opacity, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
