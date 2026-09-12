
--[[
    Original implementation for this bank. A flat, static-position
    tower-defense/RTS "range" or "placement radius" indicator: a
    translucent disc fill out to Radius, a bright double-edge ring at
    the boundary, a slow inward-pulsing secondary ring for a subtle
    "scanning" read, and evenly-spaced rotating dash ticks around the
    rim. Meant to sit flat under units/buildings, not attached to any
    sprite's own silhouette.

    Checked against all existing kernels first: kernelG_UI_radarSweep
    rotates a single wedge/beam across the *whole* disc with blips (a
    detection sweep, no filled radius, no dashed static boundary);
    kernelG_UI_questBeacon is a vertical light column + bobbing marker,
    not a flat ground-plane circle. Nothing else in the bank draws a
    static filled-radius indicator with a dashed rotating rim.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "UI"
kernel.name = "rangeIndicatorRing"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Center_X','Center_Y','Radius','Edge_Softness',
            'Fill_Alpha','Ring_R','Ring_G','Ring_B',
            'Dash_Count','Rotate_Speed','Scan_Speed','Aspect_Ratio',
            '','','','',
        },
        default = {
            .5,.5,.35,.01,
            .12,.4,.9,1,
            24,.3,.6,1,
            0,0,0,0,
        },
        min = {
            0,0,.05,.002,
            0,0,0,0,
            6,-2,0,.2,
            0,0,0,0,
        },
        max = {
            1,1,.6,.05,
            .6,1,1,1,
            60,2,3,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Center        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Radius        = u_UserData0[0][2];
float Edge_Softness = u_UserData0[0][3];
float Fill_Alpha    = u_UserData0[1][0];
vec3  Ring_Color    = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Dash_Count    = u_UserData0[2][0];
float Rotate_Speed  = u_UserData0[2][1];
float Scan_Speed    = u_UserData0[2][2];
float Aspect_Ratio  = u_UserData0[2][3];

const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 d = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( d );
    float ang = atan( d.y, d.x );

    float fill = smoothstep( Radius, Radius - Edge_Softness * 3.0, dist ) * Fill_Alpha;

    float ring = smoothstep( Edge_Softness, 0.0, abs( dist - Radius ) );

    float scanR = Radius * ( 0.5 + 0.5 * fract( CoronaTotalTime * Scan_Speed * 0.2 ) );
    float scanRing = smoothstep( Edge_Softness * 2.0, 0.0, abs( dist - scanR ) ) * 0.5;

    float dashAngle = ang - CoronaTotalTime * Rotate_Speed;
    float dashPattern = step( 0.5, fract( dashAngle / TAU * Dash_Count ) );
    float dashRing = smoothstep( Edge_Softness * 1.6, 0.0, abs( dist - Radius ) ) * dashPattern;

    float alpha = clamp( fill + ring + scanRing + dashRing, 0.0, 1.0 );
    vec3 rgb = Ring_Color;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
