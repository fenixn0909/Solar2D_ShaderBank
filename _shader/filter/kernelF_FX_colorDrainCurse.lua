
--[[
    Original implementation for this bank. Modeled on the "curse /
    life-drain" character-transform category from commercial character
    shader bundles - nothing was copied from any of them (all paid,
    closed-source). Color drains outward from Drain_Point as a simple
    growing-radius mask (Progress * Max_Radius) rather than a uniform
    whole-sprite desaturation, so the effect visibly spreads from
    wherever a curse or drain effect originates, with a thin dark
    curse-tinted rim marking the current boundary between drained and
    still-colored areas.

    Checked against all existing kernels first: kernelF_color_HSV/
    whiteBalance/colorCycling desaturate or shift hue uniformly across
    the whole sprite with no origin point and no growth radius at all;
    this bank's own kernelF_color_seasonalShift (batch 8) gates by hue
    proximity to green, not by spatial distance from a point. No
    existing kernel drains color radially from an origin.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "colorDrainCurse"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Drain_X','Drain_Y','Max_Radius',
            'Curse_R','Curse_G','Curse_B','Aspect_Ratio',
            'Rim_Width','Opacity','','',
            '','','','',
        },
        default = {
            0,.5,.5,.8,
            .25,.05,.35,1,
            .06,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.2,
            0,0,0,.2,
            .01,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1.5,
            1,1,1,5,
            .15,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress      = u_UserData0[0][0];
vec2  Drain_Point   = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Max_Radius    = u_UserData0[0][3];
vec3  Curse_Color   = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Aspect_Ratio  = u_UserData0[1][3];
float Rim_Width     = u_UserData0[2][0];
float Opacity       = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float dist = length( ( UV - Drain_Point ) * vec2( 1.0, Aspect_Ratio ) );
    float drainRadius = Progress * Max_Radius;

    float drained = 1.0 - smoothstep( drainRadius - Rim_Width, drainRadius + Rim_Width, dist );

    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    vec3 grayed = vec3( lum );
    vec3 finalRGB = mix( tex.rgb, grayed, drained );

    float rim = smoothstep( Rim_Width * 1.5, 0.0, abs( dist - drainRadius ) );
    finalRGB = mix( finalRGB, Curse_Color, rim * 0.55 );

    finalRGB = mix( tex.rgb, clamp( finalRGB, 0.0, 1.0 ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
