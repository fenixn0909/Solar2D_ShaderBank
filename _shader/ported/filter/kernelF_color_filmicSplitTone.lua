
--[[
    Original implementation for this bank. A professional color-grade
    combo: an ACES-approximation filmic tone curve (Narkowicz's fit)
    compresses highlights with a cinematic rolloff instead of clipping,
    then Shadow_Tint and Highlight_Tint are blended in by luminance
    weight independently (classic split-toning/"teal and orange" style
    grading, where shadows and highlights can be pushed toward
    different colors rather than a single uniform tint).

    Checked against all existing kernels first: kernelF_color_HSV and
    kernelF_color_whiteBalance adjust hue/saturation/temperature
    uniformly across all luminances with no tone-curve compression and
    no separate shadow/highlight targets; kernelF_color_posterize
    quantizes into flat bands rather than a continuous filmic curve;
    kernelF_color_colorPalette4/correctBlind remap the whole image
    against fixed reference values, not a luminance-weighted two-tint
    split. None combine a filmic S-curve with independent shadow/
    highlight tinting.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "filmicSplitTone"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Exposure','Tint_Strength','Shadow_R','Shadow_G',
            'Shadow_B','Highlight_R','Highlight_G','Highlight_B',
            'Opacity','','','',
            '','','','',
        },
        default = {
            1,.35,.15,.25,
            .35,1,.85,.6,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            .2,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3,1,1,1,
            1,1,1,1,
            1,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Exposure       = u_UserData0[0][0];
float Tint_Strength  = u_UserData0[0][1];
vec3  Shadow_Tint    = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
vec3  Highlight_Tint = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Opacity        = u_UserData0[2][0];

//----------------------------------------------

vec3 fst_aces( vec3 x )
{
    return clamp( ( x * ( 2.51 * x + 0.03 ) ) / ( x * ( 2.43 * x + 0.59 ) + 0.14 ), 0.0, 1.0 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec3 graded = fst_aces( tex.rgb * Exposure );
    float lum = dot( graded, vec3( 0.299, 0.587, 0.114 ) );

    float shadowW = 1.0 - smoothstep( 0.0, 0.5, lum );
    float highlightW = smoothstep( 0.5, 1.0, lum );

    vec3 toned = graded + Shadow_Tint * shadowW * Tint_Strength * 0.5 + Highlight_Tint * highlightW * Tint_Strength * 0.5;
    toned = clamp( toned, 0.0, 1.0 );

    vec3 finalRGB = mix( tex.rgb, toned, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
