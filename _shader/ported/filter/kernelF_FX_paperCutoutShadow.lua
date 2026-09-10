
--[[
    Original implementation for this bank. A paper-craft/cutout-animation
    look (Klaus, classic Paper Mario, physical stop-motion paper puppets)
    comes mostly from a soft-edged offset shadow sitting slightly behind
    the flat shape plus a consistent paper-fiber grain shared by both the
    shadow and the shape itself. The shadow re-samples CoronaSampler0 at
    an offset position and averages its alpha over 5 taps (itself plus
    four texel-offset neighbours) for a cheap soft edge rather than a
    hard-edged duplicate silhouette; compositing avoids any division by
    interpolating color with the main shape's own alpha and letting the
    final premultiply step apply the shadow's alpha on its own, so there's
    no risk of a divide-by-zero at fully transparent pixels.

    Single-texture filter, works on any sprite.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "paperCutoutShadow"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Shadow_Offset_X','Shadow_Offset_Y','Shadow_Opacity','Blur_Radius',
            'Shadow_Color_R','Shadow_Color_G','Shadow_Color_B','Grain_Amount',
            'Grain_Scale','','','',
            '','','','',
        },
        default = {
            .012,.018,.55,1.5,
            .15,.12,.18,.12,
            180,0,0,0,
            0,0,0,0,
        },
        min = {
            -.05,-.05,0,0,
            0,0,0,0,
            30,0,0,0,
            0,0,0,0,
        },
        max = {
            .05,.05,1,4,
            1,1,1,1,
            400,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Shadow_Offset_X = u_UserData0[0][0];
float Shadow_Offset_Y = u_UserData0[0][1];
float Shadow_Opacity  = u_UserData0[0][2];
float Blur_Radius     = u_UserData0[0][3];
vec3  Shadow_Color    = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Grain_Amount    = u_UserData0[1][3];
float Grain_Scale     = u_UserData0[2][0];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    vec2 shadowUV = UV - vec2( Shadow_Offset_X, Shadow_Offset_Y );
    vec2 offs = CoronaTexelSize.xy * Blur_Radius;

    float a0 = texture2D( CoronaSampler0, shadowUV ).a;
    float a1 = texture2D( CoronaSampler0, shadowUV + vec2( offs.x, 0.0 ) ).a;
    float a2 = texture2D( CoronaSampler0, shadowUV - vec2( offs.x, 0.0 ) ).a;
    float a3 = texture2D( CoronaSampler0, shadowUV + vec2( 0.0, offs.y ) ).a;
    float a4 = texture2D( CoronaSampler0, shadowUV - vec2( 0.0, offs.y ) ).a;
    float shadowMask = ( a0 + a1 + a2 + a3 + a4 ) / 5.0 * Shadow_Opacity;

    float grainHash = hash1( dot( floor( UV * Grain_Scale ), vec2( 12.9898, 78.233 ) ) );
    float paperTexture = mix( 1.0 - Grain_Amount * 0.5, 1.0 + Grain_Amount * 0.5, grainHash );

    vec3 shadowRGB = Shadow_Color * paperTexture;
    vec3 mainRGB = src.rgb * paperTexture;

    vec3 finalRGB = mix( shadowRGB, mainRGB, src.a );
    float finalAlpha = clamp( src.a + shadowMask * ( 1.0 - src.a ), 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( finalRGB, finalAlpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
