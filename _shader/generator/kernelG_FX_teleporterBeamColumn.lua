
--[[
    Original implementation for this bank. A sci-fi teleporter-pad
    column: a wide vertical band filled with upward-scrolling streak
    texture (elongated noise stripes moving up, not particles), a
    pulsing ring at the base where a character would stand, and a
    Materialize uniform (0 = not present/fully transparent, 1 = fully
    solid) meant to be tweened by game code for an appear/disappear
    moment - independent of the beam's own continuous idle animation.

    Checked against all existing kernels first: kernelG_UI_questBeacon
    is a *waypoint marker* - a thin column topped with a bobbing
    diamond, meant to hover over a location, not stand a character in;
    no streak texture, no materialize trigger. kernelG_ray_holy fans
    rays from a source at an angle (a divine-light rig, not a fixed
    vertical column a character occupies). kernelG_FX_energyBeam2 is a
    Godot-ported attack/weapon beam, not an idle standing pad. None of
    the three combine a column + streak scroll + materialize trigger.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "teleporterBeamColumn"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Center_X','Column_Width','Column_Height','Speed',
            'Color_R','Color_G','Color_B','Base_Ring_Size',
            'Materialize','Streak_Density','Aspect_Ratio','Beam_Angle',
            'Glow','','','',
        },
        default = {
            .5,.22,.9,.6,
            .4,.9,1,.14,
            1,14,1,0,
            1,0,0,0,
        },
        min = {
            0,.05,.2,0,
            0,0,0,.02,
            0,2,.2,-3.14159,
            0,0,0,0,
        },
        max = {
            1,.5,1,3,
            1,1,1,.3,
            1,40,5,3.14159,
            3,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Center_X       = u_UserData0[0][0];
float Column_Width   = u_UserData0[0][1];
float Column_Height  = u_UserData0[0][2];
float Speed          = u_UserData0[0][3];
vec3  Beam_Color     = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Base_Ring_Size = u_UserData0[1][3];
float Materialize    = u_UserData0[2][0];
float Streak_Density = u_UserData0[2][1];
float Aspect_Ratio   = u_UserData0[2][2];
float Beam_Angle     = u_UserData0[2][3]; // 0 = vertical, +/- lean
float Glow           = u_UserData0[3][0]; // edge + ring glow strength

//----------------------------------------------

P_RANDOM float tp_hash( float n )
{
    return fract( sin( n * 43.27 ) * 12543.547 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 base = vec2( Center_X, 1.0 );
    // Beam axis: 0 = straight up, rotated by Beam_Angle. At 0 this
    // reproduces the original vertical column exactly.
    vec2 axis = vec2( sin( Beam_Angle ), -cos( Beam_Angle ) );
    vec2 perp = vec2( cos( Beam_Angle ), sin( Beam_Angle ) );
    vec2 relB = UV - base;
    float along = dot( relB, axis ); // 0 at base, Column_Height at top
    float across = dot( relB, perp );

    float acrossN = across / max( Column_Width * 0.5, 0.0001 );
    float colMask = smoothstep( 1.0, 0.85, abs( acrossN ) );
    float vertMask = smoothstep( -0.02, 0.05, along ) * smoothstep( Column_Height + 0.1, Column_Height - 0.1, along );

    float scrollY = ( 1.0 - along ) * 40.0 + CoronaTotalTime * Speed * 20.0;
    float cell = floor( scrollY );
    float streak = tp_hash( cell + floor( acrossN * Streak_Density ) );
    float streakMask = step( 0.55, streak ) * ( 1.0 - abs( acrossN ) );

    float edgeGlow = ( smoothstep( 1.0, 0.7, abs( acrossN ) ) - smoothstep( 0.7, 0.3, abs( acrossN ) ) ) * Glow;

    vec2 d = ( UV - vec2( Center_X, 1.0 ) ) * vec2( 1.0, Aspect_Ratio );
    float ringDist = length( d );
    float pulse = 0.5 + 0.5 * sin( CoronaTotalTime * 3.0 );
    float baseRing = smoothstep( 0.015, 0.0, abs( ringDist - Base_Ring_Size * ( 0.9 + 0.1 * pulse ) ) ) * Glow;

    float body = colMask * vertMask * ( 0.35 + streakMask * 0.5 + edgeGlow * 0.6 );
    float alpha = clamp( body + baseRing, 0.0, 1.0 ) * Materialize;

    P_COLOR vec4 COLOR = vec4( Beam_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
