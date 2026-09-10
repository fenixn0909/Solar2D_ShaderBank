
--[[
    Original implementation for this bank. Rising ember/spark particles
    via a single hashed-cell lookup per depth layer (no per-particle loop
    over individual sparks - each layer is one cheap tiled lookup, same
    "single-tap hashed cell" approach this batch already uses for bubbles
    in kernelF_UI_liquidFillWave.lua) rather than an actual particle
    system, so it's a drop-in generator instead of something that needs a
    ParticleSystem/emitter set up. Three fixed depth layers scroll upward
    at different speeds/scales/sizes to sell parallax depth cheaply.

    Pure generator, transparent background - overlay on a campfire, forge,
    burning building, or torch for rising embers/ash. Aspect_Ratio
    convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "emberDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Density','Density_Threshold','Rise_Speed','Wobble_Amount',
            'Wobble_Speed','Size','Color_R','Color_G',
            'Color_B','Brightness','Seed','Aspect_Ratio',
            '','','','',
        },
        default = {
            6,.12,1,.06,
            1.5,1,1,.55,
            .15,1.2,0,1,
            0,0,0,0,
        },
        min = {
            1,0,-3,0,
            0,.2,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            20,1,3,.3,
            5,3,1,1,
            1,3,50,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Density           = u_UserData0[0][0];
float Density_Threshold = u_UserData0[0][1];
float Rise_Speed        = u_UserData0[0][2];
float Wobble_Amount     = u_UserData0[0][3];
float Wobble_Speed      = u_UserData0[1][0];
float Size              = u_UserData0[1][1];
vec3  Color             = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Brightness        = u_UserData0[2][1];
float Seed              = u_UserData0[2][2];
float Aspect_Ratio      = u_UserData0[2][3];

const int EMBER_LAYERS = 3;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

float emberLayer( vec2 uv, float layerIndex )
{
    float speed = Rise_Speed * ( 0.6 + layerIndex * 0.35 );
    float scale = Density * ( 1.0 + layerIndex * 0.4 );

    vec2 scrolled = vec2( uv.x * scale, ( uv.y + CoronaTotalTime * speed * 0.15 ) * scale );
    vec2 cell = floor( scrolled );
    vec2 localUV = fract( scrolled ) - 0.5;

    float hA = hash1( dot( cell, vec2( 15.23, 71.19 ) ) + layerIndex * 37.0 + Seed * 11.0 );
    float hB = hash1( dot( cell, vec2( 91.7, 13.3 ) ) + layerIndex * 17.0 + Seed * 11.0 );

    localUV.x += sin( CoronaTotalTime * Wobble_Speed + hA * 20.0 ) * Wobble_Amount;

    float size = mix( 0.05, 0.22, hB ) * Size;
    float dist = length( localUV );
    float dotShape = 1.0 - smoothstep( size * 0.3, size, dist );

    float visible = step( 1.0 - Density_Threshold, hA );
    float twinkle = 0.5 + 0.5 * sin( CoronaTotalTime * ( 3.0 + hB * 4.0 ) + hA * 30.0 );

    return dotShape * visible * twinkle;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float total = 0.0;
    for ( int layerIndex = 0; layerIndex < EMBER_LAYERS; layerIndex++ ) {
        total += emberLayer( uv, float( layerIndex ) );
    }
    total = clamp( total, 0.0, 1.0 );

    vec3 rgb = Color * total * Brightness;
    float alpha = clamp( total * Brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
