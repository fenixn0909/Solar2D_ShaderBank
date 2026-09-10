
--[[
    Original implementation for this bank. Falling water streaks reuse the
    same per-column hashed-phase idea as this batch's
    kernelG_FX_matrixCodeRain.lua (each vertical column offset so they
    don't all flow in lockstep) but driven through a continuous `sin`
    flow coordinate and sharpened with `pow` instead of a hard glyph cell,
    for a liquid streak rather than a falling-block look. A foam band at
    a settable Pool_Line and a soft noise-modulated mist glow just above
    it complete the look.

    Pure generator, transparent above/below the water - drop it in front
    of a cliff/rock backdrop for a waterfall. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "waterfallCascade"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Column_Density','Fall_Speed','Streak_Length','Pool_Line',
            'Pool_Depth','Mist_Height','Mist_Amount','Water_Color_R',
            'Water_Color_G','Water_Color_B','Aspect_Ratio','',
            '','','','',
        },
        default = {
            40,3.5,2,.82,
            .15,.1,.4,.75,
            .88,.95,1,0,
            0,0,0,0,
        },
        min = {
            5,0,.2,.3,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            100,10,5,1,
            .4,.3,1,1,
            1,1,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Column_Density = u_UserData0[0][0];
float Fall_Speed     = u_UserData0[0][1];
float Streak_Length  = u_UserData0[0][2];
float Pool_Line      = u_UserData0[0][3];
float Pool_Depth     = u_UserData0[1][0];
float Mist_Height    = u_UserData0[1][1];
float Mist_Amount    = u_UserData0[1][2];
vec3  Water_Color    = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Aspect_Ratio   = u_UserData0[2][2];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float wobble = sin( UV.y * 20.0 + CoronaTotalTime * 2.0 + uv.x * 3.0 ) * 0.003;
    float col = floor( ( uv.x + wobble ) * Column_Density );
    float colOffset = hash1( col * 7.3 ) * 10.0;

    float flowCoord = UV.y * Streak_Length * 30.0 - CoronaTotalTime * Fall_Speed + colOffset;
    float streak = pow( sin( flowCoord ) * 0.5 + 0.5, 3.0 );

    float fallMask = streak * step( UV.y, Pool_Line );

    float poolDist = UV.y - Pool_Line;
    float poolMask = smoothstep( -0.02, 0.02, poolDist ) * ( 1.0 - smoothstep( Pool_Depth * 0.7, Pool_Depth, poolDist ) );
    float foamNoise = sin( UV.x * 80.0 + CoronaTotalTime * 4.0 ) * 0.5 + 0.5;
    float foam = poolMask * smoothstep( 0.4, 0.8, foamNoise );

    float mistBand = exp( -pow( ( UV.y - ( Pool_Line - Mist_Height * 0.5 ) ) / max( Mist_Height * 0.5, 0.01 ), 2.0 ) ) * step( UV.y, Pool_Line );
    float mistNoise = sin( UV.x * 10.0 + CoronaTotalTime * 1.2 ) * 0.5 + 0.5;
    float mist = mistBand * mistNoise * Mist_Amount;

    vec3 rgb = Water_Color * fallMask + vec3( 1.0 ) * foam * 0.8 + vec3( 1.0 ) * mist;
    float alpha = clamp( fallMask * 0.8 + foam + mist, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
