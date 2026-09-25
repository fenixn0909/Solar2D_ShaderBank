--[[
    https://godotshaders.com/shader/scratch-fisheye-effect/
    The2AndOnly, October 6, 2024

    Improved: the slider did nothing (a hardcoded
    `amount = sin(TIME)*5000` overwrote it every frame), the center was
    pinned at (0.5, 0.5), and it sampled an unbound TEXTURE sampler.
    Now Amount / Speed / Center_X / Center_Y / Process are all
    real-time: Speed = 0 freezes the wobble, Process fades the lens.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fisheyeScratch"
kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Amount','Speed','',
            'Center_X','Center_Y','','',
            '','','','',
            '','','','',
        },
        default = {
            1,100,1,0,
            0.5,0.5,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,-500,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,800,5,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Process = u_UserData0[0][0];
float Amount  = u_UserData0[0][1];
float Speed   = u_UserData0[0][2];
vec2  Center  = vec2( u_UserData0[1][0], u_UserData0[1][1] );

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // gentle wobble around the chosen amount; Speed = 0 freezes it
    float wob = 1.0;
    if ( Speed > 0.01 ) { wob = 0.7 + 0.3 * sin( CoronaTotalTime * Speed ); }
    float newAmount = ( Amount * wob / 100.0 ) + 1.0;

    vec4 orig = texture2D( CoronaSampler0, UV );

    vec2 vec = ( UV - Center ) / vec2( 0.5 );
    float vecLength = length( vec );
    vec2 warpUV = UV;
    if ( vecLength > 0.0001 )
    {
        float r = pow( min( vecLength, 1.0 ), newAmount ) * max( 1.0, vecLength );
        vec2 unit = vec / vecLength;
        warpUV = Center + r * unit * vec2( 0.5 );
    }
    vec4 warped = texture2D( CoronaSampler0, warpUV );

    vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = outc;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel




--[[

--]]
