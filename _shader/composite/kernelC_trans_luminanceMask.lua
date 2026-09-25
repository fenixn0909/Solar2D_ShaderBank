
--[[
    https://godotshaders.com/shader/luminance-mask-transition/
    null_builds
    April 10, 2026

    Direct port. paint1 = display_texture (the character/content shown
    as-is, never tinted by the mask), paint2 = mask_texture (a
    greyscale/noise mask - only its luminance is read, its own color
    never reaches the output).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "trans"
kernel.name = "luminanceMask"

kernel.vertexData =
{
  { name = "Luminance_Cutoff", default = 0, min = 0, max = 1, index = 0, },
  { name = "Invert",           default = 0, min = 0, max = 1, index = 1, },
}


kernel.fragment =
[[

float Luminance_Cutoff = CoronaVertexUserData.x;
float Invert           = CoronaVertexUserData.y;
//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 mask_sample = texture2D( CoronaSampler1, UV );
    float luminance = dot( mask_sample.rgb, vec3( 0.2126, 0.7152, 0.0722 ) );

    bool onFilter = luminance > Luminance_Cutoff;
    if ( Invert > 0.5 ) {
        onFilter = !onFilter;
    }

    P_COLOR vec4 display = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 COLOR = onFilter ? display : ( vec4( 1.0, 1.0, 1.0, 0.0 ) * display );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

