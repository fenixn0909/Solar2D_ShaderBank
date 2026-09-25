
--[[
    Original implementation for this bank. The "rare loot" shimmer -
    a pulsing colored glow hugging an item icon's silhouette plus a
    diagonal shine sweeping across it every few seconds - is a genre
    convention rather than one shader (Diablo, Borderlands, and most
    ARPGs since all do some version of it), so this reimplements the
    convention itself: an 8-tap ring sample around each transparent
    pixel checks whether CoronaSampler0 has opaque content nearby (the
    same cheap "dilate the alpha, keep only where the source itself is
    still transparent" trick as this bank's outline kernels) to build
    the edge-hugging glow, and a separate `dot(uv, diagonalDir)` band
    sweeps a highlight across the icon's own opaque pixels on a loop.

    Tier_Color is meant to be driven by your own rarity table (set it to
    orange for legendary, purple for epic, blue for rare, etc.) - this
    shader only handles the shimmer, not the color logic. Works on any
    icon shape since it reads CoronaSampler0's own alpha rather than
    assuming a fixed silhouette. Aspect_Ratio convention matches the rest
    of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "rarityGlow"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Glow_Radius','Glow_Pulse_Speed','Glow_Pulse_Amount','Sweep_Speed',
            'Sweep_Width','Sweep_Angle','Sweep_Brightness','Tier_Color_R',
            'Tier_Color_G','Tier_Color_B','Base_Brightness','Aspect_Ratio',
            '','','','',
        },
        default = {
            .02,2.5,.3,.4,
            .08,.7,.6,1,
            .65,.15,1,1,
            0,0,0,0,
        },
        min = {
            0,0,0,-2,
            .01,0,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            .08,8,1,2,
            .3,6.28318,2,1,
            1,1,2,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Glow_Radius       = u_UserData0[0][0];
float Glow_Pulse_Speed  = u_UserData0[0][1];
float Glow_Pulse_Amount = u_UserData0[0][2];
float Sweep_Speed       = u_UserData0[0][3];
float Sweep_Width       = u_UserData0[1][0];
float Sweep_Angle       = u_UserData0[1][1];
float Sweep_Brightness  = u_UserData0[1][2];
vec3  Tier_Color        = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Base_Brightness   = u_UserData0[2][2];
float Aspect_Ratio      = u_UserData0[2][3];

const int EDGE_TAPS = 8;
const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float maxNearbyAlpha = src.a;
    for ( int tapIndex = 0; tapIndex < EDGE_TAPS; tapIndex++ ) {
        float ang = float( tapIndex ) / float( EDGE_TAPS ) * TAU;
        vec2 offset = vec2( cos( ang ), sin( ang ) ) * Glow_Radius;
        vec2 sampleUV = UV + vec2( offset.x, offset.y * Aspect_Ratio );
        maxNearbyAlpha = max( maxNearbyAlpha, texture2D( CoronaSampler0, clamp( sampleUV, 0.0, 1.0 ) ).a );
    }

    float glowMask = maxNearbyAlpha * ( 1.0 - src.a );
    float pulse = 1.0 + sin( CoronaTotalTime * Glow_Pulse_Speed ) * Glow_Pulse_Amount;
    vec3 glowRGB = Tier_Color * glowMask * pulse;
    float glowAlpha = glowMask * pulse * 0.85;

    vec2 dir = vec2( cos( Sweep_Angle ), sin( Sweep_Angle ) );
    float proj = dot( UV - vec2( 0.5 ), dir );
    float sweepPos = fract( CoronaTotalTime * Sweep_Speed ) * 3.0 - 1.0;
    float sweepMask = ( 1.0 - smoothstep( 0.0, Sweep_Width, abs( proj - sweepPos ) ) ) * src.a;

    vec3 baseRGB = src.rgb * Base_Brightness + vec3( 1.0 ) * sweepMask * Sweep_Brightness;

    vec3 rgb = baseRGB + glowRGB;
    float alpha = clamp( src.a + glowAlpha, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
