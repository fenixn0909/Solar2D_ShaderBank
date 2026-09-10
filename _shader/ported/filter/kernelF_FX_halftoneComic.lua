
--[[
    Original implementation for this bank. Classic print halftone screening:
    each grid cell samples CoronaSampler0 once at its center (the same
    single-tap-per-cell approach as this bank's kernelF_pixel_ledMatrix.lua
    and kernelF_pixel_asciiTerminal.lua), and instead of quantizing that
    luminance into density bands, draws one circular ink dot whose radius
    scales directly with darkness - exactly how real halftone printing
    (and the Ben-Day dots comic artists borrowed the look from) encodes
    tone using dot size on a fixed grid rather than continuous shading.

    Single-texture filter. Use_Source_Color toggles between classic single-
    ink-color dots (Ink_Color, default near-black on a warm paper tone)
    and dots tinted by the sprite's own color for a colored-print look.
    Output alpha always follows the source's own silhouette exactly - only
    the fill inside that silhouette is re-rendered as paper + dots.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "halftoneComic"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Grid_Size','Max_Dot_Radius','Use_Source_Color','Paper_Color_R',
            'Paper_Color_G','Paper_Color_B','Ink_Color_R','Ink_Color_G',
            'Ink_Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            22,.55,0,.96,
            .94,.88,.08,.08,
            .1,1,0,0,
            0,0,0,0,
        },
        min = {
            4,.2,0,0,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            60,.8,1,1,
            1,1,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Grid_Size        = u_UserData0[0][0];
float Max_Dot_Radius   = u_UserData0[0][1];
float Use_Source_Color = u_UserData0[0][2];
vec3  Paper_Color      = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
vec3  Ink_Color        = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio     = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 grid = vec2( Grid_Size ) * vec2( 1.0, Aspect_Ratio );
    vec2 cellId = floor( UV * grid );
    vec2 cellUV = fract( UV * grid );

    vec2 sampleUV = ( cellId + 0.5 ) / grid;
    P_COLOR vec4 src = texture2D( CoronaSampler0, clamp( sampleUV, 0.0, 1.0 ) );

    float lum = dot( src.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float dotRadius = ( 1.0 - lum ) * Max_Dot_Radius;
    float dist = length( cellUV - vec2( 0.5 ) );
    float dotShape = 1.0 - smoothstep( max( dotRadius - 0.06, 0.0 ), dotRadius, dist );

    vec3 inkColor = mix( Ink_Color, src.rgb, Use_Source_Color );
    vec3 rgb = mix( Paper_Color, inkColor, dotShape );

    P_COLOR vec4 localSrc = texture2D( CoronaSampler0, UV );
    float alpha = localSrc.a;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
