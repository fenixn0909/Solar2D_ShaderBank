
--[[
    https://godotshaders.com/shader/2d-outline-universal/
    marcbbb
    July 15, 2026

    The original's real value is its 16-direction x 4-step radial alpha
    scan for a clean, atlas-safe outline - that's ported faithfully
    below (both counts are compile-time constants in the original too,
    so no change needed there). Dropped: the atlas sub-region remapping
    and the companion C# script that feeds it (Solar2D doesn't expose
    atlas regions to a kernel the way Godot's REGION_RECT does) and the
    original's vertex-kernel geometry expansion. This version reads
    CoronaSampler0 directly in the object's own UV space.
    IMPORTANT: like any outline shader, this can only draw where
    transparent pixels already exist to draw INTO - if your source art
    has no transparent margin around the sprite, the outline will clip
    at the texture edge. Leave a few px of padding around the art, same
    as you would for any other outline technique.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "outlineUniversal"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Outline_Width','Tint_R','Tint_G','Tint_B',
            'Tint_A','','','',
            '','','','',
            '','','','',
        },
        default = {
            4, 1,1,1,
            1, 0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0, 0,0,0,
            0, 0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            32, 1,1,1,
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

float Outline_Width = u_UserData0[0][0];
vec4  Outline_Tint  = vec4( u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );

const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 sampled_rgba = texture2D( CoronaSampler0, UV );

    vec2 outline_step_uv = Outline_Width * CoronaTexelSize.xy;

    float outline_alpha = 0.0;
    if ( Outline_Width > 0.0 ) {
        const int direction_count = 16;
        const int step_count = 4;

        for ( int direction_index = 0; direction_index < direction_count; direction_index++ ) {
            float angle = TAU * float( direction_index ) / float( direction_count );
            vec2 direction = vec2( cos( angle ), sin( angle ) );

            for ( int step_index = 1; step_index <= step_count; step_index++ ) {
                float step_ratio = float( step_index ) / float( step_count );
                vec2 sample_uv = UV + direction * outline_step_uv * step_ratio;

                if ( sample_uv.x >= 0.0 && sample_uv.x <= 1.0 &&
                     sample_uv.y >= 0.0 && sample_uv.y <= 1.0 ) {
                    outline_alpha = max( outline_alpha, texture2D( CoronaSampler0, sample_uv ).a );
                }
            }
        }
    }

    outline_alpha *= Outline_Tint.a * ( 1.0 - sampled_rgba.a );

    P_COLOR vec4 COLOR = vec4( Outline_Tint.rgb, outline_alpha );
    COLOR.rgb = mix( COLOR.rgb, sampled_rgba.rgb, sampled_rgba.a );
    COLOR.a = sampled_rgba.a + outline_alpha;

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

