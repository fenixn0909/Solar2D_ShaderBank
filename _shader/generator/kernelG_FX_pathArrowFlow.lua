
--[[
    Original implementation for this bank. Repeating chevron/arrow
    shapes (built from two mirrored angled line segments, not a
    texture) flowing continuously along Aim_Angle - a tower-defense
    or puzzle-game "enemies travel this way" / waypoint-flow indicator.
    Chevron spacing and glow are exposed directly; motion is a simple
    scroll of the repeating chevron field along the direction vector.

    Checked against all existing kernels first: kernelG_BG_gridScroller
    scrolls a diagonal *grid* line pattern, not discrete arrow shapes,
    and has no directional "flow" read; nothing else in the bank draws
    repeating chevrons. Not related to this bank's swirl/vortex/whirl
    family either - straight-line flow, no rotation.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "pathArrowFlow"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Aim_Angle','Chevron_Size','Spacing','Speed',
            'Thickness','Color_R','Color_G','Color_B',
            'Glow','Opacity','Aspect_Ratio','',
            '','','','',
        },
        default = {
            0,.06,.16,.5,
            .015,.4,.9,1,
            .4,.85,1,0,
            0,0,0,0,
        },
        min = {
            0,.02,.05,0,
            .004,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            6.28318,.2,.5,3,
            .05,1,1,1,
            1.5,1,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Aim_Angle     = u_UserData0[0][0];
float Chevron_Size  = u_UserData0[0][1];
float Spacing       = u_UserData0[0][2];
float Speed         = u_UserData0[0][3];
float Thickness     = u_UserData0[1][0];
vec3  Arrow_Color   = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Glow          = u_UserData0[2][0];
float Opacity       = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 dir = vec2( cos( Aim_Angle ), sin( Aim_Angle ) );
    vec2 side = vec2( -dir.y, dir.x );

    vec2 rel = ( UV - vec2( 0.5 ) ) * vec2( 1.0, Aspect_Ratio );
    float along = dot( rel, dir ) - CoronaTotalTime * Speed;
    float across = dot( rel, side );

    float cell = floor( along / Spacing );
    float localAlong = fract( along / Spacing ) * Spacing - Spacing * 0.5;

    float armDist = abs( abs( across ) - ( -localAlong ) ) ;
    float chevron = 1.0 - smoothstep( Thickness, Thickness + 0.006, armDist );
    chevron *= step( abs( across ), Chevron_Size );
    chevron *= step( localAlong, Chevron_Size * 0.05 );
    chevron *= step( -Chevron_Size, localAlong );

    float glowFalloff = exp( -abs( armDist ) * 40.0 / max( Glow + 0.01, 0.01 ) ) * 0.4;

    float alpha = clamp( chevron + glowFalloff * step( abs( across ), Chevron_Size ), 0.0, 1.0 ) * Opacity;

    P_COLOR vec4 COLOR = vec4( Arrow_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
