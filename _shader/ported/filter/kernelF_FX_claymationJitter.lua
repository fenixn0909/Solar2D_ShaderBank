
--[[
    Original implementation for this bank. Real stop-motion has three
    "flaws" that read as charm rather than error: the whole shot only
    updates a handful of times per second, each held frame sits at a
    very slightly different position/lighting than the last because a
    human physically touched the set between exposures, and film grain
    changes per-shot rather than per-render-frame. All three are driven
    from the same quantized `floor(time * Frame_Rate)` frame index here,
    each mapped through a different hash seed so the jitter, flicker, and
    grain don't all peak/trough in lockstep.

    Single-texture filter, works on any sprite (animated or static).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "claymationJitter"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Frame_Rate','Jitter_Amount','Flicker_Amount','Grain_Amount',
            'Grain_Scale','','','',
            '','','','',
            '','','','',
        },
        default = {
            12,.006,.08,.15,
            250,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            2,0,0,0,
            50,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            30,.03,.5,1,
            500,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Frame_Rate     = u_UserData0[0][0];
float Jitter_Amount  = u_UserData0[0][1];
float Flicker_Amount = u_UserData0[0][2];
float Grain_Amount   = u_UserData0[0][3];
float Grain_Scale    = u_UserData0[1][0];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float frameIndex = floor( CoronaTotalTime * max( Frame_Rate, 0.1 ) );
    float frameHash = hash1( frameIndex );

    vec2 jitter = ( vec2( hash1( frameHash * 3.1 ), hash1( frameHash * 7.7 + 1.0 ) ) - 0.5 ) * Jitter_Amount;
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV + jitter );

    float flicker = 1.0 + ( hash1( frameHash * 5.5 + 2.0 ) - 0.5 ) * Flicker_Amount;

    float grainHash = hash1( dot( floor( UV * Grain_Scale ), vec2( 12.9898, 78.233 ) ) + frameHash * 13.0 );
    vec3 rgb = src.rgb * flicker * mix( 1.0 - Grain_Amount * 0.3, 1.0 + Grain_Amount * 0.3, grainHash );

    P_COLOR vec4 COLOR = vec4( rgb, src.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
