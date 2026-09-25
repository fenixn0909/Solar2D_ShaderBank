
--[[
    Original implementation for this bank of the "flying through an
    infinite tunnel" look - one of the most recognizable raymarched-
    demo silhouettes on shader showcase sites, faked here entirely in
    2D screen space rather than actually raymarching: polar-remapping
    UV around a center point turns radial distance into a depth proxy
    (1/radius recedes toward the center), a checker pattern is scrolled
    along both the angular and depth axes for the tunnel-wall texture,
    and a central glow sells the "light at the end of the tunnel" read.

    Checked against all existing kernels first: kernelG_FX_
    hyperSpaceSpeed streaks radial lines outward from center for a warp-
    speed starfield read - motion lines with no wall texture or
    checkerboard depth cue; kernelG_FX_whirlpoolVortex/kernelF_deform_
    vortexOverlay swirl UVs angularly with no polar-to-depth remap and
    no scrolling wall pattern. Neither produces the tunnel-wall-
    scrolling-past-camera illusion this does.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "raymarchTunnelWarp"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Angular_Segments','Depth_Scale','Speed','Color_A_R',
            'Color_A_G','Color_A_B','Color_B_R','Color_B_G',
            'Color_B_B','Glow_Size','Glow_R','Glow_G',
            'Glow_B','Aspect_Ratio','','',
        },
        default = {
            10,3,.6,.15,
            .1,.25,.3,.18,
            .45,.18,1,.9,
            .6,1,0,0,
        },
        min = {
            3,.5,-2,0,
            0,0,0,0,
            0,.03,0,0,
            0,.2,0,0,
        },
        max = {
            24,8,2,1,
            1,1,1,1,
            1,.5,1,1,
            1,5,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Angular_Segments = u_UserData0[0][0];
float Depth_Scale       = u_UserData0[0][1];
float Speed             = u_UserData0[0][2];
vec3  Color_A           = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
vec3  Color_B           = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Glow_Size         = u_UserData0[2][1];
vec3  Glow_Color        = vec3( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0] );
float Aspect_Ratio      = u_UserData0[3][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p = ( UV - vec2( 0.5 ) ) * vec2( 1.0, Aspect_Ratio );
    float radius = length( p );
    float angle = atan( p.y, p.x );

    float depth = 1.0 / max( radius, 0.02 );
    float u = angle / 6.28318 + 0.5;

    float cx = floor( u * Angular_Segments );
    float cy = floor( depth * Depth_Scale - CoronaTotalTime * Speed );
    float checker = mod( cx + cy, 2.0 );

    vec3 wallColor = mix( Color_A, Color_B, checker );
    float depthFade = clamp( radius * 2.2, 0.0, 1.0 );
    wallColor *= mix( 0.25, 1.0, depthFade );

    float glow = exp( -( radius * radius ) / max( Glow_Size * Glow_Size, 0.0001 ) );
    vec3 finalRGB = clamp( wallColor + Glow_Color * glow, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
