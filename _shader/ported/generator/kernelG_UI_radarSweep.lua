
--[[
    Original implementation for this bank. A classic radar/sonar HUD:
    one rotating sweep line with an angular afterglow trailing behind it,
    range rings, and a handful of hashed-position blips that light up
    brightly right as the sweep passes over them and dim afterward -
    reusing the same "active" step-based count trick this bank already
    uses for tunable-but-compile-time-bounded loops (see
    kernelG_FX_gemSparkle.lua's header) so Blip_Count is adjustable
    without a variable loop bound.

    Pure generator, transparent background - a sci-fi/submarine/tactical
    HUD overlay. Aspect_Ratio convention matches the rest of this bank
    (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "UI"
kernel.name = "radarSweep"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Sweep_Speed','Sweep_Width','Afterglow_Amount','Radius',
            'Ring_Count','Blip_Count','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            1.5,.15,.5,.42,
            3,4,.2,1,
            .35,1,0,0,
            0,0,0,0,
        },
        min = {
            -6,.02,0,.05,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            6,1,1,.6,
            8,6,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Sweep_Speed      = u_UserData0[0][0];
float Sweep_Width      = u_UserData0[0][1];
float Afterglow_Amount = u_UserData0[0][2];
float Radius           = u_UserData0[0][3];
float Ring_Count       = u_UserData0[1][0];
float Blip_Count       = u_UserData0[1][1];
vec3  Color            = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio     = u_UserData0[2][1];

const int BLIP_MAX = 6;
const float TAU = 6.28318530718;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float rad = length( uv );
    float ang = atan( uv.y, uv.x );
    float sweepAngle = mod( CoronaTotalTime * Sweep_Speed, TAU );
    float inside = 1.0 - smoothstep( 0.0, Radius, rad );

    float angDiff = mod( sweepAngle - ang + TAU, TAU );
    float sweepGlow = exp( -angDiff * angDiff * ( 2.0 / max( Sweep_Width, 0.05 ) ) ) * inside;
    float afterglow = exp( -angDiff * 1.2 ) * inside * Afterglow_Amount;

    float ringDist = abs( fract( rad / max( Radius, 0.001 ) * Ring_Count + 0.5 ) - 0.5 );
    float rings = ( 1.0 - smoothstep( 0.0, 0.01, ringDist ) ) * step( rad, Radius );

    float blips = 0.0;
    for ( int blipIndex = 0; blipIndex < BLIP_MAX; blipIndex++ ) {
        float active = step( float( blipIndex ) + 0.5, Blip_Count );
        float fi = float( blipIndex );

        float bAngle = hash1( fi * 3.7 + 1.0 ) * TAU;
        float bRad = sqrt( hash1( fi * 5.1 + 2.0 ) ) * Radius * 0.85;
        vec2 bPos = vec2( cos( bAngle ), sin( bAngle ) ) * bRad;

        float bDist = length( uv - bPos );
        float bAngDiff = mod( sweepAngle - bAngle + TAU, TAU );
        float lit = exp( -bAngDiff * 3.0 ) * step( bAngDiff, 1.5 );
        float dotShape = 1.0 - smoothstep( 0.01, 0.02, bDist );

        blips += active * dotShape * max( lit, 0.15 );
    }

    vec3 rgb = Color * ( sweepGlow + afterglow + rings * 0.4 + blips );
    float alpha = clamp( sweepGlow + afterglow + rings * 0.4 + blips, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
