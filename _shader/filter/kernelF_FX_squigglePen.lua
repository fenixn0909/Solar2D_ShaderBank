--[[
    https://godotshaders.com/shader/squiggle-pen-canvas-post-process/
    Br0skinator
    May 13, 2026
    Squiggle Pen – post-process hand-drawn look. Original combines
    Squigglevision + Line art, sampling SCREEN_TEXTURE, noise texture,
    and background_texture. Here CoronaSampler0 is the screen (snapshot),
    noise is procedural valueNoise (no extra texture), background is a
    uniform color. CC0.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "squigglePen"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniLines",
        paramName = {
            'Weight','Line_Thickness','Opacity','Scale_X',
            'Scale_Y','Strength','Fps','Bg_R',
            'Bg_G','Bg_B','Bg_A','Color_R',
            'Color_G','Color_B','','',
        },
        default = {
            .07, 1, 1, 10,
            10, .5, 6, 1,
            1, 1, 1, 0,
            0, 0, 0,0,
        },
        min = {
            0, 0, 0, 1,
            1, 0, 1, 0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            0.3, 6, 1, 30,
            30, 2, 30, 1,
            1,1,1,0,
            1,1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Line_R','Line_G','Line_B','',
            '','','','',
            '','','','',
            '','','','',
        },
        default = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        min =     { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, },
        max =     { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
//----------------------------------------------

float Weight        = u_UserData0[0][0];
float Line_Thickness= u_UserData0[0][1];
float Opacity       = u_UserData0[0][2];
vec2  Scale         = vec2(u_UserData0[0][3], u_UserData0[1][0]);
float Strength      = u_UserData0[1][1];
float Fps           = u_UserData0[1][2];
vec3  Bg_Color      = vec3(u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1]);
float Bg_A          = u_UserData0[2][2];
vec3  Line_Color    = vec3(u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2]);

float TIME = CoronaTotalTime;
const float PI = 3.14159265359;
const float E = 2.71828182846;

// procedural noise (valueNoise) instead of noise texture
float hash(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
float valueNoise(vec2 p){
    vec2 i=floor(p); vec2 f=fract(p);
    float a=hash(i); float b=hash(i+vec2(1,0)); float c=hash(i+vec2(0,1)); float d=hash(i+vec2(1,1));
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // noise_uv equivalent: world coords simplified to UV * scale
    vec2 noise_uv = UV * 0.1 + vec2(0.0); // scale already in procedural freq
    vec2 offset_mult = vec2(PI, E);
    vec2 noise_offset = vec2(floor(TIME * Fps)) * offset_mult;
    // sample procedural noise at noise_uv*10 + offset
    float noise_sample = valueNoise(noise_uv * 10.0 + noise_offset) * 4.0 * PI;
    vec2 direction = vec2(cos(noise_sample), sin(noise_sample));
    vec2 squiggle_uv = UV + direction * Strength * 0.005;

    // edge detection on squiggled screen
    vec3 current = texture2D(CoronaSampler0, squiggle_uv).rgb;
    vec3 right   = texture2D(CoronaSampler0, squiggle_uv + vec2(CoronaTexelSize.zw.x * Line_Thickness, 0.0)).rgb;
    vec3 bottom  = texture2D(CoronaSampler0, squiggle_uv - vec2(0.0, CoronaTexelSize.zw.y * Line_Thickness)).rgb;
    float r_dist = length(current - right);
    float b_dist = length(current - bottom);

    vec4 bg = vec4(Bg_Color, Bg_A);
    vec4 solid = vec4(Line_Color, 1.0);
    vec4 line_tex = (r_dist > Weight || b_dist > Weight) ? mix(bg, solid, Opacity) : bg;

    P_COLOR vec4 COLOR = line_tex;
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
