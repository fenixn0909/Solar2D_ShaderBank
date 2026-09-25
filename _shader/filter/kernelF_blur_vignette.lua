--[[
    Blur Vignette (Post Processing / ColorRect) [Godot 4.2.1]
    https://godotshaders.com/shader/blur-vignette-post-processing-colorrect-godot-4-2-1/
    paitorocxon Dec 29, 2023
    Fixed (round 2): the lod-bias blur `texture2D(s, uv, bias)` needs
    mipmaps (sprites have none) so corners never blurred = looked dead.
    Now uses an explicit 8-tap ring blur that always works. Radius was
    folded into the ring, freeing a slot for Process (sharp -> vignette).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "vignette"

kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Blur_Amount','Inner','Outer',
            'Feather','','','',
            '','','','',
            '','','','',
        },
        default = {
            1,5,0.45,0.75,
            0.25,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0.01,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,10,1,1.2,
            0.6,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Process     = u_UserData0[0][0];
float Blur_Amount = u_UserData0[0][1];
float Inner       = u_UserData0[0][2];
float Outer       = u_UserData0[0][3];
float Feather     = u_UserData0[1][0];

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec4 sharp = texture2D( CoronaSampler0, UV );

    // explicit ring blur: works with or without mipmaps
    vec2 px = CoronaTexelSize.zw * Blur_Amount * 1.5;
    vec3 acc = sharp.rgb;
    acc += texture2D( CoronaSampler0, UV + vec2( px.x, 0.0 ) ).rgb;
    acc += texture2D( CoronaSampler0, UV - vec2( px.x, 0.0 ) ).rgb;
    acc += texture2D( CoronaSampler0, UV + vec2( 0.0, px.y ) ).rgb;
    acc += texture2D( CoronaSampler0, UV - vec2( 0.0, px.y ) ).rgb;
    acc += texture2D( CoronaSampler0, UV + px ).rgb;
    acc += texture2D( CoronaSampler0, UV - px ).rgb;
    acc += texture2D( CoronaSampler0, UV + vec2( px.x, -px.y ) ).rgb;
    acc += texture2D( CoronaSampler0, UV + vec2( -px.x, px.y ) ).rgb;
    vec3 blurred = acc / 9.0;

    float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
    float dist = length( ( UV - vec2( 0.5 ) ) * vec2( aspect, 1.0 ) );

    float outer = max( Outer, Inner + 0.02 );
    float m = smoothstep( max( Inner - Feather, 0.0 ), outer, dist );

    vec3 vig = mix( sharp.rgb, blurred, clamp( m, 0.0, 1.0 ) );
    vec3 col = mix( sharp.rgb, vig, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( col, sharp.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
