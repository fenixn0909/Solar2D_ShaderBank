
--[[
    https://godotshaders.com/shader/vignette-with-reduced-banding-artifacts/
    (author handle not shown on the post page)
    July 8, 2024

    Direct port, no texture needed - pure generator, same as the
    original (no TEXTURE sample in the source either). The dither term
    breaks up banding in the smoothstep gradient, a nice cheap trick
    worth keeping as-is.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "vignetteDither"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Inner_Radius','Outer_Radius','Vignette_Strength','Dither_Strength',
            'Vignette_Color_R','Vignette_Color_G','Vignette_Color_B','Vignette_Color_A',
            '','','','',
            '','','','',
        },
        default = { .1,1,1,.03,  0,0,0,1,  0,0,0,0,  0,0,0,0, },
        min =     { 0,0,0,0,     0,0,0,0,  0,0,0,0,  0,0,0,0, },
        max =     { 1,1.5,2,.2,  1,1,1,1,  1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Inner_Radius      = u_UserData0[0][0];
float Outer_Radius      = u_UserData0[0][1];
float Vignette_Strength = u_UserData0[0][2];
float Dither_Strength   = u_UserData0[0][3];
vec4 Vignette_Color = vec4( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float dist = distance( UV, vec2( 0.5 ) );
    float vignette = smoothstep( Inner_Radius, Outer_Radius, dist ) * Vignette_Strength;
    float dither = fract( sin( dot( UV, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 ) * Dither_Strength;

    P_COLOR vec4 COLOR = vec4( Vignette_Color.rgb, vignette + dither );
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

