
--[[
    Original implementation for this bank of the classic Truchet tile
    pattern - one of the standard "first three" 2D pattern techniques
    taught in shader courses alongside Voronoi and hexagonal tiling
    (the tiling itself predates computing entirely: Sebastien Truchet's
    17th-century tile studies). Each grid cell gets one of two quarter-
    circle-pair orientations from a per-cell hash, and because both
    orientations always meet cell edges at the same midpoints, the
    arcs chain into a continuous flowing maze regardless of the random
    per-cell choice. An optional slow color drift along the line length
    gives it a "flowing energy circuit" read for magic/tech UI use.

    Checked against all existing kernels first: this bank's Voronoi-
    based kernels (kernelF_FX_stainedGlassMosaic, kernelG_FX_
    moltenCracks, kernelF_FX_crackOverlay and others) all key off
    nearest-cell-center distance fields, a different geometric family
    entirely from arc-tiling; kernelF_trans_hexagonalize/kernelC_trans_
    hexGrid tile hexagons with no arcs at all. No existing kernel
    builds the arc-based Truchet pattern.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "truchetTiles"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Grid_Scale','Line_Width','Flow_Speed','Color_R',
            'Color_G','Color_B','BG_R','BG_G',
            'BG_B','Seed','Opacity','',
            '','','','',
        },
        default = {
            8,.09,.6,.3,
            .85,1,.06,.07,
            .1,0,1,0,
            0,0,0,0,
        },
        min = {
            2,.02,-2,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            24,.25,16,1,
            1,1,1,1,
            1,50,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Grid_Scale  = u_UserData0[0][0];
float Line_Width  = u_UserData0[0][1];
float Flow_Speed  = u_UserData0[0][2];
vec3  Line_Color  = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
vec3  BG_Color    = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Seed        = u_UserData0[2][1];
float Opacity     = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float truchet_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 41.9, 289.3 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 scaled = UV * Grid_Scale;
    vec2 cell = floor( scaled );
    vec2 local = fract( scaled );

    float h = truchet_hash( cell + Seed );
    float flip = step( 0.5, h );
    vec2 localF = mix( local, vec2( 1.0 - local.x, local.y ), flip );

    float d1 = abs( length( localF - vec2( 0.0, 0.0 ) ) - 0.5 );
    float d2 = abs( length( localF - vec2( 1.0, 1.0 ) ) - 0.5 );
    float dist = min( d1, d2 );

    float mask = smoothstep( Line_Width, Line_Width * 0.3, dist );

    float arcLen = ( d1 < d2 ) ? atan( localF.y, localF.x ) : atan( localF.y - 1.0, localF.x - 1.0 );
    float flow = 0.5 + 0.5 * sin( arcLen * 3.0 + ( cell.x + cell.y ) * 1.7 - CoronaTotalTime * Flow_Speed );

    vec3 finalRGB = mix( BG_Color, Line_Color * mix( 0.6, 1.3, flow ), mask );
    finalRGB = mix( BG_Color, finalRGB, Opacity ) ;

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
