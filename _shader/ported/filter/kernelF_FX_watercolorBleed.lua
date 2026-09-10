
--[[
    Original implementation for this bank. Two independent, well-known
    ingredients: noise-displaced UV sampling for the organic wobbly edge
    real watercolor washes have (rather than a crisp vector silhouette),
    and an "edge pooling" darken/tint pass using the same alpha-vs-
    neighbours edge measurement this bank's other outline-adjacent kernels
    use (e.g. kernelF_UI_rarityGlow.lua) - watercolor pigment visibly
    concentrates where a wet wash dries at its boundary, and this
    reproduces that same visual cue rather than a flat, evenly-tinted
    edge. A cheap value-noise paper grain rounds it out.

    Single-texture filter, works on any sprite.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "watercolorBleed"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Bleed_Amount','Bleed_Scale','Pool_Strength','Pool_Color_R',
            'Pool_Color_G','Pool_Color_B','Grain_Amount','Edge_Width',
            '','','','',
            '','','','',
        },
        default = {
            .012,6,.5,.25,
            .2,.35,.25,2,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,1,0,0,
            0,0,0,.5,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            .05,20,1,1,
            1,1,1,6,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Bleed_Amount = u_UserData0[0][0];
float Bleed_Scale  = u_UserData0[0][1];
float Pool_Strength= u_UserData0[0][2];
vec3  Pool_Color   = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Grain_Amount = u_UserData0[1][2];
float Edge_Width   = u_UserData0[1][3];

P_RANDOM float hash21( vec2 p )
{
    p = fract( p * vec2( 123.34, 456.21 ) );
    p += dot( p, p + 45.32 );
    return fract( p.x * p.y );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash21( i );
    float b = hash21( i + vec2( 1.0, 0.0 ) );
    float c = hash21( i + vec2( 0.0, 1.0 ) );
    float d = hash21( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( a, b, u.x ), mix( c, d, u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 noiseOffset = vec2( valueNoise( UV * Bleed_Scale + 7.0 ), valueNoise( UV * Bleed_Scale + 19.0 ) ) - 0.5;
    vec2 distortedUV = UV + noiseOffset * Bleed_Amount;
    P_COLOR vec4 src = texture2D( CoronaSampler0, distortedUV );

    vec2 offs = CoronaTexelSize.xy * Edge_Width;
    float aXp = texture2D( CoronaSampler0, distortedUV + vec2( offs.x, 0.0 ) ).a;
    float aXn = texture2D( CoronaSampler0, distortedUV - vec2( offs.x, 0.0 ) ).a;
    float aYp = texture2D( CoronaSampler0, distortedUV + vec2( 0.0, offs.y ) ).a;
    float aYn = texture2D( CoronaSampler0, distortedUV - vec2( 0.0, offs.y ) ).a;
    float minNeighbor = min( min( aXp, aXn ), min( aYp, aYn ) );
    float edgePool = clamp( ( src.a - minNeighbor ) * 2.0, 0.0, 1.0 ) * Pool_Strength;

    vec3 pooled = mix( src.rgb, src.rgb * Pool_Color + Pool_Color * 0.15, edgePool );

    float paperGrain = valueNoise( UV * 300.0 );
    vec3 withGrain = pooled * mix( 1.0 - Grain_Amount * 0.5, 1.0 + Grain_Amount * 0.5, paperGrain );

    P_COLOR vec4 COLOR = vec4( withGrain, src.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
