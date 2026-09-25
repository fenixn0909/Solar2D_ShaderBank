
--[[

    V2 sprite-masked variant of kernelF_pixel_ledMatrix.lua
    (filter.pixel.ledMatrix) in this same folder - same "pixelate, then
    stamp a circular dot per cell" LED/dot-matrix idea, same single
    center-sample per cell (so every dot is one flat color like a real
    RGB LED), same square-to-circular Dot_Roundness blend and optional
    monochrome Tint_Amount.

    Difference from V1: V1 always composites every dot over an opaque
    Background color, so even fully transparent sprite areas come out
    as a solid rectangle of LED dots. This V2 instead applies the dots
    ONLY where the sprite itself has color:

      - outside the sprite (center-sampled alpha below Alpha_Threshold)
        stays fully transparent - no background fill, no dots;
      - inside the sprite the gaps between dots are transparent too,
        not Background-colored, so the silhouette is preserved and the
        result can sit over any backdrop;
      - dot alpha is center-sampled sprite alpha x dot shape, with a
        small smoothstep feather above Alpha_Threshold so soft
        anti-aliased edges fade instead of popping.

    If you want the opaque jumbotron / terminal-screen look with a
    backdrop fill, use the original ledMatrix; if you want an LED
    version of the sprite itself that keeps its shape, use this V2.

    Works as a straightforward post-process filter on any sprite via
    CoronaSampler0. Aspect_Ratio convention matches the rest of this
    bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "pixel"
kernel.name = "ledMatrixV2"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Grid_Size','Dot_Roundness','Gap','Brightness_Boost',
            'Alpha_Threshold','','','',
            'Color_Tint_R','Color_Tint_G','Color_Tint_B','Tint_Amount',
            'Aspect_Ratio','','','',
        },
        default = {
            40,1,.28,1.15,
            .05,0,0,0,
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
float Alpha_Threshold  = u_UserData0[1][0];
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

    // Sprite-only gate: empty cells stay transparent. Small feather so
    // soft edges fade instead of popping at the cutoff.
    float alphaKeep = smoothstep( Alpha_Threshold, Alpha_Threshold + 0.08, sourceColor.a );

    vec3 tinted = mix( sourceColor.rgb, Color_Tint, Tint_Amount ) * Brightness_Boost;

    vec3 finalRGB = tinted;
    float finalAlpha = sourceColor.a * dotMask * alphaKeep;

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
