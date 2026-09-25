
--[[
    Original implementation for this bank. Mirrors the sprite's own
    content across a settable Water_Line back into the region below it -
    the standard "wet street/puddle reflection" trick - with a sine-wave
    UV offset (driven by the sample's own y-coordinate so the ripple reads
    as horizontal water lines rather than a uniform wobble) and a
    distance-based fade/darken so the reflection reads as sitting in
    shallow water rather than a literal mirror. Blended in with smoothstep
    masks throughout rather than a hard branch at the water line, so there
    is no visible seam between "reflecting" and "not reflecting" pixels.

    Single-texture filter - reflects the sprite's own content, so it
    works best on a full scene/background capture rather than an isolated
    character sprite.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "puddleReflection"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Water_Line','Ripple_Amount','Ripple_Freq','Ripple_Speed',
            'Fade_Distance','Reflection_Opacity','Darken','',
            '','','','',
            '','','','',
        },
        default = {
            .65,.006,25,1.2,
            .35,.55,.65,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,2,-3,
            .05,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.03,60,3,
            1,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Water_Line         = u_UserData0[0][0];
float Ripple_Amount      = u_UserData0[0][1];
float Ripple_Freq        = u_UserData0[0][2];
float Ripple_Speed       = u_UserData0[0][3];
float Fade_Distance      = u_UserData0[1][0];
float Reflection_Opacity = u_UserData0[1][1];
float Darken             = u_UserData0[1][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float belowMask = smoothstep( Water_Line - 0.01, Water_Line + 0.01, UV.y );
    float mirroredY = Water_Line - ( UV.y - Water_Line );
    vec2 rippleUV = vec2( UV.x + sin( UV.y * Ripple_Freq + CoronaTotalTime * Ripple_Speed ) * Ripple_Amount, mirroredY );

    P_COLOR vec4 reflection = texture2D( CoronaSampler0, clamp( rippleUV, 0.0, 1.0 ) );

    float fade = 1.0 - clamp( ( UV.y - Water_Line ) / max( Fade_Distance, 0.001 ), 0.0, 1.0 );
    vec3 reflRGB = reflection.rgb * Darken;

    float reflAmount = belowMask * fade * Reflection_Opacity * reflection.a;
    vec3 finalRGB = mix( src.rgb, reflRGB, reflAmount );
    float finalAlpha = max( src.a, reflAmount );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
