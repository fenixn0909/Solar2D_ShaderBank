
--[[
    Original implementation for this bank. Anisotropic sheen (a highlight
    that runs perpendicular to a surface's fiber direction, the classic
    Kajiya-Kay hair/cloth model rather than an isotropic Blinn-Phong dot)
    is what actually sells silk/satin/brushed-metal in real-time
    rendering; simplified to 2D here by reading a fiber-direction map
    (CoronaSampler1, encoded like a normal map's RG channels) instead of
    a real tangent-space basis, then measuring how aligned that direction
    is with the vector to a 2D light point - alignment near 0 (light
    roughly perpendicular to the fiber) gives the brightest sheen, which
    is the same "grazing highlight" behaviour real anisotropic materials
    show. A faint streak pattern running along the fibers is layered on
    top for a woven look rather than a flat highlight band.

    CoronaSampler0 = albedo. CoronaSampler1 = fiber-direction map (R,G =
    direction.xy encoded 0-1 like a normal map; a flat "fibers running
    horizontally" map is solid (255,128,x)). Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "silkAnisoSheen"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Light_X','Light_Y','Sheen_Power','Sheen_Strength',
            'Sheen_Color_R','Sheen_Color_G','Sheen_Color_B','Streak_Freq',
            'Streak_Amount','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .3,.2,3,.8,
            1,.95,.85,80,
            .3,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.5,0,
            0,0,0,5,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,1,10,2,
            1,1,1,300,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Light_X       = u_UserData0[0][0];
float Light_Y       = u_UserData0[0][1];
float Sheen_Power   = u_UserData0[0][2];
float Sheen_Strength= u_UserData0[0][3];
vec3  Sheen_Color   = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Streak_Freq   = u_UserData0[1][3];
float Streak_Amount = u_UserData0[2][0];
float Aspect_Ratio  = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 albedo = texture2D( CoronaSampler0, UV );
    vec2 fiberDir = normalize( texture2D( CoronaSampler1, UV ).rg * 2.0 - 1.0 );

    vec2 toLight = vec2( Light_X, Light_Y ) - UV;
    toLight.y /= Aspect_Ratio;
    vec2 L = normalize( toLight );

    float align = dot( fiberDir, L );
    float sheen = pow( 1.0 - abs( align ), Sheen_Power ) * Sheen_Strength;

    float streak = 0.5 + 0.5 * sin( dot( UV, vec2( fiberDir.y, -fiberDir.x ) ) * Streak_Freq );
    sheen *= mix( 1.0, streak, Streak_Amount );

    vec3 rgb = albedo.rgb + Sheen_Color * sheen * albedo.a;

    P_COLOR vec4 COLOR = vec4( rgb, albedo.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
