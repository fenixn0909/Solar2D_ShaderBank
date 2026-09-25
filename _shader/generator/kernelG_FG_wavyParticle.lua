--[[
    https://godotshaders.com/shader/waving-particles/
    Steampunkdemon, July 22, 2023

    Drifting grid of soft wavy particles (now a generator: needs no
    source image, draws its own field).
    Rebuilt: the old r/g/b/size sliders were never read (colors and
    sizes were hardcoded). Now Count (grid density), Size, Speed and
    Wave are all live.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FG"
kernel.name = "wavyParticle"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Count", default = 8,   min = 2,  max = 20, index = 0, },
  { name = "Size",  default = 0.5, min = 0.1, max = 1, index = 1, },
  { name = "Speed", default = 1,   min = 0,  max = 3,  index = 2, },
  { name = "Wave",  default = 0.6, min = 0,  max = 1,  index = 3, },
}

kernel.fragment =
[[

uniform vec2 dimensions = vec2(600, 300.0); // grid aspect reference

uniform float vertical_scroll = 0.5;
uniform float horizontal_scroll = 0.1;
uniform float wave_rotation = 1.0;

uniform vec4 far_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 near_color = vec4(1.0, 1.0, 1.0, 1.0);

P_DEFAULT float PI = 3.14159265359;
P_COLOR vec4 bg_color = vec4(0.0, 0.0, 0.0, 0.0);

P_DEFAULT float TIME = CoronaTotalTime;

// ----------------------------------------------------------------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Count = CoronaVertexUserData.x;
    float Size  = CoronaVertexUserData.y;
    float Speed = CoronaVertexUserData.z;
    float Wave  = CoronaVertexUserData.w;

    float rows = clamp( Count, 2.0, 20.0 );
    float columns = clamp( Count, 2.0, 20.0 );
    float size_min = Size * 0.4;
    float size_max = Size;
    float wave_speed = Speed * 0.1;
    float wave_min = 0.1;
    float wave_max = max( Wave, 0.05 );

    P_COLOR vec4 COLOR = bg_color;

    float time = 10000.0 + TIME * ( 0.25 + Speed );

    float row_rn = fract( sin( floor( ( UV.y - vertical_scroll * time ) * rows ) ) );
    float column_rn = fract( sin( floor( ( UV.x + row_rn - horizontal_scroll * time ) * columns ) ) );
    float wave = sin( wave_speed * time + column_rn * 90.0 );
    vec2 uv = ( vec2( fract( ( UV.x + row_rn - horizontal_scroll * time + ( wave * ( wave_min + ( wave_max - wave_min ) * column_rn ) / columns / 2.0 ) ) * columns ), fract( ( UV.y - vertical_scroll * time ) * rows ) ) * 2.0 - 1.0 ) * vec2( dimensions.x / dimensions.y * rows / columns, 1.0 );
    float size = size_min + ( size_max - size_min ) * column_rn;
    vec4 color = mix( far_color, near_color, column_rn );

    float a = ( ( column_rn + wave ) * wave_rotation ) * PI;
    uv *= mat2( vec2( sin( a ), -cos( a ) ), vec2( cos( a ), sin( a ) ) );

    // soft-edge circles
    COLOR.rgb = mix( COLOR.rgb, color.rgb, max( ( size - length( uv ) ) / size, 0.0 ) * color.a );
    COLOR.a = max( COLOR.a, max( ( size - length( uv ) ) / size, 0.0 ) * color.a );

// ----------------------------------------------------------------------------------------------------

    return CoronaColorScale( COLOR );
}
]]
return kernel
--[[



--]]
