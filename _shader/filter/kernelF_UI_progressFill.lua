
--[[
    https://godotshaders.com/shader/sprite-progress-bar/
    swagboard
    November 20, 2021 (updated April 19, 2022)

    Direct port of the post's "Godot 4" code block, single texture
    (CoronaSampler0). Fills from the bottom of the UV rect upward as
    Progress increases, tinting the covered region by Overlay_Color at
    Strength - same fill direction and behavior as the original.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "progressFill"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Strength','Overlay_Color_R','Overlay_Color_G',
            'Overlay_Color_B','Overlay_Color_A','','',
            '','','','',
            '','','','',
        },
        default = {
            0,0,1,1,
            1,1,0,0,
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
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Progress = u_UserData0[0][0];
float Strength = u_UserData0[0][1];
vec4 Overlay_Color = vec4( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );

    if ( ( 1.0 - UV.y ) <= Progress && COLOR.a != 0.0 ) {
        COLOR.rgb = mix( COLOR.rgb, Overlay_Color.rgb, Strength );
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

