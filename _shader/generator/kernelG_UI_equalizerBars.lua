
--[[
    Original implementation for this bank. A classic music/audio-
    visualizer bar meter - no real audio input is available inside a
    fragment kernel, so each bar's height comes from a layered-sine
    "fake spectrum" function (per-bar hashed frequencies/phases so no
    two bars move identically). The falling peak-hold cap real VU
    meters have is faked without any frame-to-frame memory: the same
    height function is resampled at several recent time offsets each
    frame and the max is kept, which reads as a peak that lags behind
    and settles, at the cost of a small fixed loop instead of state.
    Bar color runs green -> yellow -> red via HSV hue rather than
    spending uniform slots on three separate RGB stops.

    Checked against all existing kernels first: nothing else in the
    bank is an audio/spectrum-style bar meter - closest neighbors by
    UI role are kernelG_UI_statusBar (a single static fill bar, no
    per-bar animation) and kernelG_UI_radarSweep (a rotating sweep
    line, unrelated mechanic). No overlap.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "UI"
kernel.name = "equalizerBars"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Bar_Count','Speed','Seed','Bar_Gap',
            'Bar_Area_Height','Peak_Thickness','Hue_Low','Hue_High',
            'Saturation','Value','Peak_Hue','Opacity',
            '','','','',
        },
        default = {
            16,1.4,0,.18,
            .85,.02,.33,0,
            .85,1,.15,1,
            0,0,0,0,
        },
        min = {
            2,0,0,0,
            .2,.005,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            48,4,50,.45,
            1,.06,1,1,
            1,1,1,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Bar_Count       = u_UserData0[0][0];
float Speed           = u_UserData0[0][1];
float Seed            = u_UserData0[0][2];
float Bar_Gap         = u_UserData0[0][3];
float Bar_Area_Height = u_UserData0[1][0];
float Peak_Thickness  = u_UserData0[1][1];
float Hue_Low         = u_UserData0[1][2];
float Hue_High        = u_UserData0[1][3];
float Saturation      = u_UserData0[2][0];
float Value           = u_UserData0[2][1];
float Peak_Hue        = u_UserData0[2][2];
float Opacity         = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float eq_hash( float n )
{
    return fract( sin( n * 191.9 ) * 43758.5453123 );
}

vec3 eq_hsv2rgb( vec3 c )
{
    vec3 rgb = clamp( abs( mod( c.x * 6.0 + vec3( 0.0, 4.0, 2.0 ), 6.0 ) - 3.0 ) - 1.0, 0.0, 1.0 );
    return c.z * mix( vec3( 1.0 ), rgb, c.y );
}

float eq_barHeight( float barIndex, float t )
{
    float h1 = eq_hash( barIndex + Seed );
    float h2 = eq_hash( barIndex + Seed + 7.0 );
    float h3 = eq_hash( barIndex + Seed + 13.0 );

    float w1 = sin( t * Speed * ( 1.3 + h1 * 2.0 ) + h1 * 10.0 );
    float w2 = sin( t * Speed * ( 2.7 + h2 * 3.0 ) + h2 * 10.0 );
    float w3 = sin( t * Speed * ( 0.6 + h3 * 1.0 ) + h3 * 10.0 );

    float raw = 0.5 + w1 * 0.25 + w2 * 0.125 + w3 * 0.2;
    return clamp( raw, 0.02, 1.0 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float barIndexF = floor( UV.x * Bar_Count );
    float cellX = fract( UV.x * Bar_Count );
    float gapMask = smoothstep( 0.0, Bar_Gap, cellX ) * smoothstep( 1.0, 1.0 - Bar_Gap, cellX );

    float t = CoronaTotalTime;
    float h = eq_barHeight( barIndexF, t );

    float peak = 0.0;
    for ( int k = 0; k < 5; k++ )
    {
        float dt = float( k ) * 0.08;
        peak = max( peak, eq_barHeight( barIndexF, t - dt ) );
    }

    float bottomY = 1.0;
    float barTopY = bottomY - h * Bar_Area_Height;
    float inBar = step( barTopY, UV.y ) * step( UV.y, bottomY );

    float peakY = bottomY - peak * Bar_Area_Height;
    float peakLine = smoothstep( Peak_Thickness, 0.0, abs( UV.y - peakY ) );

    float levelForColor = clamp( ( bottomY - UV.y ) / max( Bar_Area_Height, 0.0001 ), 0.0, 1.0 );
    float hue = mix( Hue_Low, Hue_High, levelForColor );
    vec3 barColor = eq_hsv2rgb( vec3( hue, Saturation, Value ) );
    vec3 peakColor = eq_hsv2rgb( vec3( Peak_Hue, Saturation, Value ) );

    float mask = inBar * gapMask;
    float peakMask = peakLine * gapMask;
    vec3 rgb = barColor * mask + peakColor * peakMask;
    float alpha = clamp( mask + peakMask, 0.0, 1.0 ) * Opacity;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
