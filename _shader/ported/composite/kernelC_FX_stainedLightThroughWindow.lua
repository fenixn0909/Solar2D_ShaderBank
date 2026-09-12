
--[[
    Original implementation for this bank. Projects colored light
    through a stained-glass window onto a separate base scene:
    CoronaSampler1 supplies the window's color/pattern (a stained-
    glass texture), which is skewed along Light_Angle to fake a low
    sun angle and added onto CoronaSampler0's base image as tinted
    light splashes, with thin dark mullion lines (the window's metal
    frame) subtracted back in. This is a light *projection* onto a
    different scene, not a self-stylization of the input sprite.

    Checked against all existing kernels first: kernelF_FX_
    stainedGlassMosaic is a single-sampler *filter* that turns the
    input sprite itself into a stained-glass mosaic look - it
    restyles one image, it doesn't cast that image's colored light
    onto a second one. Different sampler count and different purpose;
    no overlap in output or use case.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "stainedLightThroughWindow"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Light_Angle','Skew_Amount','Intensity','Mullion_Width',
            'Warmth','Opacity','','',
            '','','','',
            '','','','',
        },
        default = {
            .6,.35,.8,.02,
            .15,.85,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -1.5,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1.5,1,2,.08,
            .5,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Light_Angle    = u_UserData0[0][0];
float Skew_Amount    = u_UserData0[0][1];
float Intensity      = u_UserData0[0][2];
float Mullion_Width  = u_UserData0[0][3];
float Warmth         = u_UserData0[1][0];
float Opacity        = u_UserData0[1][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 base = texture2D( CoronaSampler0, UV );

    vec2 skewUV = UV + vec2( ( UV.y - 0.5 ) * Skew_Amount * tan( Light_Angle ), 0.0 );
    P_COLOR vec4 window = texture2D( CoronaSampler1, skewUV );

    float lum = dot( window.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float mullion = smoothstep( Mullion_Width, Mullion_Width * 0.4, lum ) * window.a;

    vec3 warmTint = mix( vec3( 1.0 ), vec3( 1.0, 0.85, 0.65 ), Warmth );
    vec3 lightSplash = window.rgb * window.a * warmTint * Intensity;

    vec3 finalRGB = base.rgb + lightSplash * ( 1.0 - mullion * 0.7 );
    finalRGB = mix( base.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( clamp( finalRGB, 0.0, 1.0 ), base.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
