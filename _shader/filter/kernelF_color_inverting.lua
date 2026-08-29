--[[
    https://godotshaders.com/shader/invert-color-ddd/
    SpeedyShaderZZZ Aug 5, 2024
    Fixed: had progress param declared but commented out, and used
    hardcoded frequency 20 + TIME. Now Progress blends original vs
    inverted, controlled real-time.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "inverting"

kernel.vertexData =
{
  { name = "Progress", default = 0, min = 0, max = 1, index = 0, },
  { name = "Frequency",default = 0, min = 0, max = 30, index = 1, },
}

kernel.isTimeDependent = true

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float Progress  = CoronaVertexUserData.x;
    float Frequency = CoronaVertexUserData.y;
    if (Frequency > 0.1) {
        float phase = sign(sin(CoronaTotalTime * Frequency));
        if (phase < 0.0) Progress = 1.0;
    }
    vec4 tex = texture2D(CoronaSampler0, UV);
    vec3 inv = vec3(1.0) - tex.rgb;
    vec3 col = mix(tex.rgb, inv, clamp(Progress,0.0,1.0));
    P_COLOR vec4 COLOR = vec4(col, tex.a);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
