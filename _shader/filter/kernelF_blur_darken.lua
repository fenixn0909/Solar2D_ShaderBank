--[[
    https://godotshaders.com/shader/darkened-blur/
    LambBrainz Aug 25, 2024
    Fixed: was filter with no vertexData (hardcoded strength 2, lod 0,
    mix 0.3). Now exposes Strength/Lod/Mix as real-time params.
--]]
local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "darken"
kernel.isTimeDependent = false

kernel.vertexData = {
  { name = "Strength", default = 2, min = 1, max = 12, index = 0, },
  { name = "Lod",      default = 0, min = 0, max = 5,  index = 1, },
  { name = "Mix",      default = 0.3, min = 0, max = 1, index = 2, },
}

kernel.fragment =
[[

//----------------------------------------------

uniform float lod = 0.0;
uniform float mix_percentage = 0.3;
int strength = 2;

vec4 blur_size(sampler2D tex,vec2 fragCoord, vec2 pixelSize) {
    vec4 color = vec4(0.);
    float sf = float(strength);
    vec2 pixel = fragCoord/pixelSize;
    int x_min = int(max(pixel.x-sf, 0));
    int x_max = int(min(pixel.x+sf, 1./pixelSize.x));
    int y_min = int(max(pixel.y-sf, 0));
    int y_max = int(min(pixel.y+sf, 1./pixelSize.y));
    int count =0;
    for(int x=x_min; x <= x_max; x++) {
        for(int y = y_min; y <= y_max; y++) {
            color += texture2D(tex, vec2(float(x), float(y)) * pixelSize);
            count++;
        }
    }
    color /= float(count);
    return color;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    int   Strength = int(CoronaVertexUserData.x + 0.5);
    float Lod      = CoronaVertexUserData.y;
    float Mix      = CoronaVertexUserData.z;
    strength = Strength;
    lod = Lod;
    mix_percentage = Mix;

    vec4 color = blur_size( CoronaSampler0, UV, CoronaTexelSize.zw );
    P_COLOR vec4 COLOR = mix(color, vec4(0,0,0,color.a), mix_percentage);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
