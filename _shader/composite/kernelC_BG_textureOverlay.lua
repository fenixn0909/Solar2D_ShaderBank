--[[
    https://godotshaders.com/shader/repeated-texture-overlay-for-tilemaps/
    jess.codes Aug 31, 2024 Overlays texture in color mask
    Fixed: did COLOR = col_overlay after mix, discarding mix and always
    showing overlay, blocking view. Now correctly mixes only where
    original is red (floor), and keeps original where not.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "BG"
kernel.name = "textureOverlay"
kernel.isTimeDependent = false
kernel.textureWrap = 'repeat'

kernel.vertexData =
{
  { name = "Tex_Size",  default = 144, min = 1, max = 512, index = 0, },
}

kernel.vertex =
[[

varying P_UV vec2 world_position;

P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{ 
    P_UV vec2 VERTEX = CoronaTexCoord / CoronaTexelSize.zw;
    world_position = ( gl_ModelViewMatrix * vec4(VERTEX, 0.0, 1.0)).xy;
    return position;
}
]]

kernel.fragment =
[[

float Tex_Size = CoronaVertexUserData.x;
varying vec2 world_position;
float scale = 1.0 / Tex_Size;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 base = texture2D(CoronaSampler0, UV);
    float mix_amount = floor(base.r + 0.5); // 1 where red ~1, 0 elsewhere
    vec4 overlay = texture2D(CoronaSampler1, world_position * scale);
    // was: COLOR = col_overlay (always) – now correctly mix
    P_COLOR vec4 COLOR = mix(base, overlay, mix_amount * overlay.a);
    // keep sprite alpha, background visible where base transparent
    COLOR.a = base.a;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
