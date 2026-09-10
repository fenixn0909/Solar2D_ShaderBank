
--[[
    Original implementation for this bank. Risograph printing's signature
    look comes from two or three flat spot-color ink layers, each
    separately (and imperfectly) screened and slightly misaligned from
    the others - approximated here as two independently-thresholded
    luminance layers (each sampled at a small pixel offset from the other
    to fake the registration drift) with a hashed-cell jitter added before
    thresholding so the ink edge is rough rather than a clean vector edge,
    plus a fine all-over speckle multiply for the flecked ink texture real
    riso prints have.

    Single-texture filter. Ink1/Ink2 default to a classic riso pink/blue
    pairing over warm paper, but any two spot colors work.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "risoGrain"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Misregister','Threshold1','Threshold2','Grain_Amount',
            'Grain_Scale','Ink1_Opacity','Ink2_Opacity','Paper_R',
            'Paper_G','Paper_B','Ink1_R','Ink1_G',
            'Ink1_B','Ink2_R','Ink2_G','Ink2_B',
        },
        default = {
            1.5,.55,.5,.35,
            60,.85,.7,.94,
            .91,.82,1,.15,
            .5,.1,.35,.85,
        },
        min = {
            0,0,0,0,
            10,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            5,1,1,1,
            200,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Misregister  = u_UserData0[0][0];
float Threshold1   = u_UserData0[0][1];
float Threshold2   = u_UserData0[0][2];
float Grain_Amount = u_UserData0[0][3];
float Grain_Scale  = u_UserData0[1][0];
float Ink1_Opacity = u_UserData0[1][1];
float Ink2_Opacity = u_UserData0[1][2];
vec3  Paper_Color  = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
vec3  Ink1_Color   = vec3( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0] );
vec3  Ink2_Color   = vec3( u_UserData0[3][1], u_UserData0[3][2], u_UserData0[3][3] );

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

float grain( vec2 uv, float seedVal )
{
    return hash1( dot( floor( uv ), vec2( 12.9898, 78.233 ) ) + seedVal );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 offset1 = vec2( Misregister, 0.0 ) * CoronaTexelSize.xy;
    vec2 offset2 = vec2( -Misregister * 0.6, Misregister * 0.4 ) * CoronaTexelSize.xy;

    float lum1 = dot( texture2D( CoronaSampler0, UV + offset1 ).rgb, vec3( 0.299, 0.587, 0.114 ) );
    float lum2 = dot( texture2D( CoronaSampler0, UV + offset2 ).rgb, vec3( 0.299, 0.587, 0.114 ) );

    float g1 = grain( UV * Grain_Scale, 1.0 );
    float g2 = grain( UV * Grain_Scale + 7.0, 2.0 );

    float ink1 = step( lum1 + ( g1 - 0.5 ) * Grain_Amount, Threshold1 );
    float ink2 = step( lum2 + ( g2 - 0.5 ) * Grain_Amount, Threshold2 );

    vec3 result = Paper_Color;
    result = mix( result, Ink1_Color, ink1 * Ink1_Opacity );
    result = mix( result, Ink2_Color, ink2 * Ink2_Opacity );

    float speckle = grain( UV * 400.0, 9.0 );
    result *= mix( 0.94, 1.0, speckle );

    P_COLOR vec4 localSrc = texture2D( CoronaSampler0, UV );

    P_COLOR vec4 COLOR = vec4( result, localSrc.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
