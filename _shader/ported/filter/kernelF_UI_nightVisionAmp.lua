
--[[
    Original implementation for this bank. Night-vision goggle
    amplification: luminance is gamma-lifted and remapped into a single
    green channel (light amplification, not a multi-stop palette), then
    masked by two overlapping circles offset by Eye_Separation for the
    binocular dual-lens view real NVGs have, with fine animated grain
    and a soft bloom on the brightest amplified spots (real image
    intensifiers bloom hard on bright sources).

    Checked against all existing kernels first: this bank's own
    kernelF_UI_thermalVision (batch 6) maps luminance through a seven-
    stop black-purple-blue-green-yellow-red-white *palette* for a heat-
    detection read and has no lens mask at all; kernelF_FX_xrayVision
    reveals a hidden layer through silhouette alpha rather than
    amplifying the existing image's own luminance. Single-channel
    green amplification plus a dual-circle binocular mask doesn't
    overlap either.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "nightVisionAmp"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Gain','Gamma','Eye_Separation','Lens_Radius',
            'Noise_Amount','Bloom_Amount','Aspect_Ratio','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            1.6,.7,.16,.42,
            .06,.5,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .5,.3,0,.15,
            0,0,.2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            4,1.5,.4,.6,
            .3,1.5,5,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Gain           = u_UserData0[0][0];
float Gamma          = u_UserData0[0][1];
float Eye_Separation = u_UserData0[0][2];
float Lens_Radius    = u_UserData0[0][3];
float Noise_Amount   = u_UserData0[1][0];
float Bloom_Amount   = u_UserData0[1][1];
float Aspect_Ratio   = u_UserData0[1][2];
float Opacity        = u_UserData0[1][3];

//----------------------------------------------

P_RANDOM float nv_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 78.2, 34.9 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float amplified = clamp( pow( lum * Gain, Gamma ), 0.0, 1.0 );

    vec3 green = vec3( 0.08, 1.0, 0.22 ) * amplified;

    float hotspot = smoothstep( 0.82, 1.0, amplified );
    green += vec3( 0.55, 1.0, 0.65 ) * hotspot * Bloom_Amount;

    float grain = nv_hash( UV * 640.0 + fract( CoronaTotalTime ) * 71.0 ) - 0.5;
    green += vec3( grain * Noise_Amount );

    vec2 leftC = vec2( 0.5 - Eye_Separation, 0.5 );
    vec2 rightC = vec2( 0.5 + Eye_Separation, 0.5 );
    float dl = length( ( UV - leftC ) * vec2( 1.0, Aspect_Ratio ) );
    float dr = length( ( UV - rightC ) * vec2( 1.0, Aspect_Ratio ) );
    float lensMask = max( smoothstep( Lens_Radius, Lens_Radius - 0.04, dl ), smoothstep( Lens_Radius, Lens_Radius - 0.04, dr ) );

    vec3 finalRGB = clamp( green, 0.0, 1.0 ) * lensMask;
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
