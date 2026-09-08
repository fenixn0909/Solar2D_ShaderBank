
--[[
    Original implementation for this bank - not a line-by-line port (Unity's
    URP shader source is under the Unity Companion License, which isn't
    freely redistributable, so nothing was copied from it).

    Technique: tangent-space normal-map + point-light lighting for 2D
    sprites - the same model behind Unity's actual "Sprite-Lit-Default" /
    "Sprite Lit" Shader Graph (URP 2D Renderer + Light2D), which is the
    default shader every Unity 2D project gets the moment it adds a normal
    map to a sprite and lights it with a Light2D. Reimplemented here from
    scratch as a GLSL kernel: unpack a tangent-space normal (RG=XY, B=Z)
    from CoronaSampler1, treat CoronaSampler0 as the albedo, then do
    Lambert diffuse + Blinn-Phong specular from a single tunable point
    light positioned in UV space with an adjustable height (Light_Z) above
    the sprite plane - the standard trick used to fake proper falloff/
    direction for a "flat" 2D normal map. Added a cheap fake rim term
    (driven by the normal's own Z falloff) since a bought-once specular
    highlight alone reads flat on sprite edges - most polished
    normal-mapped 2D lighting shaders (Unity's included) layer some form
    of edge/rim response on top for exactly this reason.

    CoronaSampler0 = albedo/diffuse sprite. CoronaSampler1 = tangent-space
    normal map (standard R=X, G=Y, B=Z encoding, each channel *2-1) - paint
    one in Krita/Aseprite/Normal Map Online or bake one, same as you would
    for Unity's NormalMap slot. A flat "no bumps" normal map is solid
    (128,128,255). Aspect_Ratio: set to your sprite's height/width if it
    isn't square, same convention as the other ported kernels in this bank
    (see e.g. kernelF_FX_shockwave.lua).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "Lit"
kernel.name = "normalMap2D"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Light_X','Light_Y','Light_Z','Light_Radius',
            'Light_Color_R','Light_Color_G','Light_Color_B','Light_Intensity',
            'Ambient_R','Ambient_G','Ambient_B','Specular_Power',
            'Specular_Strength','Rim_Strength','Aspect_Ratio','',
        },
        default = {
            .5,.35,.35,.9,
            1,.92,.75,1.4,
            .12,.12,.16,24,
            .35,.25,1,0,
        },
        min = {
            0,0,.05,.05,
            0,0,0,0,
            0,0,0,1,
            0,0,.2,0,
        },
        max = {
            1,1,1.5,2,
            1,1,1,4,
            1,1,1,64,
            1,1,5,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Light_X           = u_UserData0[0][0];
float Light_Y           = u_UserData0[0][1];
float Light_Z           = u_UserData0[0][2];
float Light_Radius      = u_UserData0[0][3];
vec3  Light_Color       = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Light_Intensity   = u_UserData0[1][3];
vec3  Ambient_Color     = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Specular_Power    = u_UserData0[2][3];
float Specular_Strength = u_UserData0[3][0];
float Rim_Strength      = u_UserData0[3][1];
float Aspect_Ratio      = u_UserData0[3][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 albedo = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 normalSample = texture2D( CoronaSampler1, UV );

    P_NORMAL vec3 N = normalize( vec3( normalSample.rg * 2.0 - 1.0, normalSample.b ) );

    vec2 toLight = vec2( Light_X, Light_Y ) - UV;
    toLight.y /= Aspect_Ratio;

    vec3 L = vec3( toLight, Light_Z );
    float dist = length( L );
    L /= max( dist, 0.0001 );

    float atten = clamp( 1.0 - dist / max( Light_Radius, 0.0001 ), 0.0, 1.0 );
    atten *= atten;

    float diffuse = max( dot( N, L ), 0.0 );

    vec3 V = vec3( 0.0, 0.0, 1.0 );
    vec3 H = normalize( L + V );
    float specular = pow( max( dot( N, H ), 0.0 ), Specular_Power ) * Specular_Strength;

    float rim = pow( 1.0 - clamp( N.z, 0.0, 1.0 ), 3.0 ) * Rim_Strength * diffuse;

    vec3 lightContribution = Light_Color * Light_Intensity * atten * ( diffuse + specular + rim );
    vec3 rgb = albedo.rgb * ( Ambient_Color + lightContribution );

    P_COLOR vec4 COLOR = vec4( rgb, albedo.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
