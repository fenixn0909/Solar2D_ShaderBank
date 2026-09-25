--[[
  https://godotshaders.com/shader/screentone-black-spaced-pixels/
  Exuin, January 24, 2021

  Manga screentone: dark pixels in a Bayer grid, density follows
  brightness.
  Rebuilt: the old bool[16] array constructor is GLSL-ES-3.0-only (never
  compiled on mobile = dead shader) and its one param did nothing. Now
  a branchless 4x4 Bayer dither with fun slots: Process (1st), Cell
  (screentone dot size in px), Cutoff (density shift), Invert.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "blackSpacePixel"

kernel.isTimeDependent = false

kernel.vertexData =
{
  { name = "Process", default = 1,   min = 0, max = 1, index = 0, },
  { name = "Cell",    default = 1,   min = 1, max = 8, index = 1, },
  { name = "Cutoff",  default = 0,   min = -1, max = 1, index = 2, },
  { name = "Invert",  default = 0,   min = 0, max = 1, index = 3, },
}

kernel.fragment =
[[

P_COLOR vec3 color_light = vec3( 0.5, 0.5, 1.0 );
P_COLOR vec3 color_dark = vec3( 0.0, 0.0, 0.3 );

// 4x4 Bayer matrix without any array constructor (GLES2-safe)
float bayer4_bsp( vec2 p )
{
    vec2 ip = mod( floor( p ), 4.0 );
    float idx = ip.x + ip.y * 4.0;
    if ( idx < 0.5 ) return 0.0;
    if ( idx < 1.5 ) return 8.0;
    if ( idx < 2.5 ) return 2.0;
    if ( idx < 3.5 ) return 10.0;
    if ( idx < 4.5 ) return 12.0;
    if ( idx < 5.5 ) return 4.0;
    if ( idx < 6.5 ) return 14.0;
    if ( idx < 7.5 ) return 6.0;
    if ( idx < 8.5 ) return 3.0;
    if ( idx < 9.5 ) return 11.0;
    if ( idx < 10.5 ) return 1.0;
    if ( idx < 11.5 ) return 9.0;
    if ( idx < 12.5 ) return 15.0;
    if ( idx < 13.5 ) return 7.0;
    if ( idx < 14.5 ) return 13.0;
    return 5.0;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Process = CoronaVertexUserData.x;
    float Cell    = CoronaVertexUserData.y;
    float Cutoff  = CoronaVertexUserData.z;
    float Invert  = CoronaVertexUserData.w;

    vec2 pixel = UV / CoronaTexelSize.zw;
    vec2 cellUV = ( floor( pixel / max( Cell, 1.0 ) ) + vec2( 0.5 ) )
                * max( Cell, 1.0 ) * CoronaTexelSize.zw;
    vec4 cur = texture2D( CoronaSampler0, cellUV );

    float ta = max( cur.a, 0.001 );
    float lum = dot( cur.rgb / ta, vec3( 0.299, 0.587, 0.114 ) );
    float threshold = ( bayer4_bsp( pixel / max( Cell, 1.0 ) ) + 0.5 ) / 16.0;

    // lum in 0..1 vs threshold 0..1, shifted by Cutoff
    float on = step( threshold, clamp( lum + Cutoff * 0.5, 0.0, 1.0 ) );
    on = mix( on, 1.0 - on, clamp( Invert, 0.0, 1.0 ) );

    // keep the sprite's own colors on lit cells, navy screentone elsewhere
    vec3 lit = cur.rgb;
    vec3 dark = color_dark * cur.a;
    vec3 col = mix( dark, lit, on );
    col = mix( cur.rgb, col, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( col, cur.a );
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[


--]]
