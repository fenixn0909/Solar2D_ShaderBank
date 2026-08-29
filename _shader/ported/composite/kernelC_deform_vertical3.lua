--[[
    https://godotshaders.com/shader/2d-vertical-deform-shader-3-sections/
    MikeGooB
    August 3, 2026
    MIT. Deforms sprites vertically in 3 sections based on an effector
    position (object_position) and a RGB mask (deform_mask_texture).
    Original uses global object_position, deform_mask_texture sampler,
    and a vertex stage that computes deform_map_strength from
    pivot_world_pos distance. Here ported as composite: paint1 = sprite
    (CoronaSampler0), paint2 = deform mask (CoronaSampler1, R/G/B = 3
    sections). Object position is a normalized UV uniform; vertex stage
    is folded into fragment for Solar2D compatibility (no MODEL_MATRIX).
    If you have no mask texture, a procedural UV-based mask is used as
    fallback (R= left third, G= center, B= right third).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "deform"
kernel.name = "vertical3"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Object_X','Object_Y','Deform_Strength','',
            '','','','',
            '','','','',
            '','','','',
        },
        default = { 0.5, 0.5, 0.25, 0,
                    0,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0, 0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,1, 1,0, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Object_X       = u_UserData0[0][0];
float Object_Y       = u_UserData0[0][1];
float Deform_Strength= u_UserData0[0][2];

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 object_position = vec2(Object_X, Object_Y);
    // approximate pivot as center of sprite (0.5) – original used MODEL_MATRIX[3].xy
    vec2 pivot = vec2(0.5);
    // texture_size approx 1 pixel in UV space ~ CoronaTexelSize.zw * 320? use 1.0 for relative
    float tex_w = 1.0;
    // deform_map_strength per original: distance from pivot offset by ±tex_w/6
    vec3 dms;
    dms.x = distance((pivot - vec2(tex_w/6.0, 0.0)), object_position) * 0.007 * 100.0;
    dms.y = distance(pivot, object_position) * 0.007 * 100.0;
    dms.z = distance((pivot + vec2(tex_w/6.0, 0.0)), object_position) * 0.007 * 100.0;
    dms = clamp(dms, 0.0, 1.0);
    dms = dms*0.5 + 0.5;
    dms = 1.0 - dms;

    // deform mask from paint2, fallback to procedural 3-section mask
    vec3 mask = texture2D(CoronaSampler1, UV).rgb;
    // if mask is near black (no texture bound, returns 0), use procedural
    float mask_luma = dot(mask, vec3(0.333));
    if (mask_luma < 0.01) {
        // left third R, center G, right third B
        mask.r = step(UV.x, 0.33) * (1.0 - step(UV.x, 0.0));
        mask.g = step(0.33, UV.x) * step(UV.x, 0.66);
        mask.b = step(0.66, UV.x);
    }

    vec2 uv = UV;
    uv.y -= mask.r * Deform_Strength * dms.x;
    uv.y -= mask.g * Deform_Strength * dms.y;
    uv.y -= mask.b * Deform_Strength * dms.z;

    // also simple vertex-like lift
    // (original vertex did VERTEX.y += length(dms)*... – approximated as uv offset already)

    uv = clamp(uv, vec2(0.0), vec2(1.0));
    P_COLOR vec4 COLOR = texture2D(CoronaSampler0, uv);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
