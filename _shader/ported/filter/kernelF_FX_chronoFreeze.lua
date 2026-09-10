
--[[
    Original implementation for this bank. A "time stop" treatment built
    from three independent, additively combined pieces: a desaturate-
    toward-a-cool-tint pass (the color side of the effect), a faceted
    low-poly shading pass (nearest-point Voronoi, cell ID hashed straight
    to a brightness multiplier rather than compared for F2-F1 borders -
    simpler than this batch's other Voronoi-based kernels since only a
    flat per-facet shade is needed, not a border line), and a fixed
    number of straight crack lines radiating from Freeze_Origin at random
    hashed angles/reaches (an angular take on the "distance to a line"
    idea this batch already uses for bolts/tears, but measuring angular
    rather than perpendicular distance from a point).

    Unlike this bank's existing kernelF_FX_frostbite.lua - which grows
    organic Voronoi ice cracks inward from the screen *edges* over an
    implied time axis - this is centered on a settable origin point and
    driven by a single Freeze_Amount (0-1) meant to snap on/off instantly
    for a "moment frozen in time" beat rather than a spreading effect.
    Single-texture filter.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "chronoFreeze"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Freeze_Amount','Desaturate_Amount','Tint_R','Tint_G',
            'Tint_B','Facet_Scale','Freeze_Origin_X','Freeze_Origin_Y',
            'Crack_Width','','','',
            '','','','',
        },
        default = {
            1,.7,.75,.88,
            1,18,.5,.5,
            .035,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,3,0,0,
            .005,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            1,40,1,1,
            .15,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Freeze_Amount     = u_UserData0[0][0];
float Desaturate_Amount = u_UserData0[0][1];
vec3  Tint_Color        = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Facet_Scale       = u_UserData0[1][1];
vec2  Freeze_Origin     = vec2( u_UserData0[1][2], u_UserData0[1][3] );
float Crack_Width       = u_UserData0[2][0];

const int CRACK_DIRS = 8;
const float TAU = 6.28318530718;
const float PI = 3.14159265359;

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
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float lum = dot( src.rgb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 desat = mix( src.rgb, vec3( lum ) * Tint_Color * 1.4, Desaturate_Amount );

    vec2 p = UV * Facet_Scale;
    vec2 cellId = floor( p );
    vec2 localP = fract( p );
    float f1 = 8.0;
    vec2 bestCell = cellId;

    for ( int y = -1; y <= 1; y++ ) {
        for ( int x = -1; x <= 1; x++ ) {
            vec2 neighbor = vec2( float( x ), float( y ) );
            vec2 point = hash22( cellId + neighbor );
            float dist = length( neighbor + point - localP );
            if ( dist < f1 ) {
                f1 = dist;
                bestCell = cellId + neighbor;
            }
        }
    }
    float facetShade = hash1( dot( bestCell, vec2( 41.3, 17.7 ) ) ) * 0.3 + 0.85;

    vec2 toPixel = UV - Freeze_Origin;
    float distFromOrigin = length( toPixel );
    float angFromOrigin = atan( toPixel.y, toPixel.x );

    float crackMask = 0.0;
    for ( int dirIndex = 0; dirIndex < CRACK_DIRS; dirIndex++ ) {
        float fi = float( dirIndex );
        float baseAngle = fi / float( CRACK_DIRS ) * TAU + hash1( fi * 3.7 ) * 0.3;
        float angDiff = abs( mod( angFromOrigin - baseAngle + PI, TAU ) - PI );
        float reach = 0.15 + hash1( fi * 5.1 + 2.0 ) * 0.35;
        float visible = 1.0 - smoothstep( reach, reach + 0.05, distFromOrigin );
        float line = ( 1.0 - smoothstep( 0.0, Crack_Width, angDiff ) ) * visible;
        crackMask = max( crackMask, line );
    }

    vec3 faceted = desat * facetShade;
    vec3 iced = mix( faceted, vec3( 1.0 ), crackMask * 0.8 );

    vec3 rgb = mix( src.rgb, iced, Freeze_Amount );

    P_COLOR vec4 COLOR = vec4( rgb, src.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
