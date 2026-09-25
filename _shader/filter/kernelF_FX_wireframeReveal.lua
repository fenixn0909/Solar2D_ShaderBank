
--[[
    Original implementation for this bank. Builds a "holographic wireframe
    mesh" look from three ingredients, none of which need extra art: a
    triple crosshatch grid (horizontal + vertical + diagonal `fract`
    bands) standing in for a wireframe mesh, an alpha-gradient edge
    detector (comparing CoronaSampler0's alpha against its neighbours one
    texel over, same idea as this batch's kernelF_UI_rarityGlow.lua) to
    keep the silhouette outline bright, and a single looping horizontal
    scan band for the classic sci-fi hologram sweep. Base_Alpha controls
    how much of the sprite's own fill still peeks through underneath
    (0 = fully see-through wireframe, higher = a ghostly fill as well).

    Single-texture filter - works on any sprite's own alpha shape, no
    second map required. Aspect_Ratio isn't needed here since nothing
    measures radial/circular distance.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "wireframeReveal"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Grid_Density','Line_Width','Line_Brightness','Edge_Sharpness',
            'Edge_Brightness','Scan_Speed','Scan_Width','Scan_Brightness',
            'Color_R','Color_G','Color_B','Base_Alpha',
            '','','','',
        },
        default = {
            24,.06,.8,6,
            1.5,.4,.04,.6,
            .3,.85,1,.05,
            0,0,0,0,
        },
        min = {
            4,.01,0,1,
            0,-2,.005,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            60,.2,2,20,
            3,2,.2,2,
            1,1,1,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Grid_Density    = u_UserData0[0][0];
float Line_Width      = u_UserData0[0][1];
float Line_Brightness = u_UserData0[0][2];
float Edge_Sharpness  = u_UserData0[0][3];
float Edge_Brightness = u_UserData0[1][0];
float Scan_Speed      = u_UserData0[1][1];
float Scan_Width      = u_UserData0[1][2];
float Scan_Brightness = u_UserData0[1][3];
vec3  Color           = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Base_Alpha      = u_UserData0[2][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );
    float mask = src.a;

    float aX = texture2D( CoronaSampler0, UV + vec2( CoronaTexelSize.x, 0.0 ) ).a;
    float aY = texture2D( CoronaSampler0, UV + vec2( 0.0, CoronaTexelSize.y ) ).a;
    float edge = clamp( length( vec2( aX - mask, aY - mask ) ) * Edge_Sharpness, 0.0, 1.0 );

    vec2 guv = UV * Grid_Density;
    float g1 = abs( fract( guv.x ) - 0.5 );
    float g2 = abs( fract( guv.y ) - 0.5 );
    float g3 = abs( fract( ( guv.x + guv.y ) * 0.7071 ) - 0.5 );
    float gridLine = 1.0 - min( min( smoothstep( 0.0, Line_Width, g1 ), smoothstep( 0.0, Line_Width, g2 ) ), smoothstep( 0.0, Line_Width, g3 ) );

    float scanPos = fract( CoronaTotalTime * Scan_Speed );
    float scan = 1.0 - smoothstep( 0.0, Scan_Width, abs( UV.y - scanPos ) );

    float linesVisible = gridLine * mask;
    float edgeGlow = edge * mask;
    float scanGlow = scan * mask * Scan_Brightness;

    vec3 rgb = Color * ( linesVisible * Line_Brightness + edgeGlow * Edge_Brightness + scanGlow );
    float alpha = clamp( linesVisible * Line_Brightness * 0.9 + edgeGlow * Edge_Brightness * 0.9 + scanGlow + Base_Alpha * mask, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
