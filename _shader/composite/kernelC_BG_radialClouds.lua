
--[[
    https://godotshaders.com/shader/pixelated-radial-2d-clouds/
    Miaurin
    February 11, 2026

    Original needs 3 external textures (two scrolling noise layers +
    a 1D color gradient) plus never touches the object's own texture -
    Solar2D composite mode caps at 2. paint1 = color_gradient (real,
    author-specific artwork - kept as-is), paint2 = one real scrolling
    noise texture (cloud_noise1). The second noise layer (cloud_noise2)
    is generated procedurally instead of sampled, using the same
    hash-based value noise this bank already uses elsewhere (Fire2D,
    TorchFlame) - a second generic noise texture doesn't carry any
    author-specific content worth requiring a texture slot for.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "BG"
kernel.name = "radialClouds"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Pixelation_X','Pixelation_Y','Scroll_Speed1_X','Scroll_Speed1_Y',
            'Scroll_Speed2_X','Scroll_Speed2_Y','Center_Pos_X','Center_Pos_Y',
            'Position_Impact','','','',
            '','','','',
        },
        default = { 256,256,.02,.007,  -.015,-.004,.5,0,  .75,0,0,0,  0,0,0,0, },
        min =     { 16,16,-.2,-.2,     -.2,-.2,0,0,        0,0,0,0,   0,0,0,0, },
        max =     { 512,512,.2,.2,     .2,.2,1,1,          1,1,1,1,   1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

vec2  Pixelation      = vec2( u_UserData0[0][0], u_UserData0[0][1] );
vec2  Scroll_Speed1    = vec2( u_UserData0[0][2], u_UserData0[0][3] );
vec2  Scroll_Speed2    = vec2( u_UserData0[1][0], u_UserData0[1][1] );
vec2  Center_Pos       = vec2( u_UserData0[1][2], u_UserData0[1][3] );
float Position_Impact  = u_UserData0[2][0];

float TIME = CoronaTotalTime;

//----------------------------------------------

float hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash( i );
    float b = hash( i + vec2( 1.0, 0.0 ) );
    float c = hash( i + vec2( 0.0, 1.0 ) );
    float d = hash( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( a, b, u.x ) + ( c - a ) * u.y * ( 1.0 - u.x ) + ( d - b ) * u.x * u.y;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 pixel_uv = floor( UV * Pixelation ) / Pixelation;

    vec2 noise_uv_scale = pixel_uv;
    noise_uv_scale.x *= Pixelation.x / Pixelation.y;

    vec2 noise1uv = fract( noise_uv_scale + TIME * Scroll_Speed1 );
    vec2 noise2uv = fract( noise_uv_scale + TIME * Scroll_Speed2 );

    vec4 noise_col = ( texture2D( CoronaSampler1, noise1uv ) + vec4( valueNoise( noise2uv * 8.0 ) ) ) * 0.5;

    float dist = distance( pixel_uv, Center_Pos );
    vec2 furthest = vec2( -min( sign( Center_Pos.x - 0.5 ), 0.0 ), -min( sign( Center_Pos.y - 0.5 ), 0.0 ) );
    float max_dist = distance( Center_Pos, furthest );
    dist /= max_dist;

    float final = mix( 1.0 - noise_col.r, dist, Position_Impact );

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, vec2( final, final ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

