
--[[
    https://godotshaders.com/shader/2d-burn-dissolve-from-point-v-1-0/
    enekoassets
    February 21, 2025

    Port of the burn/disc logic: distance from Epicenter plus a noise
    wobble, sprite turns to Burn_Color inside radius + Border_Width
    and goes transparent inside radius - animate Radius 0 -> 2 for a
    full burn (the post's own GDScript drives it exactly that way).

    One substitution: the original samples a caller-supplied
    noiseTexture (.b channel); Solar2D filter kernels only get the
    object's own texture, so the wobble comes from a small procedural
    value-noise instead (same approach as this bank's Fire2D/TorchFlame
    ports) - Noise_Scale sets its frequency, Noise_Strength matches
    the original's burnMult. Aspect_Ratio keeps the burn circular on
    non-square rects (original measures raw UV distance, so it comes
    out elliptical there).

    CC0.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "burnFromPoint"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Epicenter_X','Epicenter_Y','Radius','Border_Width',
            'Noise_Scale','Noise_Strength','Aspect_Ratio','',
            '','','','',
            '','','','',
        },
        default = {
            .5,.5,.15,.06,
            6,.135,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            1,0,.2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,2,.3,
            16,.5,5,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Burn_R','Burn_G','Burn_B','Burn_A',
            '','','','',
            '','','','',
            '','','','',
        },
        default = {
            1,.32,.04,1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            2,2,2,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
//----------------------------------------------

vec2  Epicenter      = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Radius         = u_UserData0[0][2];
float Border_Width   = u_UserData0[0][3];
float Noise_Scale    = u_UserData0[1][0];
float Noise_Strength = u_UserData0[1][1];
float Aspect_Ratio   = u_UserData0[1][2];

vec4 Burn_Color = vec4( u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2], u_UserData1[0][3] );

//----------------------------------------------

P_RANDOM float burn_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float burn_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( burn_hash( i ), burn_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( burn_hash( i + vec2( 0.0, 1.0 ) ), burn_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 aspectVec = vec2( 1.0, Aspect_Ratio );
    float dist = length( ( Epicenter - UV ) * aspectVec )
               + burn_noise( UV * Noise_Scale ) * Noise_Strength;

    float burned = 1.0 - step( Radius, dist );
    float ring = ( 1.0 - step( Radius + Border_Width, dist ) ) - burned;

    vec3 finalRGB = mix( tex.rgb, Burn_Color.rgb, clamp( burned + ring, 0.0, 1.0 ) * Burn_Color.a );
    float finalAlpha = tex.a * ( 1.0 - burned );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
