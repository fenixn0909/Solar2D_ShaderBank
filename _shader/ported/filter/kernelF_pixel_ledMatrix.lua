
--[[
    Original implementation for this bank. The "pixelate, then stamp a
    circular dot per cell" LED/dot-matrix technique is a small, widely
    reproduced idea with no single owner (the exact same construction
    turns up as a feature of Daniel Ilett's "Hologram Shaders Pro" Unity
    asset's Dot Matrix module, as a standalone Godot Shaders snippet, and
    in assorted "Dot Matrix Shader (LED Screen Effect)" writeups) - this
    is a fresh GLSL implementation of that general idea rather than a copy
    of any one of them, extended a bit further than the bare-bones
    versions: each LED cell samples the source texture ONCE at the cell's
    center (so every dot is a single flat color, like a real RGB LED
    rather than a smoothed-out pixel), the dot shape blends continuously
    between square and circular (Dot_Roundness), and there's an optional
    monochrome tint (Tint_Amount) for an old green-phosphor-terminal look
    instead of a full-color jumbotron.

    Works as a straightforward post-process filter on any sprite or
    screen-captured texture via CoronaSampler0. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "pixel"
kernel.name = "ledMatrix"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Grid_Size','Dot_Roundness','Gap','Brightness_Boost',
            'Background_R','Background_G','Background_B','Background_A',
            'Color_Tint_R','Color_Tint_G','Color_Tint_B','Tint_Amount',
            'Aspect_Ratio','','','',
        },
        default = {
            40,1,.28,1.15,
            .02,.02,.03,1,
            .1,1,.3,0,
            1,0,0,0,
        },
        min = {
            4,0,0,.5,
            0,0,0,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            128,1,.9,3,
            1,1,1,1,
            1,1,1,1,
            5,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Grid_Size        = u_UserData0[0][0];
float Dot_Roundness    = u_UserData0[0][1];
float Gap              = u_UserData0[0][2];
float Brightness_Boost = u_UserData0[0][3];
vec3  Background       = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Background_A     = u_UserData0[1][3];
vec3  Color_Tint       = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Tint_Amount      = u_UserData0[2][3];
float Aspect_Ratio     = u_UserData0[3][0];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 aspectVec = vec2( 1.0, Aspect_Ratio );
    vec2 grid = max( vec2( Grid_Size ) * aspectVec, vec2( 1.0 ) );

    vec2 gridUV = UV * grid;
    vec2 cellId = floor( gridUV );
    vec2 cellUV = fract( gridUV );

    vec2 sampleUV = ( cellId + 0.5 ) / grid;
    P_COLOR vec4 sourceColor = texture2D( CoronaSampler0, clamp( sampleUV, 0.0, 1.0 ) );

    vec2 centered = ( cellUV - 0.5 ) * 2.0;
    float roundDist = length( centered );
    float squareDist = max( abs( centered.x ), abs( centered.y ) );
    float shapeDist = mix( squareDist, roundDist, Dot_Roundness );

    float dotRadius = 1.0 - clamp( Gap, 0.0, 0.9 );
    float dotMask = 1.0 - smoothstep( dotRadius - 0.1, dotRadius, shapeDist );

    vec3 tinted = mix( sourceColor.rgb, Color_Tint, Tint_Amount ) * Brightness_Boost;

    vec3 finalRGB = mix( Background, tinted, dotMask );
    float finalAlpha = mix( Background_A, sourceColor.a, dotMask );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
