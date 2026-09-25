
--[[
    Original implementation for this bank. The anamorphic-lens streak
    look (the single wide horizontal flare line real anamorphic glass
    produces, distinct from a classic circular ghost flare): for each
    pixel, 8 samples march outward in both directions along
    Streak_Angle through the *existing* image, gate on bright pixels,
    and weight down with distance - any sufficiently bright highlight
    in the scene grows its own streak along that fixed axis, rather
    than needing one hardcoded light source position.

    Checked against all existing kernels first: kernelF_fxNoise_
    lensFlare (per its own header, a ported ShaderToy/godotshaders
    piece) draws the classic multi-ghost circular flare strung along a
    line from a bright point through screen center - rings and ghost
    artifacts, not a single continuous axis-constrained streak;
    kernelF_FX_speedLine/speedLineRadial/speedLineManga draw fixed
    graphic line patterns unrelated to sampling the image's own bright
    pixels. This is the only kernel building a streak from whatever is
    actually bright in-frame along one fixed axis.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "anamorphicLensStreak"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Streak_Angle','Streak_Length','Threshold','Intensity',
            'Color_R','Color_G','Color_B','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            0,.09,.75,1.6,
            .6,.75,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,.02,.4,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3.14159,.2,.95,4,
            1,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Streak_Angle  = u_UserData0[0][0];
float Streak_Length = u_UserData0[0][1];
float Threshold     = u_UserData0[0][2];
float Intensity     = u_UserData0[0][3];
vec3  Streak_Color  = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Opacity       = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 dir = vec2( cos( Streak_Angle ), sin( Streak_Angle ) );
    vec3 accum = vec3( 0.0 );

    for ( int i = 1; i <= 8; i++ )
    {
        float t = float( i ) * Streak_Length / 8.0;
        float w = 1.0 - float( i ) / 8.0;

        vec3 sPos = texture2D( CoronaSampler0, UV + dir * t ).rgb;
        vec3 sNeg = texture2D( CoronaSampler0, UV - dir * t ).rgb;
        float bp = max( sPos.r, max( sPos.g, sPos.b ) );
        float bn = max( sNeg.r, max( sNeg.g, sNeg.b ) );

        accum += sPos * smoothstep( Threshold, 1.0, bp ) * w;
        accum += sNeg * smoothstep( Threshold, 1.0, bn ) * w;
    }
    accum *= ( 1.0 / 8.0 );

    vec3 finalRGB = clamp( tex.rgb + accum * Streak_Color * Intensity, 0.0, 1.0 );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
