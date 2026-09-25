
--[[
    Original implementation for this bank. Reuses the standard Voronoi
    F1/F2 cell technique this batch already applies in
    kernelG_FX_moltenCracks.lua (see that file's header for the technique
    note) but aimed at a different result entirely: instead of glowing
    crack veins, each cell samples CoronaSampler0 once at its own jittered
    site (not the pixel's own UV) to get one flat color per pane, a thick
    dark "leading" line is drawn at the cell borders (f2-f1 near zero)
    the way real lead came separates stained-glass pieces, and a small
    per-cell brightness jitter keeps every pane from reading as an exact
    flat-color clone of its neighbours. The final alpha still comes from
    the pixel's own true UV sample rather than the jittered cell sample,
    so the overall silhouette stays accurate even though each pane's
    color is a small area average taken from elsewhere in the sprite.

    Single-texture filter. No Aspect_Ratio correction on the cell shape
    (real stained-glass panes are irregular anyway, so slight stretching
    on non-square sprites reads as part of the style rather than a flaw).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "stainedGlassMosaic"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Cell_Scale','Leading_Width','Leading_Color_R','Leading_Color_G',
            'Leading_Color_B','Color_Variation','Brightness','',
            '','','','',
            '','','','',
        },
        default = {
            14,.15,.05,.04,
            .03,.35,1.1,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            3,.02,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            200,.4,1,1,
            1,1,2,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cell_Scale     = u_UserData0[0][0];
float Leading_Width  = u_UserData0[0][1];
vec3  Leading_Color  = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Color_Variation= u_UserData0[1][1];
float Brightness     = u_UserData0[1][2];

const int SEARCH_R = 1;

P_RANDOM vec2 hash22( vec2 p )
{
    vec2 q = vec2( dot( p, vec2( 127.1, 311.7 ) ), dot( p, vec2( 269.5, 183.3 ) ) );
    return fract( sin( q ) * 43758.5453123 );
}

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p = UV * Cell_Scale;
    vec2 cellId = floor( p );
    vec2 localP = fract( p );

    float f1 = 8.0;
    float f2 = 8.0;
    vec2 bestNeighbor = vec2( 0.0 );
    vec2 bestPoint = vec2( 0.0 );

    for ( int y = -SEARCH_R; y <= SEARCH_R; y++ ) {
        for ( int x = -SEARCH_R; x <= SEARCH_R; x++ ) {
            vec2 neighbor = vec2( float( x ), float( y ) );
            vec2 point = hash22( cellId + neighbor );
            vec2 diff = neighbor + point - localP;
            float dist = length( diff );
            if ( dist < f1 ) {
                f2 = f1;
                f1 = dist;
                bestNeighbor = neighbor;
                bestPoint = point;
            } else if ( dist < f2 ) {
                f2 = dist;
            }
        }
    }

    vec2 sampleUV = clamp( ( cellId + bestNeighbor + bestPoint ) / Cell_Scale, 0.0, 1.0 );
    P_COLOR vec4 cellColor = texture2D( CoronaSampler0, sampleUV );
    P_COLOR vec4 localSrc = texture2D( CoronaSampler0, UV );

    float mortarMask = 1.0 - smoothstep( 0.0, Leading_Width, f2 - f1 );

    float jitter = hash1( dot( cellId + bestNeighbor, vec2( 41.3, 289.1 ) ) );
    vec3 tinted = cellColor.rgb * mix( 1.0 - Color_Variation * 0.5, 1.0 + Color_Variation * 0.5, jitter ) * Brightness;

    vec3 rgb = mix( tinted, Leading_Color, mortarMask );
    float alpha = localSrc.a;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
