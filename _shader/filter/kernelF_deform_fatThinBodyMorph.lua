
--[[
    Original implementation for this bank. Modeled on the "fat / thin"
    body-morph toggle from commercial character shader bundles (a
    standard entry in packs like "Character Shader Pack" alongside
    dissolve/freeze/petrify/ghost) - nothing was copied from any of
    them (all paid, closed-source). A single signed Morph value drives
    a belly-weighted horizontal bulge (sampling closer to the vertical
    centerline for positive Morph makes the source art appear to
    stretch outward/fatter; sampling farther out for negative Morph
    compresses it thinner) plus a smaller matching vertical squash/
    stretch so the silhouette reads as a real body-shape change, not
    just a horizontal smear.

    Checked against all existing kernels first: this bank's existing
    deform filters (kernelF_deform_fisheye/perspective/skew/swirl and
    others) warp UVs for lens/perspective/twist effects with no belly-
    weighted vertical profile and no fat/thin framing; none combine a
    Y-weighted horizontal bulge with a matching vertical squash the way
    a body-shape morph needs.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fatThinBodyMorph"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Process','Morph','Belly_Center_Y','Belly_Width',
            'Vert_Squash','Aspect_Ratio','Speed','Wobble',
            '','','','',
            '','','','',
        },
        default = {
            1,0,.55,.3,
            .15,1,0,0.15,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,-.8,.1,.1,
            0,.2,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.8,.9,.6,
            .5,5,5,0.5,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Process        = u_UserData0[0][0];
float Morph          = u_UserData0[0][1];
float Belly_Center_Y = u_UserData0[0][2];
float Belly_Width    = u_UserData0[0][3];
float Vert_Squash    = u_UserData0[1][0];
float Aspect_Ratio   = u_UserData0[1][1];
float Speed          = u_UserData0[1][2];
float Wobble         = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // jiggle around the sculpted shape; Speed = 0 keeps it static
    float morphEff = Morph;
    if ( Speed > 0.01 ) { morphEff += sin( CoronaTotalTime * Speed ) * Wobble; }
    float bellyWeight = exp( -pow( ( UV.y - Belly_Center_Y ) / max( Belly_Width, 0.001 ), 2.0 ) );
    float bulge = morphEff * bellyWeight;
    float vertScale = 1.0 - morphEff * Vert_Squash * bellyWeight;

    vec2 remapUV = UV;
    remapUV.x = 0.5 + ( UV.x - 0.5 ) / ( 1.0 + bulge );
    remapUV.y = Belly_Center_Y + ( UV.y - Belly_Center_Y ) / max( vertScale, 0.2 );

    P_COLOR vec4 tex = texture2D( CoronaSampler0, remapUV );
    P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );

    vec4 blended = mix( orig, tex, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = blended;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
