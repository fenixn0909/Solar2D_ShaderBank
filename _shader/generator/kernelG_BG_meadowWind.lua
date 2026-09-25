
--[[
    Original implementation for this bank. A fully procedural strip of
    wind-blown grass - two density layers of individually-seeded blade
    silhouettes (per-blade height/width/phase all from a per-column
    hash, no texture input), each blade bending from its base with an
    ease-in curve so the tip sways more than the root, driven by a
    per-blade phase plus a shared low-frequency "gust" term so the
    whole field ripples in waves rather than jittering uniformly. A
    sparse hash-gated fleck of flower color sits near some blade tips
    for a bit of meadow color. Transparent above the grass line so it
    layers as a foreground strip over any background.

    Checked against all existing kernels first: kernelF_wobble_
    windSway2D and kernelF_wobble_windSwayPurga both *sway an existing
    input sprite* (they warp CoronaSampler0's UVs) - a single tree/bush
    art asset bending in the wind. This is a generator: it draws its
    own complete field of blades from scratch, no input texture, meant
    as a ground-cover layer rather than a per-object effect. Not a
    re-skin of kernelG_BG_stripes/waveForms either - blade shape comes
    from a per-column bend function, not a repeating sine texture.

    UV.y follows this bank's normal convention (0 top, 1 bottom);
    Ground_Height measures up from the bottom edge.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "meadowWind"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Blade_Density','Blade_Height','Wind_Speed','Wind_Strength',
            'Gust_Frequency','Ground_Height','Grass_R','Grass_G',
            'Grass_B','Ground_R','Ground_G','Ground_B',
            'Flower_Chance','Flower_R','Flower_G','Flower_B',
        },
        default = {
            60,.55,1.4,.05,
            2.2,.05,.25,.55,
            .18,.22,.16,.1,
            .06,.95,.55,.75,
        },
        min = {
            10,.1,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            160,.9,4,.2,
            8,.25,1,1,
            1,1,1,1,
            .3,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Blade_Density   = u_UserData0[0][0];
float Blade_Height    = u_UserData0[0][1];
float Wind_Speed      = u_UserData0[0][2];
float Wind_Strength   = u_UserData0[0][3];
float Gust_Frequency  = u_UserData0[1][0];
float Ground_Height   = u_UserData0[1][1];
vec3  Grass_Color     = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
vec3  Ground_Color    = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float Flower_Chance   = u_UserData0[3][0];
vec3  Flower_Color    = vec3( u_UserData0[3][1], u_UserData0[3][2], u_UserData0[3][3] );

//----------------------------------------------

P_RANDOM float meadow_hash( float n )
{
    return fract( sin( n * 78.233 ) * 43758.5453123 );
}

vec2 meadow_blade( vec2 uv, float freq, float heightScale, float seed )
{
    // returns (mask, flowerMask)
    float col = floor( uv.x * freq );
    float cellX = fract( uv.x * freq );
    float h1 = meadow_hash( col + seed );
    float h2 = meadow_hash( col + seed + 17.3 );
    float h3 = meadow_hash( col + seed + 41.9 );

    float bladeHeight = Blade_Height * heightScale * ( 0.55 + 0.45 * h1 );
    float bottomY = 1.0;
    float topY = bottomY - bladeHeight;

    float t = clamp( ( bottomY - uv.y ) / max( bladeHeight, 0.0001 ), 0.0, 1.0 );
    float gust = sin( CoronaTotalTime * Wind_Speed * 0.35 + uv.x * Gust_Frequency );
    float sway = ( sin( CoronaTotalTime * Wind_Speed + h1 * 6.2832 ) * 0.6 + gust * 0.4 ) * Wind_Strength;
    float centerX = 0.5 + sway * t * t;
    float width = mix( 0.22, 0.02, t ) * ( 0.6 + 0.5 * h2 );

    float inHeight = step( uv.y, bottomY ) * step( topY, uv.y );
    float mask = smoothstep( width, width * 0.25, abs( cellX - centerX ) ) * inHeight;

    float flowerSpot = step( 1.0 - Flower_Chance, h3 ) * smoothstep( 0.08, 0.0, abs( t - 0.92 ) );
    float flower = flowerSpot * smoothstep( width * 1.6, width * 0.5, abs( cellX - centerX ) ) * inHeight;

    return vec2( mask, flower );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 back = meadow_blade( UV, Blade_Density * 0.6, 0.75, 3.0 );
    vec2 front = meadow_blade( UV, Blade_Density, 1.0, 91.0 );

    vec3 rgb = vec3( 0.0 );
    float alpha = 0.0;

    vec3 backColor = Grass_Color * 0.65;
    alpha = max( alpha, back.x );
    rgb = mix( rgb, backColor, back.x );

    alpha = max( alpha, front.x );
    rgb = mix( rgb, Grass_Color, front.x );

    rgb = mix( rgb, Flower_Color, clamp( back.y + front.y, 0.0, 1.0 ) );
    alpha = max( alpha, clamp( back.y + front.y, 0.0, 1.0 ) );

    float groundMask = step( 1.0 - Ground_Height, UV.y );
    rgb = mix( rgb, Ground_Color, groundMask * step( alpha, 0.5 ) );
    alpha = max( alpha, groundMask );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
