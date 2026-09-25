
--[[
    Original implementation for this bank. Height-map-driven refraction
    with per-channel offset dispersion (sample R/G/B at slightly different
    displaced UVs instead of one shared offset) is the standard cheap
    stand-in for real light dispersion through glass/gems in real-time
    work - this derives the displacement straight from CoronaSampler1 via
    a central-difference gradient (no separate normal map needed, just a
    grayscale height/facet map you can paint quickly), then reuses that
    same gradient at three different strengths for R/G/B to fringe the
    edges the way a cut gem or prism splits light.

    CoronaSampler0 = the sprite/art underneath. CoronaSampler1 = a
    grayscale height map (bright = raised facets) - a faceted gem outline
    with a few painted highlight bumps works well. Distinct from this
    bank's kernelC_FX_iridescence2d.lua, which distorts UVs with a *noise*
    texture and cycles a full rainbow via a sine palette; this reads an
    intentional height/facet map and only fringes the channel edges,
    closer to a cut-glass/prism look than an iridescent soap-film one.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "prismGemRefraction"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Refraction_Strength','Dispersion','Refraction_Mix','Brightness',
            'Tint_R','Tint_G','Tint_B','Tint_Amount',
            '','','','',
            '','','','',
        },
        default = {
            8,.6,.8,1.1,
            .7,.85,1,.25,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            30,1,1,2,
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

float Refraction_Strength = u_UserData0[0][0];
float Dispersion          = u_UserData0[0][1];
float Refraction_Mix      = u_UserData0[0][2];
float Brightness          = u_UserData0[0][3];
vec3  Tint                = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Tint_Amount         = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float hC = texture2D( CoronaSampler1, UV ).r;
    float hX = texture2D( CoronaSampler1, UV + vec2( CoronaTexelSize.x, 0.0 ) ).r;
    float hY = texture2D( CoronaSampler1, UV + vec2( 0.0, CoronaTexelSize.y ) ).r;

    vec2 grad = vec2( hX - hC, hY - hC ) * Refraction_Strength * CoronaTexelSize.xy * 200.0;

    P_COLOR vec4 baseColor = texture2D( CoronaSampler0, UV );

    float rC = texture2D( CoronaSampler0, UV + grad * ( 1.0 + Dispersion ) ).r;
    float gC = texture2D( CoronaSampler0, UV + grad ).g;
    float bC = texture2D( CoronaSampler0, UV + grad * ( 1.0 - Dispersion ) ).b;
    vec3 refracted = vec3( rC, gC, bC );

    vec3 rgb = mix( baseColor.rgb, refracted, Refraction_Mix ) * Brightness + Tint * hC * Tint_Amount;

    P_COLOR vec4 COLOR = vec4( rgb, baseColor.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
