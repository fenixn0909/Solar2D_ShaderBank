
--[[
    Original implementation for this bank. A fighting-game "freeze
    frame on KO" look: desaturation, a contrast/gamma push, a closing
    radial vignette and a slight red-cyan chromatic edge separation all
    ramp in together as Progress goes 0->1, meant to be held near 1 for
    the freeze beat then released. It's the specific *combination* that
    reads as a knockout beat, not any single piece.

    Checked against all existing kernels first: this bank already has
    several single-purpose pieces of this combo (kernelF_blur_vignette
    variants for darkening alone, kernelF_FX_CA for chromatic split
    alone, kernelF_color_HSV for desaturation alone) but nothing
    combines desaturate + contrast + closing vignette + chroma edge
    into one Progress-driven "impact freeze" beat the way a KO moment
    needs - checked to be sure this specific combination doesn't
    already exist as a single kernel anywhere in the bank.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "koFreezeVignette"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Desaturate_Amount','Contrast_Boost','Vignette_Amount',
            'Chroma_Amount','Tint_R','Tint_G','Tint_B',
            '','','','',
            '','','','',
        },
        default = {
            0,1,.5,.6,
            .01,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1.5,1,
            .04,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress          = u_UserData0[0][0];
float Desaturate_Amount = u_UserData0[0][1];
float Contrast_Boost    = u_UserData0[0][2];
float Vignette_Amount   = u_UserData0[0][3];
float Chroma_Amount     = u_UserData0[1][0];
vec3  Tint_Color        = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 dir = normalize( UV - vec2( 0.5 ) + 0.0001 );
    vec2 off = dir * Chroma_Amount * Progress;

    float rC = texture2D( CoronaSampler0, UV + off ).r;
    float gC = texture2D( CoronaSampler0, UV ).g;
    float bC = texture2D( CoronaSampler0, UV - off ).b;
    float aC = texture2D( CoronaSampler0, UV ).a;
    vec3 tex = vec3( rC, gC, bC );

    float lum = dot( tex, vec3( 0.299, 0.587, 0.114 ) );
    vec3 desat = mix( tex, vec3( lum ), Desaturate_Amount * Progress );

    vec3 contrasted = ( desat - 0.5 ) * ( 1.0 + Contrast_Boost * Progress ) + 0.5;
    contrasted *= Tint_Color;

    float d = length( UV - vec2( 0.5 ) );
    float vig = 1.0 - Vignette_Amount * Progress * smoothstep( 0.15, 0.7, d );

    vec3 finalRGB = clamp( contrasted * vig, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( finalRGB, aC );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
