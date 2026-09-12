
--[[
    Original implementation for this bank. Wispy dandelion/thistle
    seed tufts - a soft round puff crossed with a few thin radiating
    filament lines (cheap fuzzy-tuft look, not a texture) - suspended
    and drifting on slow horizontal wander rather than falling, with
    only a gentle downward creep. No glow, no flutter, no tumble
    rotation, all deliberately unlike this bank's other airborne
    nature ambience.

    Checked against all existing kernels first: kernelG_FX_sakuraPetals
    falls/tumbles with a flat colored petal shape and real rotation;
    kernelG_FX_fireflyDrift and this bank's own kernelG_FX_
    butterflyDrift (batch 6) both glow and/or flutter; neither is a
    non-glowing, filament-tufted, mostly-suspended seed. Distinct
    silhouette and motion character from all three.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "dandelionDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Count','Speed','Wander_Amount','Size',
            'Fall_Speed','Color_R','Color_G','Color_B',
            'Opacity','Seed','','',
            '','','','',
        },
        default = {
            6,.25,.25,.018,
            .04,.96,.95,.9,
            .75,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.006,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            100,1,.6,.04,
            .15,1,1,1,
            1,50,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Count       = u_UserData0[0][0];
float Speed       = u_UserData0[0][1];
float Wander      = u_UserData0[0][2];
float Size        = u_UserData0[0][3];
float Fall_Speed  = u_UserData0[1][0];
vec3  Seed_Color  = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Opacity     = u_UserData0[2][0];
float Seed        = u_UserData0[2][1];

const float TAU = 6.28318530718;

//----------------------------------------------

P_RANDOM float dand_hash( float n )
{
    return fract( sin( n * 71.3 ) * 39217.9 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float alpha = 0.0;

    for ( int i = 0; i < 100; i++ )
    {
        float fi = float( i );
        float active = step( fi + 0.5, Count );
        float h0 = dand_hash( fi + Seed );
        float h1 = dand_hash( fi + Seed + 9.0 );
        float h2 = dand_hash( fi + Seed + 19.0 );

        float t = CoronaTotalTime;
        vec2 base = vec2( h0, fract( h1 - t * Fall_Speed * ( 0.5 + h2 ) ) );
        vec2 pos = base + Wander * vec2(
            sin( t * Speed * ( 0.6 + 0.5 * h0 ) + h1 * 6.28 ),
            cos( t * Speed * ( 0.4 + 0.4 * h1 ) + h2 * 6.28 ) ) * 0.3;

        vec2 d = UV - pos;
        float dist = length( d );
        float puff = exp( -( dist * dist ) / max( Size * Size, 0.0001 ) ) * 0.5;

        float ang = atan( d.y, d.x );
        float filaments = 0.0;
        for ( int k = 0; k < 5; k++ )
        {
            float fk = float( k );
            float a = fk / 5.0 * TAU + h2 * 6.28;
            float angDiff = abs( mod( ang - a + 3.14159, TAU ) - 3.14159 );
            filaments = max( filaments, smoothstep( 0.4, 0.0, angDiff ) * smoothstep( Size * 1.6, Size * 0.3, dist ) );
        }

        alpha = max( alpha, ( puff + filaments * 0.4 ) * active );
    }

    P_COLOR vec4 COLOR = vec4( Seed_Color, clamp( alpha, 0.0, 1.0 ) * Opacity );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
