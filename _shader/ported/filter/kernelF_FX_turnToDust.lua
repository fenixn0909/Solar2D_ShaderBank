
--[[
    https://godotshaders.com/shader/turn-to-dust-dissolve/
    qDRot
    April 7, 2026

    Direct port, single texture (CoronaSampler0). Original's inline
    `random()` credited by its own header to a separate godotshaders.com
    snippet (https://godotshaders.com/snippet/random-value/) - carried
    over as-is.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "turnToDust"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Strength','Seed','Direction_X','Direction_Y',
            'Mask_Vignette_Strength','Mask_Vignette_Center_X','Mask_Vignette_Center_Y','',
            '','','','',
            '','','','',
        },
        default = {
            0, .5, -.5, 0,
            .5, .5, .3, 0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0, .01, -2, -2,
            0, 0, 0, 0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1, 1, 2, 2,
            1, 1, 1, 1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Strength                 = u_UserData0[0][0];
float Seed                     = u_UserData0[0][1];
vec2  Direction                = vec2( u_UserData0[0][2], u_UserData0[0][3] );
float Mask_Vignette_Strength   = u_UserData0[1][0];
vec2  Mask_Vignette_Center     = vec2( u_UserData0[1][1], u_UserData0[1][2] );

//----------------------------------------------
// from https://godotshaders.com/snippet/random-value/, per the original

float random( vec2 uv )
{
    return fract( sin( dot( uv.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 offset = vec2( random( UV * Seed ), random( UV * Seed ) );
    offset.x = clamp( offset.x, 0.0, 0.5 );
    offset.y = clamp( offset.y, 0.0, 1.5 );

    vec2 offset_uv = offset;
    offset_uv = offset_uv * Strength + UV + Direction * Strength;

    float circle_clip = distance( UV, Mask_Vignette_Center );

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, offset_uv );
    COLOR.a = ( COLOR.a - clamp( offset.x * Strength, 0.0, 3.0 ) - Strength )
              - circle_clip * Strength * Mask_Vignette_Strength * 3.0;

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

