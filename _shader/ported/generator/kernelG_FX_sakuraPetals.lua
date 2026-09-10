
--[[
    Original implementation for this bank. Reuses the same layered
    hashed-cell-per-depth approach as this batch's kernelG_FX_emberDrift.lua
    (three scrolling layers for cheap parallax, no per-particle loop) but
    swaps the isotropic dot for an elongated, continuously-rotating
    ellipse (`length(rotated_local * vec2(1, k))` for k > 1, same
    anisotropic-distance trick as kernelG_FX_sandstormDrift.lua's streaks)
    so each speck reads as a tumbling petal rather than a round mote, and
    a per-petal rotation angle driven by its own hashed spin rate sells
    the "falling leaf" tumble.

    Pure generator, transparent background - overlay for a sakura tree
    scene, a spring festival level, or a slow-motion petals-on-wind beat.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "sakuraPetals"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Fall_Speed','Density','Sway_Amount','Sway_Speed',
            'Spin_Speed','Size','Color_R','Color_G',
            'Color_B','Highlight_Amount','Threshold','Aspect_Ratio',
            '','','','',
        },
        default = {
            .35,3.5,.12,.6,
            2,1,1,.75,
            .85,.4,.35,1,
            0,0,0,0,
        },
        min = {
            0,.5,0,0,
            0,.2,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            2,10,.4,3,
            8,3,1,1,
            1,1,1,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Fall_Speed       = u_UserData0[0][0];
float Density          = u_UserData0[0][1];
float Sway_Amount      = u_UserData0[0][2];
float Sway_Speed       = u_UserData0[0][3];
float Spin_Speed       = u_UserData0[1][0];
float Size             = u_UserData0[1][1];
vec3  Color            = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Highlight_Amount = u_UserData0[2][1];
float Threshold        = u_UserData0[2][2];
float Aspect_Ratio     = u_UserData0[2][3];

const int PETAL_LAYERS = 3;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

float petalLayer( vec2 uv, float layerIndex )
{
    float speed = Fall_Speed * ( 0.6 + layerIndex * 0.3 );
    float scale = Density * ( 1.0 + layerIndex * 0.3 );

    float sway = sin( CoronaTotalTime * Sway_Speed + uv.y * 4.0 + layerIndex * 2.0 ) * Sway_Amount;
    vec2 scrolled = vec2( ( uv.x + sway - CoronaTotalTime * speed * 0.05 ) * scale, ( uv.y - CoronaTotalTime * speed * 0.12 ) * scale );

    vec2 cell = floor( scrolled );
    vec2 localUV = fract( scrolled ) - 0.5;

    float hA = hash1( dot( cell, vec2( 15.23, 71.19 ) ) + layerIndex * 37.0 );
    float hB = hash1( dot( cell, vec2( 91.7, 13.3 ) ) + layerIndex * 17.0 );

    float spin = CoronaTotalTime * Spin_Speed * ( 0.5 + hA ) + hB * 6.28318;
    float cs = cos( spin );
    float sn = sin( spin );
    vec2 rotated = vec2( localUV.x * cs - localUV.y * sn, localUV.x * sn + localUV.y * cs );

    float size = mix( 0.08, 0.22, hB ) * Size;
    float dist = length( rotated * vec2( 1.0, 2.6 ) );
    float petal = 1.0 - smoothstep( size * 0.5, size, dist );

    float visible = step( 1.0 - Threshold, hA );
    float shade = 0.7 + 0.3 * sin( spin * 2.0 );

    return petal * visible * shade;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float total = 0.0;
    for ( int layerIndex = 0; layerIndex < PETAL_LAYERS; layerIndex++ ) {
        total += petalLayer( uv, float( layerIndex ) );
    }
    total = clamp( total, 0.0, 1.0 );

    vec3 rgb = mix( Color, vec3( 1.0 ), total * Highlight_Amount * 0.4 ) * total;

    P_COLOR vec4 COLOR = vec4( rgb, total );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
