
--[[
    https://godotshaders.com/shader/raindrops-on-glass/
    Godot4me
    January 23, 2026

    CoronaSampler0 stands in for the original's screen capture - feed
    it a snapshot/render-to-texture (same convention as this bank's
    other screen-space shaders). Dropped blur_amount: the original
    used textureLod() to soften the refracted background, which needs
    a GLES2 extension this bank has no working precedent for elsewhere
    - rather than gamble on device support for one soft-focus knob,
    this samples directly. Everything else (two-layer raindrop
    pattern, slant, refraction, highlight tint) ported as-is.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "raindropsGlass"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Slant_Factor','Distortion_Strength','Base_Rain_Speed','Reflection_Color_R',
            'Reflection_Color_G','Reflection_Color_B','Reflection_Color_A','',
            '','','','',
            '','','','',
        },
        default = { .12,.08,.4,.6,  .4,.9,1,0,  0,0,0,0,  0,0,0,0, },
        min =     { -.5,0,.1,0,     0,0,0,0,    0,0,0,0,  0,0,0,0, },
        max =     { .5,.2,2,1,      1,1,1,1,    1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Slant_Factor        = u_UserData0[0][0];
float Distortion_Strength = u_UserData0[0][1];
float Base_Rain_Speed     = u_UserData0[0][2];
vec4  Reflection_Color     = vec4( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );

float TIME = CoronaTotalTime;

//----------------------------------------------

vec2 hash22( vec2 p )
{
    p = vec2( dot( p, vec2( 127.1, 311.7 ) ), dot( p, vec2( 269.5, 183.3 ) ) );
    return fract( sin( p ) * 43758.5453123 );
}

vec3 rain_layer( vec2 uv, float scale )
{
    vec2 grid_uv = uv * scale;
    vec2 id = floor( grid_uv );
    vec3 rnd = vec3( hash22( id ), hash22( id + vec2( 1.0 ) ).x );

    float speed_mult = mix( 0.5, 1.5, rnd.y );
    float t = TIME * Base_Rain_Speed * speed_mult;

    grid_uv.y += t;
    vec2 final_id = floor( grid_uv );
    vec2 final_uv = fract( grid_uv ) - 0.5;

    vec2 drop_rand = hash22( final_id );
    final_uv += ( drop_rand - 0.5 ) * 0.6;

    // stretch the drop shape vertically for a sense of gravity
    float d = length( final_uv * vec2( 5.0, 0.5 ) / mix( 0.4, 0.8, drop_rand.y ) );

    float drop = smoothstep( 0.2, 0.05, d );

    // small drip trail beneath each drop
    float trail = smoothstep( 0.04, 0.01, abs( final_uv.x ) ) * smoothstep( -0.1, 0.4, final_uv.y );
    float combined_mask = drop + trail * 0.3;

    return vec3( final_uv * combined_mask * Distortion_Strength, combined_mask );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = -UV;
    uv.x -= uv.y * Slant_Factor;

    vec3 layer1 = rain_layer( uv, 5.0 );
    vec3 layer2 = rain_layer( uv + vec2( 0.35 ), 11.0 ) * 0.5;
    vec3 final_effect = layer1 + layer2;

    vec2 refraction_uv = UV + final_effect.xy;
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, refraction_uv );

    // reflective tint only where the raindrop mask has coverage
    float highlight = smoothstep( 0.1, 0.5, final_effect.z );
    COLOR.rgb += highlight * Reflection_Color.rgb * 0.25;

    // faint bright rim on each drop's edge, like glass catching light
    COLOR.rgb += ( layer1.z + layer2.z ) * 0.1 * Reflection_Color.rgb;

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

