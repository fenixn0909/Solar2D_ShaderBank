
--[[
    Original implementation for this bank. A Fresnel-style rim light
    for hero/selection highlighting (RTS unit selection, ARPG target
    highlight): an 8-tap ring around each pixel estimates how close it
    sits to the sprite's own alpha edge, that estimate is raised to
    Fresnel_Power for a true curved falloff (soft deep into the shape,
    bright right at the edge) rather than a flat band, and a
    Light_Angle bias brightens whichever side faces that direction -
    a real Fresnel term responds to angle, a plain outline doesn't.

    Checked against all existing kernels first: kernelF_FX_
    outlineUniversal (per its own header) does a faithfully-ported
    16-direction x 4-step radial alpha *scan* for a clean, uniform-
    width, solid-color traced line - a silhouette outline, not a
    soft graded falloff, and has no light-angle bias. kernelF_FX_
    forceField also rim-samples alpha but renders a steady scan-lined
    energy dome; this bank's own kernelF_FX_buffSparkleRise (batch 7)
    rim-samples alpha but renders rising sparkle motes. Neither
    produces a plain graded Fresnel highlight, and neither has a
    directional bias term.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "heroRimFresnel"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Fresnel_Power','Sample_Dist','Light_Angle','Color_R',
            'Color_G','Color_B','Intensity','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            2.2,.015,.9,.4,
            .8,1,1.4,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .5,.003,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            6,.04,6.28318,1,
            1,1,4,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Fresnel_Power = u_UserData0[0][0];
float Sample_Dist   = u_UserData0[0][1];
float Light_Angle   = u_UserData0[0][2];
vec3  Rim_Color     = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Intensity     = u_UserData0[1][2];
float Opacity       = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float edgeAccum = 0.0;
    for ( int i = 0; i < 8; i++ )
    {
        float a = float( i ) / 8.0 * 6.28318530718;
        vec2 offs = vec2( cos( a ), sin( a ) ) * Sample_Dist;
        edgeAccum += clamp( tex.a - texture2D( CoronaSampler0, UV + offs ).a, 0.0, 1.0 );
    }
    edgeAccum *= ( 1.0 / 8.0 );

    float fresnel = pow( clamp( edgeAccum, 0.0, 1.0 ), Fresnel_Power );

    vec2 lightDir = vec2( cos( Light_Angle ), sin( Light_Angle ) );
    vec2 fromCenter = normalize( UV - vec2( 0.5 ) + 0.0001 );
    float bias = dot( fromCenter, lightDir ) * 0.5 + 0.5;

    float rim = fresnel * mix( 0.35, 1.0, bias ) * step( 0.02, tex.a ) * Intensity;

    vec3 finalRGB = clamp( tex.rgb + Rim_Color * rim, 0.0, 1.0 );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
