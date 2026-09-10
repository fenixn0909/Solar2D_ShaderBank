
--[[
    Original implementation for this bank. A vertical light column (a
    simple width-vs-height band test measured up from the bottom of the
    UV rect) topped with a bobbing diamond marker (an L1/taxicab-distance
    test, which draws a diamond the same cheap way a Euclidean distance
    test draws a circle), both breathing on the same pulse so the beam and
    marker read as one connected object rather than two independently
    animated pieces.

    Pure generator, transparent background - a waypoint/objective marker
    hovering over a location. Aspect_Ratio convention matches the rest of
    this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "UI"
kernel.name = "questBeacon"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Beam_Height','Beam_Width','Pulse_Speed','Bob_Speed',
            'Bob_Amount','Marker_Size','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .5,.012,2,2.5,
            .02,.035,1,.85,
            .2,1,0,0,
            0,0,0,0,
        },
        min = {
            .1,.002,0,0,
            0,.01,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,.05,6,6,
            .08,.1,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Beam_Height  = u_UserData0[0][0];
float Beam_Width   = u_UserData0[0][1];
float Pulse_Speed  = u_UserData0[0][2];
float Bob_Speed    = u_UserData0[0][3];
float Bob_Amount   = u_UserData0[1][0];
float Marker_Size  = u_UserData0[1][1];
vec3  Color        = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float localHeight = clamp( ( UV.y - ( 1.0 - Beam_Height ) ) / max( Beam_Height, 0.0001 ), 0.0, 1.0 );
    float beamMask = ( 1.0 - smoothstep( 0.0, Beam_Width, abs( UV.x - 0.5 ) * Aspect_Ratio ) ) * step( 1.0 - Beam_Height, UV.y );
    float beamFade = localHeight * 0.7 + 0.3;

    float pulse = 1.0 + sin( CoronaTotalTime * Pulse_Speed ) * 0.2;

    float bobY = ( 1.0 - Beam_Height ) - 0.05 + sin( CoronaTotalTime * Bob_Speed ) * Bob_Amount;
    vec2 toMarker = UV - vec2( 0.5, bobY );
    toMarker.x *= Aspect_Ratio;
    float markerDist = abs( toMarker.x ) + abs( toMarker.y );
    float markerMask = 1.0 - smoothstep( Marker_Size * 0.8, Marker_Size, markerDist );

    vec3 rgb = Color * ( beamMask * beamFade * pulse * 0.7 + markerMask * pulse );
    float alpha = clamp( beamMask * beamFade * pulse * 0.7 + markerMask * pulse, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
