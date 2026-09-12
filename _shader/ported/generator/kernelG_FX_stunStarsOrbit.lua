
--[[
    Original implementation for this bank. The classic cartoon "seeing
    stars" stun/dizzy status: a small handful of four-point sparkle
    shapes (each a soft blob crossed with two thin perpendicular
    glints, cheaper than a true star polygon) orbiting in an ellipse
    above Center, evenly phase-spaced around the loop.

    Checked against all existing kernels first: every existing "star"
    kernel is either a full-screen sky/field (kernelG_BG_starField,
    starryNight, starryTunnel, kernelG_BG_starFall) or a single glowing
    burst (kernelG_FX_starburst, gemSparkle's multi-point twinkle on a
    static gem). None orbit a small fixed count of marks in an ellipse
    above a specific point the way a stun status needs. Also distinct
    from kernelG_FX_bioluminescentPulse (expanding rings, not orbiting
    points) and kernelG_FX_curseAuraWisp (this batch - curling tendrils,
    not discrete orbiting points).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "stunStarsOrbit"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Center_X','Center_Y','Orbit_Radius_X','Orbit_Radius_Y',
            'Speed','Star_Size','Color_R','Color_G',
            'Color_B','Count','Aspect_Ratio','',
            '','','','',
        },
        default = {
            .5,.35,.16,.05,
            2,.02,1,.9,
            .2,3,1,0,
            0,0,0,0,
        },
        min = {
            0,0,.05,.01,
            0,.005,0,0,
            0,1,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,.4,.15,
            6,1,1,1,
            1,30,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Center        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
vec2  Orbit_Radius  = vec2( u_UserData0[0][2], u_UserData0[0][3] );
float Speed         = u_UserData0[1][0];
float Star_Size     = u_UserData0[1][1];
vec3  Star_Color    = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Count         = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 rel = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );

    float glow = 0.0;

    for ( int i = 0; i < 30; i++ )
    {
        float fi = float( i );
        float active = step( fi + 0.5, Count );
        float phase = fi / max( Count, 1.0 ) * TAU;
        float t = CoronaTotalTime * Speed + phase;

        vec2 pos = vec2( cos( t ) * Orbit_Radius.x, sin( t ) * Orbit_Radius.y - Orbit_Radius.y );
        vec2 d = rel - pos;

        float blob = exp( -dot( d, d ) / max( Star_Size * Star_Size, 0.0001 ) );
        float glintA = exp( -( d.x * d.x ) / max( Star_Size * Star_Size * 0.02, 0.0001 ) - ( d.y * d.y ) / max( Star_Size * Star_Size * 3.0, 0.0001 ) );
        float glintB = exp( -( d.y * d.y ) / max( Star_Size * Star_Size * 0.02, 0.0001 ) - ( d.x * d.x ) / max( Star_Size * Star_Size * 3.0, 0.0001 ) );
        float twinkle = 0.6 + 0.4 * sin( t * 5.0 );

        glow = max( glow, ( blob * 0.6 + max( glintA, glintB ) ) * twinkle * active );
    }

    P_COLOR vec4 COLOR = vec4( Star_Color, clamp( glow, 0.0, 1.0 ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
