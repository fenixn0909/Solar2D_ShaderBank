
--[[
    https://godotshaders.com/shader/simple-dissolve-ragdoll-tutorial/
    ProfesorShader
    June 21, 2026

    Tagged "Spatial" on Godot Shaders (built for a 3D ragdoll tutorial),
    but the actual fragment logic only ever touches UV + a noise texture
    - no normals/lighting - so it ports directly as a 2D composite.
    paint1 = the character (always shown at its own alpha - never
    dissolved away), paint2 = a grayscale noise texture (its R channel
    is the threshold pattern). Diverges from the original on purpose:
    the original replaces the whole shape with a flat glow color and
    dissolves the shape itself; here the character stays fully visible
    and Glow_Color is added on top as an emissive highlight - only the
    glow's coverage (not the character) dissolves as Progress rises.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "mask"
kernel.name = "dissolveGlow"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Noise_Scale','Color_R','Color_G',
            'Color_B','','','',
            '','','','',
            '','','','',
        },
        default = {
            0, 1, 1, 1,
            1, 0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0, 0.1, 0, 0,
            0, 0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1, 10, 1, 1,
            1, 1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

P_COLOR float Progress    = u_UserData0[0][0];
P_COLOR float Noise_Scale = u_UserData0[0][1];
P_COLOR vec3  Glow_Color  = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 shape = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 noiseTex = texture2D( CoronaSampler1, UV * Noise_Scale );

    P_COLOR float mask = step( Progress, noiseTex.r );
    float edgeWidth = 0.08;
    float edge = smoothstep(Progress - edgeWidth, Progress, noiseTex.r) * (1.0 - mask);
    P_COLOR vec4 COLOR = shape;
    // where edge, blend glow
    COLOR.rgb = mix(shape.rgb, Glow_Color, edge * 0.85);
    COLOR.a = shape.a * (mask > 0.5 ? 1.0 : edge);
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

