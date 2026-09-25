--[[
    https://godotshaders.com/shader/color-cycling-hit-effect/
    rasmus, May 18, 2023

    Hit-flash palette cycler.
    Fixed: brightness was measured from an all-zero COLOR (so the frame
    offset never triggered) and Mix_Ratio was overridden by
    abs(sin(TIME))*Mix every frame. Now brightness comes from the
    sprite, Speed auto-advances the palette (0 = hold Frame), and
    Process fades original -> cycled.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "cycling"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Process",   default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Speed",     default = 2,   min = 0, max = 10,  index = 1, },
  { name = "Frame",     default = 0,   min = 0, max = 100, index = 2, },
  { name = "Mix_Ratio", default = 0.42, min = 0, max = 1,  index = 3, },
}

kernel.fragment =
[[

int modi_cyc( int a, int b ){ return a - ( a / b ) * b; }

vec3 palette_cyc( int i )
{
    if ( i == 0 ) return vec3( 1.0, 0.0, 0.0 );
    if ( i == 1 ) return vec3( 0.5, 0.0, 0.0 );
    if ( i == 2 ) return vec3( 0.0, 0.0, 0.0 );
    if ( i == 3 ) return vec3( 0.0, 1.0, 1.0 );
    if ( i == 4 ) return vec3( 0.0, 0.5, 0.8 );
    return vec3( 1.0, 1.0, 0.0 );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Process  = CoronaVertexUserData.x;
    float Speed    = CoronaVertexUserData.y;
    float Frame    = CoronaVertexUserData.z;
    float MixRatio = CoronaVertexUserData.w;

    vec4 tex = texture2D( CoronaSampler0, UV );

    float brightness = dot( tex.rgb, vec3( 0.2126, 0.7152, 0.0722 ) );

    int offset = 0;
    if ( brightness > 0.75 ) { offset = 2; }
    else if ( brightness > 0.25 ) { offset = 1; }

    int frameEff = int( Frame + 0.5 ) + int( floor( CoronaTotalTime * Speed ) );
    int color_index = modi_cyc( frameEff + offset, 6 );
    vec3 color = palette_cyc( color_index );

    vec3 cycled = mix( tex.rgb, color * tex.a, clamp( MixRatio, 0.0, 1.0 ) );
    vec3 col = mix( tex.rgb, cycled, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( col, tex.a );
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]


return kernel




--[[



--]]
