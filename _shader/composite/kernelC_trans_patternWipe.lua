
--[[
    https://godotshaders.com/shader/transition-shader-with-patterns/
    binbun
    February 9, 2026

    paint1 = gradient_texture (a greyscale gradient defining the wipe
    direction/shape - directional, radial, circular, whatever the
    texture encodes), paint2 = shape_texture (a tiling pattern/noise
    texture that gives the wipe edge its "shape"). Outputs alpha only
    (RGB is always black), matching the original exactly - meant as a
    reveal mask, composite it with a color fill or your outgoing scene.
    node_resolution auto-computed from CoronaTexelSize.zw instead of
    needing manual sync.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "trans"
kernel.name = "patternWipe"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Base_Color_R','Base_Color_G','Base_Color_B','Base_Color_A',
            'Factor','Width','Gradient_Fixed','Shape_Tiling',
            'Shape_Rotation','Shape_Scroll_X','Shape_Scroll_Y','Shape_Feathering',
            'Shape_Treshold','','','',
        },
        default = { 0,0,0,1,  .54,.4,0,32,  0,0,0,0,  1,0,0,0, },
        min =     { 0,0,0,0,  0,0,0,1,      0,-2,-2,0, 0,0,0,0, },
        max =     { 1,1,1,1,  1,2,1,64,     360,2,2,1, 2,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

vec4  Base_Color        = vec4( u_UserData0[0][0], u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3] );
float Factor              = u_UserData0[1][0];
float Width                = u_UserData0[1][1];
float Gradient_Fixed      = u_UserData0[1][2];
float Shape_Tiling        = u_UserData0[1][3];
float Shape_Rotation      = u_UserData0[2][0];
vec2  Shape_Scroll         = vec2( u_UserData0[2][1], u_UserData0[2][2] );
float Shape_Feathering    = u_UserData0[2][3];
float Shape_Treshold      = u_UserData0[3][0];

vec2 node_resolution = CoronaTexelSize.zw;
float TIME = CoronaTotalTime;

//----------------------------------------------

float gradientVal( vec2 uv, vec2 fixed_uv, bool isFixed )
{
    float value = 0.0;
    if ( isFixed ) {
        value = texture2D( CoronaSampler0, fixed_uv ).r;
    } else {
        value = texture2D( CoronaSampler0, uv ).r;
    }
    return value;
}

vec2 rotateUV( vec2 uv, vec2 pivot, float angle )
{
    mat2 rotation = mat2( vec2( sin( angle ), -cos( angle ) ),
                        vec2( cos( angle ), sin( angle ) ) );
    uv -= pivot;
    uv = uv * rotation;
    uv += pivot;
    return uv;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float progress = mix( -Width, 1.0, Factor );
    float aspect = node_resolution.y / node_resolution.x;

    vec2 aspect_uv = ( ( UV - vec2( 0.0, 0.5 ) ) * vec2( 1.0, aspect ) ) + vec2( 0.0, 0.5 );

    float value = clamp( ( gradientVal( UV, aspect_uv, Gradient_Fixed > 0.5 ) - progress ) / ( Width ), 0.0, 1.0 );

    vec2 tiled_uv = rotateUV( mod( ( aspect_uv + vec2( TIME ) * Shape_Scroll ) * Shape_Tiling, 1.0 ), vec2( 0.5 ), radians( Shape_Rotation ) );
    float shape_value = 1.0 - texture2D( CoronaSampler1, tiled_uv ).r;

    shape_value = mix( Shape_Feathering * 0.5, 1.0 - Shape_Feathering * 0.5, shape_value );
    float shaped_gradient = smoothstep( value - ( Shape_Feathering * 0.5 ), value + ( Shape_Feathering * 0.5 ), Shape_Treshold - shape_value );

    P_COLOR vec4 COLOR = Base_Color;
    COLOR.a = shaped_gradient;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

