
--[[
    Original implementation for this bank. A one-toggle "cutscene mode"
    filter: solid bars top and bottom at Bar_Height, plus animated film
    grain, a mild desaturate/contrast push and a soft vignette applied
    to the visible strip in between - the combination games switch on
    for dialogue/cutscenes rather than four separate effects layered
    by hand.

    Checked against all existing kernels first: nothing else in the
    bank draws letterbox bars at all; the closest neighbors are this
    bank's several vignette filters (darken corners only, no bars, no
    grain, no grade) and kernelF_FX_claymationJitter/risoGrain (grain
    alone, no bars/vignette/grade combination). No single existing
    kernel combines bars + grain + grade + vignette into one cutscene
    toggle.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "cinematicLetterbox"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Bar_Height','Grain_Amount','Saturation','Contrast',
            'Vignette_Amount','Bar_R','Bar_G','Bar_B',
            'Opacity','','','',
            '','','','',
        },
        default = {
            .1,.04,.85,1.08,
            .35,0,0,0,
            1,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.7,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            2,.15,1.5,1.4,
            .8,1,1,1,
            1,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Bar_Height       = u_UserData0[0][0];
float Grain_Amount     = u_UserData0[0][1];
float Saturation       = u_UserData0[0][2];
float Contrast         = u_UserData0[0][3];
float Vignette_Amount  = u_UserData0[1][0];
vec3  Bar_Color        = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Opacity          = u_UserData0[2][0];

//----------------------------------------------

P_RANDOM float letterbox_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 41.7, 91.3 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float grain = letterbox_hash( UV * 500.0 + fract( CoronaTotalTime ) * 37.0 ) - 0.5;
    vec3 graded = tex.rgb + grain * Grain_Amount;

    float lum = dot( graded, vec3( 0.299, 0.587, 0.114 ) );
    graded = mix( vec3( lum ), graded, Saturation );
    graded = clamp( ( graded - 0.5 ) * Contrast + 0.5, 0.0, 1.0 );

    float d = length( UV - vec2( 0.5 ) );
    graded *= 1.0 - Vignette_Amount * smoothstep( 0.3, 0.75, d );

    float barMask = step( Bar_Height, UV.y ) * step( UV.y, 1.0 - Bar_Height );
    vec3 withBars = mix( Bar_Color, graded, barMask );

    vec3 finalRGB = mix( tex.rgb, withBars, Opacity );
    float finalAlpha = mix( tex.a, 1.0, ( 1.0 - barMask ) * Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
