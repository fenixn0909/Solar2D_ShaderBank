
--[[
    https://godotshaders.com/shader/squigglevision/
    tentabrobpy
    October 16, 2025

    Renamed from the original post's title, a trademarked animation
    technique name - the effect itself (per-frame wobbly redraw look,
    aka "boiling lines") is generic.

    paint1 = the sprite (CoronaSampler0), paint2 = a seamless
    greyscale noise texture (CoronaSampler1). Two simplifications:
    dropped the original's world-space coordinate system (keeps the
    squiggle pattern anchored across multiple object instances sharing
    one noise texture - not something a single Solar2D filter/composite
    invocation needs), using local UV directly instead; and dropped
    textureSize() (auto-detects the noise texture's resolution to scale
    it correctly) since there's no precedent for it elsewhere in this
    bank - Scale is a plain tunable instead, adjust it to match your
    noise texture by eye.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "handDrawnShimmer"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Scale",    default = 4,  min = .5, max = 32, index = 0, },
  { name = "Strength", default = 1,  min = 0,  max = 5,  index = 1, },
  { name = "Fps",       default = 6,  min = 1,  max = 24, index = 2, },
}


kernel.fragment =
[[

#define PI 3.14159265359
#define E 2.71828182846

float Scale     = CoronaVertexUserData.x;
float Strength   = CoronaVertexUserData.y;
float Fps         = CoronaVertexUserData.z;

float TIME = CoronaTotalTime;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 noise_uv = UV * Scale;

    vec2 noise_offset = vec2( floor( TIME * Fps ) ) * vec2( PI, E );
    float noise_sample = texture2D( CoronaSampler1, noise_uv + noise_offset ).r * 4.0 * PI;

    vec2 direction = vec2( cos( noise_sample ), sin( noise_sample ) );
    vec2 squiggle_uv = UV + direction * Strength * 0.005;

    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, squiggle_uv );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

