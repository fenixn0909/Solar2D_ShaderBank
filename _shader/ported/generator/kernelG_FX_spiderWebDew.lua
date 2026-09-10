
--[[
    Original implementation for this bank. The web itself needs no loop
    at all - radial spokes and concentric rings are each a single `mod()`
    distance test in polar space (angular distance to the nearest spoke,
    radial distance to the nearest ring), same "distance to a repeating
    pattern" idea as a lot of this bank's grid-based effects. Only the
    dew-drop sparkles use a compile-time-bounded loop, reusing this
    batch's kernelG_FX_gemSparkle.lua's twinkle approach but positioning
    each drop at a hashed spoke/ring intersection instead of scattering
    freely, so the drops read as sitting ON the web rather than floating
    near it.

    Pure generator, transparent background - a spooky-forest or dewy-
    morning decorative overlay. Aspect_Ratio convention matches the rest
    of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "spiderWebDew"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Spoke_Count','Ring_Count','Web_Radius','Thread_Width',
            'Dew_Count','Dew_Size','Twinkle_Speed','Dew_Brightness',
            'Thread_Color_R','Thread_Color_G','Thread_Color_B','Aspect_Ratio',
            '','','','',
        },
        default = {
            10,6,.42,.006,
            5,.012,2,1.2,
            .85,.9,.95,1,
            0,0,0,0,
        },
        min = {
            4,2,.1,.001,
            0,.003,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            24,14,.6,.02,
            6,.04,6,3,
            1,1,1,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Spoke_Count    = u_UserData0[0][0];
float Ring_Count     = u_UserData0[0][1];
float Web_Radius     = u_UserData0[0][2];
float Thread_Width   = u_UserData0[0][3];
float Dew_Count      = u_UserData0[1][0];
float Dew_Size       = u_UserData0[1][1];
float Twinkle_Speed  = u_UserData0[1][2];
float Dew_Brightness = u_UserData0[1][3];
vec3  Thread_Color   = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Aspect_Ratio   = u_UserData0[2][3];

const int DEW_MAX = 6;
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

    float spokeAngle = TAU / Spoke_Count;
    float spokeDist = abs( mod( ang + spokeAngle * 0.5, spokeAngle ) - spokeAngle * 0.5 ) * rad;
    float spokes = ( 1.0 - smoothstep( 0.0, Thread_Width, spokeDist ) ) * step( rad, Web_Radius );

    float ringSpacing = Web_Radius / Ring_Count;
    float ringDist = abs( mod( rad + ringSpacing * 0.5, ringSpacing ) - ringSpacing * 0.5 );
    float rings = ( 1.0 - smoothstep( 0.0, Thread_Width, ringDist ) ) * step( rad, Web_Radius ) * step( 0.08, rad );

    float web = max( spokes, rings );

    float dew = 0.0;
    for ( int dewIndex = 0; dewIndex < DEW_MAX; dewIndex++ ) {
        float active = step( float( dewIndex ) + 0.5, Dew_Count );
        float fi = float( dewIndex );

        float dAngIndex = floor( hash1( fi * 3.3 ) * Spoke_Count );
        float dAngle = dAngIndex * spokeAngle;
        float dRadIndex = floor( hash1( fi * 7.7 ) * Ring_Count ) + 0.5;
        float dRad = dRadIndex * ringSpacing;
        vec2 dPos = vec2( cos( dAngle ), sin( dAngle ) ) * dRad;

        float twinkle = pow( 0.5 + 0.5 * sin( CoronaTotalTime * Twinkle_Speed + fi * 3.0 ), 4.0 );
        float dist = length( uv - dPos );
        float glint = exp( -dist * dist * ( 3.0 / max( Dew_Size, 0.005 ) ) ) * twinkle;

        dew += active * glint;
    }

    vec3 rgb = Thread_Color * web + vec3( 1.0 ) * dew * Dew_Brightness;
    float alpha = clamp( web * 0.85 + dew, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
