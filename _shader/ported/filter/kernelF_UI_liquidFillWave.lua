
--[[
    Original implementation for this bank. Modeled on the "2D liquid fill"
    category of Unity shader that's a consistent Asset Store/Fab top
    seller for potion/health/mana UI - e.g. the "Unity URP 2D Liquid
    Shader" listing on Fab advertises exactly this feature set (fills any
    Sprite Renderer/UI Image container, edge foam, edge glow, distortion,
    "perfect for potions, health/mana globes"), and "Liquid Volume Pro 2"
    on the Asset Store leads with animated bubbles. Nothing was copied
    from either (both are paid, closed-source Shader Graphs) - this
    reimplements the same feature list as a plain fragment kernel: a
    sine-wave liquid surface (two offset waves so it doesn't look like a
    single perfect sine), a foam ridge right at the surface line, and
    small rising bubbles from a single hashed-cell lookup (no loop needed,
    cheap).

    This bank already has two other liquid-ish shaders and this is
    deliberately not a repeat of either: kernelF_UI_progressFill.lua
    (also in this ported/ folder) is a flat hard-edge fill with no wave/
    foam/bubbles at all, and kernelG_UI_liquidSphere2D.lua is a
    self-contained circular glass-orb generator (fixed shape, not a
    filter). This one is a filter that respects CoronaSampler0's own
    alpha/shape - drop it on a rectangular bar, a round gauge, or a
    custom potion-bottle sprite and it fills whatever silhouette is
    already there, matching Fill_Level from the bottom up the same
    direction convention as progressFill for drop-in familiarity.
    Aspect_Ratio only affects the bubble grid's cell shape; the fill
    line itself is already aspect-independent (driven by UV.y).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "liquidFillWave"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Fill_Level','Wave_Height','Wave_Speed','Wave_Freq',
            'Foam_Width','Liquid_Color_R','Liquid_Color_G','Liquid_Color_B',
            'Liquid_Alpha','Foam_Color_R','Foam_Color_G','Foam_Color_B',
            'Bubble_Amount','Bubble_Speed','Aspect_Ratio','',
        },
        default = {
            .55,.012,1.6,2,
            .02,.15,.55,.95,
            .85,.85,.97,1,
            .5,1,1,0,
        },
        min = {
            0,0,0,.5,
            0,0,0,0,
            0,0,0,0,
            0,0,.2,0,
        },
        max = {
            1,.05,5,8,
            .06,1,1,1,
            1,1,1,1,
            1,3,5,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Fill_Level    = u_UserData0[0][0];
float Wave_Height   = u_UserData0[0][1];
float Wave_Speed    = u_UserData0[0][2];
float Wave_Freq     = u_UserData0[0][3];
float Foam_Width    = u_UserData0[1][0];
vec3  Liquid_Color  = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Liquid_Alpha  = u_UserData0[2][0];
vec3  Foam_Color    = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float Bubble_Amount = u_UserData0[3][0];
float Bubble_Speed  = u_UserData0[3][1];
float Aspect_Ratio  = u_UserData0[3][2];

const float TAU = 6.28318530718;

P_RANDOM float hash12( vec2 p )
{
    vec3 p3 = fract( vec3( p.xyx ) * 0.1031 );
    p3 += dot( p3, p3.yzx + 33.33 );
    return fract( ( p3.x + p3.y ) * p3.z );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 containerColor = texture2D( CoronaSampler0, UV );

    float wave  = sin( UV.x * TAU * Wave_Freq + CoronaTotalTime * Wave_Speed ) * Wave_Height;
    float wave2 = sin( UV.x * TAU * Wave_Freq * 1.7 - CoronaTotalTime * Wave_Speed * 0.6 + 1.7 ) * Wave_Height * 0.4;
    float fillLine = Fill_Level + wave + wave2;

    float d = fillLine - ( 1.0 - UV.y );
    float liquidMask = smoothstep( -0.004, 0.004, d );
    float foamMask = smoothstep( 0.0, Foam_Width, d ) * ( 1.0 - smoothstep( Foam_Width, Foam_Width * 1.6 + 0.001, d ) );

    vec2 bubbleUV = vec2( UV.x * Aspect_Ratio, UV.y + CoronaTotalTime * Bubble_Speed * 0.15 );
    vec2 bCells = vec2( 7.0, 12.0 );
    vec2 bCellId = floor( bubbleUV * bCells );
    vec2 bLocal = fract( bubbleUV * bCells ) - 0.5;

    float bHash  = hash12( bCellId + 3.7 );
    float bHash2 = hash12( bCellId * 1.37 + 9.2 );

    bLocal.x += ( bHash - 0.5 ) * 0.7;
    float bRadius = mix( 0.08, 0.24, bHash2 ) * clamp( Bubble_Amount, 0.0, 1.0 );
    float bubbleMask = 1.0 - smoothstep( bRadius * 0.55, bRadius, length( bLocal ) );
    bubbleMask *= step( 0.4, bHash );
    bubbleMask *= liquidMask * ( 1.0 - foamMask );

    vec3 liquidRGB = mix( containerColor.rgb, Liquid_Color, Liquid_Alpha );
    vec3 withFoam = mix( liquidRGB, Foam_Color, clamp( foamMask, 0.0, 1.0 ) );
    vec3 withBubbles = mix( withFoam, vec3( 1.0 ), bubbleMask * 0.85 );

    vec3 finalRGB = mix( containerColor.rgb, withBubbles, liquidMask );

    P_COLOR vec4 COLOR = vec4( finalRGB, containerColor.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
