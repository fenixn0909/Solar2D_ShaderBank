
--[[
    Original implementation for this bank. Each meteor is a closed-form
    function of its own local cycle time (no per-frame state to track): a
    head position that travels along a fixed diagonal from a hashed
    starting point, a tapered tail measured as signed distance along that
    same diagonal behind the head, and a fade-in/fade-out envelope over
    its lifetime - a fixed number of independently-phased meteors (the
    same "active" step-based count trick this batch already uses
    elsewhere, e.g. kernelG_UI_radarSweep.lua) loop endlessly without
    ever needing to spawn/despawn from Lua.

    Pure generator, transparent background - a night-sky overlay.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "meteorShower"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Meteor_Count','Speed','Travel_Distance','Tail_Length',
            'Width','Color_R','Color_G','Color_B',
            'Head_White','Brightness','Aspect_Ratio','',
            '','','','',
        },
        default = {
            3,.5,1.3,.18,
            .006,.7,.85,1,
            .8,1.3,1,0,
            0,0,0,0,
        },
        min = {
            0,0,.3,.02,
            .001,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            6,3,2,.5,
            .03,1,1,1,
            1,3,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Meteor_Count    = u_UserData0[0][0];
float Speed           = u_UserData0[0][1];
float Travel_Distance = u_UserData0[0][2];
float Tail_Length     = u_UserData0[0][3];
float Width           = u_UserData0[1][0];
vec3  Color           = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Head_White      = u_UserData0[2][0];
float Brightness      = u_UserData0[2][1];
float Aspect_Ratio    = u_UserData0[2][2];

const int METEOR_MAX = 6;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    vec2 dir = normalize( vec2( -0.6, 1.0 ) );
    vec2 perp = vec2( -dir.y, dir.x );

    float total = 0.0;
    float headGlow = 0.0;

    for ( int meteorIndex = 0; meteorIndex < METEOR_MAX; meteorIndex++ ) {
        float active = step( float( meteorIndex ) + 0.5, Meteor_Count );
        float fi = float( meteorIndex );

        float cycle = 2.0 + hash1( fi * 3.3 ) * 3.0;
        float tLocal = mod( CoronaTotalTime * Speed + hash1( fi * 7.7 ) * 20.0, cycle );
        float progress = tLocal / cycle;

        vec2 startPos = vec2( hash1( fi * 5.5 ) * Aspect_Ratio, hash1( fi * 9.9 ) * 0.4 );
        vec2 headPos = startPos + dir * progress * Travel_Distance;

        vec2 toPixel = uv - headPos;
        float alongDir = dot( toPixel, dir );
        float perpDir = dot( toPixel, perp );

        float tailMask = step( -Tail_Length, alongDir ) * step( alongDir, 0.02 );
        float taper = 1.0 - clamp( -alongDir / Tail_Length, 0.0, 1.0 );
        float lineWidth = max( Width * taper, 0.0005 );
        float line = ( 1.0 - smoothstep( 0.0, lineWidth, abs( perpDir ) ) ) * tailMask * taper;

        float fadeInOut = smoothstep( 0.0, 0.1, progress ) * ( 1.0 - smoothstep( 0.85, 1.0, progress ) );

        total += active * line * fadeInOut;
        headGlow += active * line * fadeInOut * smoothstep( 0.7, 1.0, taper );
    }

    vec3 rgb = mix( Color, vec3( 1.0 ), clamp( headGlow, 0.0, 1.0 ) * Head_White ) * total * Brightness;
    float alpha = clamp( total * Brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
