--[[
    https://godotshaders.com/shader/aetherial-flow/
    vegetable
    May 6, 2026
    MIT. Aetherial Flow: sine-wave displacement + radial ripple + swirl
    vortex, base/edge colors, glow/pulse, hue shift via noise. Original
    uses noise_tex (repeat) for wave modulation; here procedural
    valueNoise stands in (no extra texture). CC0? Actually MIT per page.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "aetherialFlow"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniAnim",
        paramName = {
            'Time_Factor','Wave_Strength','Ripple_Speed','Noise_Scale',
            'Glow_Intensity','Edge_Pulse','Swirl_Strength','Hue_Shift_Speed',
            'Base_R','Base_G','Base_B','Base_A',
            'Edge_R','Edge_G','Edge_B','Edge_A',
        },
        default = {
            1, .05, 1, 1,
            1.5, 1, .5, 1,
            1,1,1,1,
            1,.5,.7,1,
        },
        min = {
            0,0,0,0,
            0,0,-2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            5,.5,5,5,
            5,2,2,5,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------
float Time_Factor    = u_UserData0[0][0];
float Wave_Strength  = u_UserData0[0][1];
float Ripple_Speed   = u_UserData0[0][2];
float Noise_Scale    = u_UserData0[0][3];
float Glow_Intensity = u_UserData0[1][0];
float Edge_Pulse     = u_UserData0[1][1];
float Swirl_Strength = u_UserData0[1][2];
float Hue_Shift_Speed= u_UserData0[1][3];
vec4 Base_Color      = vec4(u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3]);
vec4 Edge_Color      = vec4(u_UserData0[3][0], u_UserData0[3][1], u_UserData0[3][2], u_UserData0[3][3]);
float TIME = CoronaTotalTime;

float hash(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
float valueNoise(vec2 p){
    vec2 i=floor(p); vec2 f=fract(p);
    float a=hash(i); float b=hash(i+vec2(1,0)); float c=hash(i+vec2(0,1)); float d=hash(i+vec2(1,1));
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}
vec3 rgb2hsv(vec3 c){
    vec4 K=vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p=mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q=mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d=q.x - min(q.w, q.y);
    return vec3(abs((q.w - q.y)/(6.0*d + 1e-10) + q.z), d/(q.x + 1e-10), q.x);
}
vec3 hsv2rgb(vec3 c){
    vec3 p=abs(fract(c.xxx + vec3(0.0, 1.0/3.0, 2.0/3.0))*6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}
vec2 get_swirl_uv(vec2 uv, float strength){
    vec2 center=vec2(0.5);
    vec2 diff=uv-center;
    float dist=length(diff);
    float ang=atan(diff.y, diff.x) + strength * (0.5 - dist) * sin(TIME * 0.5);
    return center + vec2(cos(ang), sin(ang)) * dist;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    float t = TIME * Time_Factor;
    float nval = valueNoise(uv * Noise_Scale + t * 0.05);
    uv.y += sin(uv.x * 10.0 + t) * Wave_Strength * nval;
    uv.x += cos(uv.y * 10.0 + t * 0.5) * Wave_Strength * nval;
    float dist_center = distance(uv, vec2(0.5));
    uv += sin(dist_center * 20.0 - t * Ripple_Speed) * (Wave_Strength * 0.5 * nval);
    uv = get_swirl_uv(uv, Swirl_Strength);
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    vec4 tex = texture2D(CoronaSampler0, uv);
    vec3 hsv = rgb2hsv(tex.rgb * Base_Color.rgb);
    hsv.x = fract(hsv.x + t * 0.1 * Hue_Shift_Speed);
    hsv.y = clamp(hsv.y + 0.2 * nval, 0.0, 1.0);
    vec3 final_rgb = hsv2rgb(hsv);
    float edge_mask = smoothstep(0.35, 0.5, dist_center);
    final_rgb += edge_mask * Edge_Pulse * Edge_Color.rgb;
    float pulse = 0.8 + 0.2 * sin(t);
    final_rgb *= (Glow_Intensity * pulse);
    final_rgb += 0.03 * vec3(sin(t * 3.0), cos(t * 2.0), nval * 0.1);
    P_COLOR vec4 COLOR = vec4(final_rgb, tex.a);
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
