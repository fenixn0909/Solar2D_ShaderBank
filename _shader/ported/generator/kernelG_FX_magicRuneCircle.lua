
--[[
    Original implementation for this bank. Fantasy "magic circle" VFX packs
    (e.g. the 14-effect Magic Circle Spells packs sold for Unity) are
    normally built from pre-rendered circle textures composited in a
    particle system - explicitly for performance, per their own listings.
    This does the opposite on purpose: a fully procedural version with no
    texture dependency at all, so it drops into any project with zero
    art requirements. Several concentric rings (compile-time-bounded loop,
    same GLES-safety reasoning as the other loop-based kernels in this
    bank), each independently counter-rotating with an alternating lit/
    unlit segment pattern standing in for rune notches, plus a bright
    core and soft outer glow.

    Pure generator, transparent background - center it under a spellcaster
    sprite. Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "magicRuneCircle"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Rotation_Speed','Ring_Count','Rune_Count','Radius',
            'Thickness','Glow','Color_R','Color_G',
            'Color_B','Core_Brightness','Pulse_Speed','Pulse_Amount',
            'Aspect_Ratio','','','',
        },
        default = {
            .4,3,10,.32,
            .02,.5,.55,.85,
            1,.6,2,.15,
            1,0,0,0,
        },
        min = {
            -3,1,3,.05,
            .002,.05,0,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            3,4,24,.5,
            .08,2,1,1,
            1,2,8,1,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Rotation_Speed = u_UserData0[0][0];
float Ring_Count     = u_UserData0[0][1];
float Rune_Count     = u_UserData0[0][2];
float Radius         = u_UserData0[0][3];
float Thickness      = u_UserData0[1][0];
float Glow           = u_UserData0[1][1];
vec3  Color          = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Core_Brightness= u_UserData0[2][1];
float Pulse_Speed    = u_UserData0[2][2];
float Pulse_Amount   = u_UserData0[2][3];
float Aspect_Ratio   = u_UserData0[3][0];

const int RING_MAX = 4;
const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float ang = atan( uv.y, uv.x );
    float rad = length( uv );

    float total = 0.0;

    for ( int ringIndex = 0; ringIndex < RING_MAX; ringIndex++ ) {
        float active = step( float( ringIndex ) + 0.5, Ring_Count );
        float fi = float( ringIndex );

        float ringRadius = Radius * ( 0.42 + fi * 0.2 );
        float rotDir = mix( 1.0, -1.0, mod( fi, 2.0 ) );
        float rotated = ang + CoronaTotalTime * Rotation_Speed * rotDir * ( 1.0 + fi * 0.15 );

        float ringBand = 1.0 - smoothstep( Thickness * 0.5, Thickness, abs( rad - ringRadius ) );

        float notches = Rune_Count * ( 1.0 + fi * 0.5 );
        float segment = step( 0.5, fract( rotated / TAU * notches ) );

        total += active * ringBand * mix( 0.35, 1.0, segment );
    }

    float core = exp( -rad * rad * 18.0 ) * Core_Brightness;
    float pulse = 1.0 + sin( CoronaTotalTime * Pulse_Speed ) * Pulse_Amount;
    float glowFalloff = exp( -rad * rad * ( 6.0 / max( Glow, 0.05 ) ) );

    float alpha = clamp( ( total + core + glowFalloff * 0.3 ) * pulse, 0.0, 1.0 );
    vec3 col = Color * ( total + core * 1.4 + glowFalloff * 0.6 ) * pulse;

    P_COLOR vec4 COLOR = vec4( col, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
