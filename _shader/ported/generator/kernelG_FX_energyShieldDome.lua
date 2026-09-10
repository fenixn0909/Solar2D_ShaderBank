
--[[
    Original implementation for this bank. "Force field" / "shield"
    Fresnel-dome shaders are a whole Unity Asset Store sub-category
    (FORGE3D's "Force Field", the free "Force Field Shader for URP",
    Shield VFX Shader Graph packages on itch.io) built on the same core
    idea - edge brightening via a Fresnel-style falloff plus a tech-panel
    grid overlay - so this reimplements that general recipe from scratch
    rather than any specific one of them, and adds an impact-reactive
    expanding ring driven by Impact_Time (seconds since the last hit -
    feed it CoronaTotalTime minus your hit timestamp each time something
    strikes the shield; a negative/large value means no ripple is active).

    Not a re-do of this bank's existing kernelG_FX_plasmaShield.lua, which
    is a swirling radial plasma *texture* - this one is a clean Fresnel
    dome with a tech grid and a settable impact point, closer to a Halo/
    Mass-Effect-style energy barrier than a plasma ball. Also distinct
    from the newer kernelF_FX_forceField.lua: that one is a *filter* that
    hugs whatever silhouette CoronaSampler0's own alpha already has (so it
    always matches the sprite it's applied to); this is a *generator*
    with its own independent circular radius, useful as a standalone
    bubble/ward object that isn't tied to a specific sprite's outline,
    and it adds the settable Impact_X/Y/Time ripple that forceField
    doesn't have. Pick forceField to wrap an existing sprite; pick this
    one for a free-standing shield/ward with impact feedback.

    Pure generator, transparent background outside the dome radius.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "energyShieldDome"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Radius','Fresnel_Power','Edge_Brightness','Grid_Density',
            'Grid_Strength','Color_R','Color_G','Color_B',
            'Impact_X','Impact_Y','Impact_Time','Ripple_Speed',
            'Aspect_Ratio','Base_Alpha','','',
        },
        default = {
            .42,2.5,1.4,10,
            .25,.35,.75,1,
            .5,.5,-10,1.6,
            1,.12,0,0,
        },
        min = {
            .05,.5,0,0,
            0,0,0,0,
            0,0,-10,.2,
            .2,0,0,0,
        },
        max = {
            .6,8,3,30,
            1,1,1,1,
            1,1,3,4,
            5,1,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Radius          = u_UserData0[0][0];
float Fresnel_Power   = u_UserData0[0][1];
float Edge_Brightness = u_UserData0[0][2];
float Grid_Density    = u_UserData0[0][3];
float Grid_Strength   = u_UserData0[1][0];
vec3  Color           = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Impact_X        = u_UserData0[2][0];
float Impact_Y        = u_UserData0[2][1];
float Impact_Time     = u_UserData0[2][2];
float Ripple_Speed    = u_UserData0[2][3];
float Aspect_Ratio    = u_UserData0[3][0];
float Base_Alpha      = u_UserData0[3][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float rad = length( uv ) / max( Radius, 0.001 );
    float fill = smoothstep( 1.05, 0.95, rad );

    float fresnel = pow( clamp( rad, 0.0, 1.0 ), Fresnel_Power );

    float ang = atan( uv.y, uv.x );
    float gridA = smoothstep( 0.85, 1.0, abs( sin( ang * Grid_Density ) ) );
    float gridR = smoothstep( 0.85, 1.0, abs( sin( rad * Grid_Density * 3.14159265 ) ) );
    float grid = max( gridA, gridR ) * Grid_Strength * fill;

    vec2 impactUV = vec2( Impact_X - 0.5, Impact_Y - 0.5 );
    impactUV.x *= Aspect_Ratio;
    float distFromImpact = length( uv - impactUV );
    float ringRadius = Impact_Time * Ripple_Speed;
    float ring = exp( -pow( ( distFromImpact - ringRadius ) * 6.0, 2.0 ) )
               * exp( -max( Impact_Time, 0.0 ) * 1.5 )
               * step( 0.0, Impact_Time );
    ring *= fill;

    float glow = fresnel * Edge_Brightness * fill;

    float alpha = clamp( Base_Alpha * fill + glow * 0.6 + grid * 0.5 + ring, 0.0, 1.0 );
    vec3 rgb = Color * ( Base_Alpha * fill * 0.5 + glow + grid * 0.8 + ring * 1.5 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
