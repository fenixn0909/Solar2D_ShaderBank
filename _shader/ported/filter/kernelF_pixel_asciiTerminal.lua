
--[[
    Original implementation for this bank. Real ASCII-art shaders usually
    sample a packed bitmap font, which needs both a font-atlas texture
    input and bitwise ops to unpack - not available in GLSL ES 1.00 (no
    `&`/`|`/`<<` without `#version 300 es`), which this bank's kernels
    avoid entirely for broad device compatibility. This gets the same
    "readable density gradient" impression a different way: each text
    cell samples CoronaSampler0 once at its center (same single-tap-per-
    cell trick as this batch's kernelF_pixel_ledMatrix.lua), quantizes
    that luminance into 6 levels, and each level draws one hand-built
    procedural glyph-like shape (dot, two dots, cross, hash-grid, filled
    block) using plain `length`/`smoothstep` SDFs - no font texture, no
    bitwise tricks, just increasing "ink density" per level standing in
    for '.', ':', '+', '#', and a solid block.

    Single-texture filter. Aspect_Ratio only affects the cell grid's
    proportions, same convention as kernelF_pixel_ledMatrix.lua.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "pixel"
kernel.name = "asciiTerminal"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Grid_Size','Use_Source_Color','Color_R','Color_G',
            'Color_B','Background_R','Background_G','Background_B',
            'Background_A','Brightness_Boost','Aspect_Ratio','',
            '','','','',
        },
        default = {
            28,0,.15,1,
            .25,.02,.02,.02,
            1,1.2,1,0,
            0,0,0,0,
        },
        min = {
            6,0,0,0,
            0,0,0,0,
            0,.3,.2,0,
            0,0,0,0,
        },
        max = {
            80,1,1,1,
            1,1,1,1,
            1,3,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Grid_Size        = u_UserData0[0][0];
float Use_Source_Color = u_UserData0[0][1];
vec3  Color            = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
vec3  Background       = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Background_A     = u_UserData0[2][0];
float Brightness_Boost = u_UserData0[2][1];
float Aspect_Ratio     = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 aspectVec = vec2( 1.0, Aspect_Ratio );
    vec2 grid = max( vec2( Grid_Size ) * aspectVec, vec2( 1.0 ) );

    vec2 gridUV = UV * grid;
    vec2 cellId = floor( gridUV );
    vec2 cellUV = fract( gridUV );

    vec2 sampleUV = ( cellId + 0.5 ) / grid;
    P_COLOR vec4 src = texture2D( CoronaSampler0, clamp( sampleUV, 0.0, 1.0 ) );

    float lum = dot( src.rgb, vec3( 0.299, 0.587, 0.114 ) ) * src.a;
    float levelF = floor( clamp( lum, 0.0, 0.999 ) * 6.0 );

    vec2 c = cellUV - vec2( 0.5 );
    float shape = 0.0;

    if ( levelF < 0.5 ) {
        shape = 0.0;
    } else if ( levelF < 1.5 ) {
        shape = 1.0 - smoothstep( 0.08, 0.14, length( c ) );
    } else if ( levelF < 2.5 ) {
        float d1 = length( c - vec2( 0.0, 0.15 ) );
        float d2 = length( c - vec2( 0.0, -0.15 ) );
        shape = max( 1.0 - smoothstep( 0.07, 0.12, d1 ), 1.0 - smoothstep( 0.07, 0.12, d2 ) );
    } else if ( levelF < 3.5 ) {
        float bar1 = ( 1.0 - smoothstep( 0.06, 0.1, abs( c.x ) ) ) * step( abs( c.y ), 0.3 );
        float bar2 = ( 1.0 - smoothstep( 0.06, 0.1, abs( c.y ) ) ) * step( abs( c.x ), 0.3 );
        shape = max( bar1, bar2 );
    } else if ( levelF < 4.5 ) {
        float g1 = ( 1.0 - smoothstep( 0.03, 0.07, abs( abs( c.x ) - 0.18 ) ) ) * step( abs( c.y ), 0.35 );
        float g2 = ( 1.0 - smoothstep( 0.03, 0.07, abs( abs( c.y ) - 0.18 ) ) ) * step( abs( c.x ), 0.35 );
        shape = clamp( max( g1, g2 ), 0.0, 1.0 );
    } else {
        shape = step( abs( c.x ), 0.38 ) * step( abs( c.y ), 0.38 );
    }

    vec3 glyphColor = mix( Color, src.rgb, Use_Source_Color ) * Brightness_Boost;
    vec3 rgb = mix( Background, glyphColor, shape );
    float alpha = mix( Background_A, 1.0, shape );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
