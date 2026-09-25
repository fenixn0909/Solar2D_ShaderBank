
--[[
    Original implementation for this bank. The eruption cycle is driven
    entirely by `mod(time, Cycle_Time)` with a fixed rise/hold/fall
    envelope built from three chained `smoothstep`s (quick rise, brief
    hold, quicker collapse) rather than any external trigger or particle
    system, so it loops forever with no Lua-side timer needed. The column
    itself is a simple width-vs-height taper test; the top spray is a 2D
    Gaussian blob centered at the column's *current* height (so it tracks
    the rise/fall automatically); falling droplets during the collapse
    phase reuse the single-hashed-cell falling-dot technique from this
    batch's kernelG_FX_sakuraPetals.lua, gated to only appear during that
    phase of the cycle.

    Pure generator, transparent background - place at the base of a hot-
    spring/volcanic scene. No Aspect_Ratio correction (purely vertical/
    horizontal geometry, no circular distances to keep round).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "geyserErupt"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Cycle_Time','Max_Height','Base_Width','Spray_Width',
            'Water_Color_R','Water_Color_G','Water_Color_B','',
            '','','','',
            '','','','',
        },
        default = {
            4,.6,.05,.12,
            .8,.9,.95,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            1,.1,.01,.02,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            15,1,.15,.3,
            1,1,1,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cycle_Time  = u_UserData0[0][0];
float Max_Height  = u_UserData0[0][1];
float Base_Width  = u_UserData0[0][2];
float Spray_Width = u_UserData0[0][3];
vec3  Water_Color = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float eruptProgress = mod( CoronaTotalTime, Cycle_Time ) / Cycle_Time;

    float riseEnd = 0.15;
    float holdEnd = 0.45;
    float fallEnd = 0.65;

    float height = smoothstep( 0.0, riseEnd, eruptProgress ) - smoothstep( holdEnd, fallEnd, eruptProgress );
    height = clamp( height, 0.0, 1.0 ) * Max_Height;

    float distFromCenter = abs( UV.x - 0.5 );
    float localHeightFrac = clamp( ( 1.0 - UV.y ) / max( height, 0.0001 ), 0.0, 1.0 );
    float widthAtHeight = mix( Base_Width, Base_Width * 0.5, localHeightFrac );
    float wobble = sin( UV.y * 30.0 + CoronaTotalTime * 20.0 ) * 0.01 * height;

    float inColumn = step( distFromCenter, widthAtHeight + wobble ) * step( 1.0 - UV.y, height );

    float sprayCenter = 1.0 - height;
    vec2 sprayVec = vec2( ( UV.x - 0.5 ) / max( Spray_Width, 0.01 ), ( UV.y - sprayCenter ) / 0.06 );
    float spray = exp( -dot( sprayVec, sprayVec ) ) * step( 0.02, height );

    float dropletsActive = smoothstep( holdEnd, holdEnd + 0.05, eruptProgress ) * ( 1.0 - smoothstep( fallEnd, fallEnd + 0.2, eruptProgress ) );
    vec2 dropUV = vec2( UV.x * 20.0, ( UV.y - CoronaTotalTime * 3.0 ) * 20.0 );
    vec2 dropCell = floor( dropUV );
    vec2 dropLocal = fract( dropUV ) - vec2( 0.5 );
    float dropHash = hash1( dot( dropCell, vec2( 12.9898, 78.233 ) ) );
    float dropVisible = step( 0.75, dropHash );
    float dropShape = 1.0 - smoothstep( 0.1, 0.2, length( dropLocal ) );
    float widthGate = smoothstep( 0.0, 0.3, 1.0 - distFromCenter / max( Spray_Width * 1.5, 0.01 ) );
    float droplets = dropVisible * dropShape * dropletsActive * widthGate;

    vec3 rgb = Water_Color * ( inColumn + spray * 1.3 + droplets );
    float alpha = clamp( inColumn + spray + droplets, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
