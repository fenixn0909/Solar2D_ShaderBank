
--[[
    Original implementation for this bank. A curse/debuff aura: five
    dark tendrils climb from Center with a sinusoidal curl that
    increases with height (so they whip more near the top than the
    base, like smoke catching a draft), each looping and regenerating
    from the base rather than dissipating outward. Purple-black by
    default with a thin glowing edge.

    Checked against all existing kernels first: kernelG_FX_emberDrift
    rises small independent embers/ash with wobble - discrete points,
    not continuous curling filaments; kernelG_FX_spiritWisp fakes a
    single ambient wandering light with closed-form wander, unattached
    to any character point; kernelG_FX_arcaneSmoke (per its own header)
    is a free-floating ambient smoke puff, not tendrils anchored to and
    climbing from a fixed base point. This is the only kernel anchoring
    multiple curling filaments to a single status-effect origin.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "curseAuraWisp"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Center_X','Center_Y','Height','Curl_Amount',
            'Speed','Color_R','Color_G','Color_B',
            'Width','Seed','Aspect_Ratio','',
            '','','','',
        },
        default = {
            .5,.85,.4,.06,
            .8,.25,.05,.35,
            .012,0,1,0,
            0,0,0,0,
        },
        min = {
            0,0,.1,0,
            0,0,0,0,
            .003,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,.8,30,
            3,1,1,1,
            5,50,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Center        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Height        = u_UserData0[0][2];
float Curl_Amount   = u_UserData0[0][3];
float Speed         = u_UserData0[1][0];
vec3  Aura_Color    = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Width         = u_UserData0[2][0];
float Seed          = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float curse_hash( float n )
{
    return fract( sin( n * 55.13 ) * 27139.51 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 rel = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );
    float bottomY = 0.0;

    float glow = 0.0;

    for ( int i = 0; i < 5; i++ )
    {
        float fi = float( i );
        float h1 = curse_hash( fi + Seed );
        float h2 = curse_hash( fi + Seed + 17.0 );

        float cycleT = fract( CoronaTotalTime * Speed * ( 0.6 + 0.4 * h1 ) + h1 );

        float pixelT = clamp( ( bottomY - rel.y ) / max( Height, 0.0001 ), 0.0, 1.0 );
        float grown = step( pixelT, cycleT );

        float curl = sin( pixelT * 6.0 + CoronaTotalTime * Speed * 2.0 + h2 * 6.0 ) * Curl_Amount * pixelT * pixelT;
        float baseOffset = ( h1 - 0.5 ) * 0.06;
        float targetX = baseOffset + curl;

        float dx = rel.x - targetX;
        float w = Width * ( 1.0 - pixelT * 0.6 );

        float tendril = exp( -( dx * dx ) / max( w * w, 0.0001 ) ) * grown;
        float tipFade = 1.0 - smoothstep( cycleT - 0.15, cycleT, pixelT );
        float cycleFade = 1.0 - smoothstep( 0.85, 1.0, cycleT );

        glow = max( glow, tendril * tipFade * cycleFade );
    }

    P_COLOR vec4 COLOR = vec4( Aura_Color, clamp( glow, 0.0, 1.0 ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
