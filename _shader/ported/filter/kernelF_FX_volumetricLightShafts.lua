
--[[
    Original implementation for this bank. The classic "volumetric
    light scattering as a post-process" technique (Mitchell, GPU Gems
    3) - for each pixel, march 16 steps toward Light_Pos through the
    *existing* image, accumulating a decay-weighted sum of whatever
    bright pixels lie along that path, then add the result back as
    light shafts. Because it operates on real image content, anything
    already dark between the pixel and the light (silhouettes, terrain,
    foliage) naturally occludes the shaft - no separate occlusion mask
    needed, which is the whole appeal of this technique.

    Checked against all existing kernels first: kernelG_ray_holy fans
    procedurally-generated rays outward from nothing at a fixed Angle/
    Spread - it draws rays, it doesn't sample or occlude against any
    existing image; kernelF_blur_radial is a Yui Kinomoto radial
    *motion*-blur port (zoom-streak from Progress, ported faithfully
    with its own bug fix noted in its header) - directionless streaking
    for a hit/dash feel, not a light-accumulation march toward a point.
    Neither produces occlusion-aware light shafts from scene content.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "volumetricLightShafts"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Light_X','Light_Y','Density','Decay',
            'Weight','Exposure','Threshold','Tint_R',
            'Tint_G','Tint_B','Opacity','',
            '','','','',
        },
        default = {
            .5,.15,.6,.94,
            .5,1.2,.6,1,
            .95,.8,1,0,
            0,0,0,0,
        },
        min = {
            -.5,-.5,.05,.7,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1.5,1.5,1.2,.995,
            2,4,.95,1,
            1,1,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Light_Pos    = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Density      = u_UserData0[0][2];
float Decay        = u_UserData0[0][3];
float Weight       = u_UserData0[1][0];
float Exposure     = u_UserData0[1][1];
float Threshold    = u_UserData0[1][2];
vec3  Shaft_Tint   = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Opacity      = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 deltaUV = ( UV - Light_Pos ) * ( Density / 16.0 );
    vec2 sampleUV = UV;
    float illumDecay = 1.0;
    vec3 accum = vec3( 0.0 );

    for ( int i = 0; i < 16; i++ )
    {
        sampleUV -= deltaUV;
        vec3 s = texture2D( CoronaSampler0, sampleUV ).rgb;
        float bright = max( s.r, max( s.g, s.b ) );
        float gate = smoothstep( Threshold, 1.0, bright );
        accum += s * gate * illumDecay * Weight;
        illumDecay *= Decay;
    }

    accum *= Exposure * ( 1.0 / 16.0 ) * 4.0;
    vec3 finalRGB = tex.rgb + accum * Shaft_Tint;
    finalRGB = mix( tex.rgb, clamp( finalRGB, 0.0, 1.0 ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
