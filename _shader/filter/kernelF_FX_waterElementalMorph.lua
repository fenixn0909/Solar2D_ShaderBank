
--[[
    Original implementation for this bank. Modeled on the "water
    elemental" character-transform category from commercial character
    shader bundles - nothing was copied from any of them (all paid,
    closed-source). Unlike this batch's kernelF_FX_liquidChromeMorph
    (opaque, reflective, metallic, T-1000 read), this goes translucent
    and aquatic: alpha drops toward Translucency as Progress rises, a
    two-axis sine flow resample simulates an internal current rather
    than a rigid surface, a soft diagonal shimmer band stands in for
    light passing through a watery body, and the tint pushes toward
    blue-green rather than chrome.

    Checked against all existing kernels first: kernelC_FX_
    stylizedWater/stylizedWaterV2 and kernelG_generator water kernels
    (discreteOcean and others) render standalone water *surfaces*, not
    a Progress-driven transformation of an existing character sprite
    into a translucent water body; this batch's own liquidChromeMorph
    is opaque/reflective/metallic rather than translucent/aquatic - see
    its header for the explicit contrast. No overlap with either.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "waterElementalMorph"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Flow_Amount','Flow_Speed','Water_R',
            'Water_G','Water_B','Tint_Amount','Translucency',
            'Shimmer_Speed','Opacity','','',
            '','','','',
        },
        default = {
            0,.01,1.6,.25,
            .65,.75,.6,.55,
            3,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,.15,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.03,4,1,
            1,1,1,.9,
            8,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress       = u_UserData0[0][0];
float Flow_Amount    = u_UserData0[0][1];
float Flow_Speed     = u_UserData0[0][2];
vec3  Water_Tint     = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Tint_Amount    = u_UserData0[1][2];
float Translucency   = u_UserData0[1][3];
float Shimmer_Speed  = u_UserData0[2][0];
float Opacity        = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 flow = vec2(
        sin( UV.y * 15.0 + CoronaTotalTime * Flow_Speed ),
        cos( UV.x * 12.0 - CoronaTotalTime * Flow_Speed * 0.7 ) ) * Flow_Amount * Progress;

    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV + flow );
    P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );

    vec3 waterColor = mix( tex.rgb, Water_Tint, Progress * Tint_Amount );

    float shimmer = 0.5 + 0.5 * sin( UV.x * 20.0 + UV.y * 15.0 + CoronaTotalTime * Shimmer_Speed );
    waterColor += Water_Tint * shimmer * 0.12 * Progress;

    float finalAlpha = orig.a * mix( 1.0, Translucency, Progress );

    vec3 finalRGB = mix( orig.rgb, clamp( waterColor, 0.0, 1.0 ), Opacity );
    finalAlpha = mix( orig.a, finalAlpha, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
