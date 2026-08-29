 
--[[
    https://godotshaders.com/shader/radial-shine-highlight/
    Josephsmithberger
    November 20, 2024
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "radialShine"


kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Spread','Cutoff','Size','Speed',
            'Ray1_Density','Ray2_Density','Ray2_Intensity','Core_Intensity',
            'Seed','Hdr','','',
            '','','','',
        },
        default = {
            .2, 2.1, .5, 1,
            8, 10, .13, .2,
            15, 0, 0,0,
            0,0,0,0,
        },
        min = {
            .05, .5, .1, 0,
            1, 1, 0, 0,
            0, 0, 0,0,
            0,0,0,0,
        },
        max = {
            1, 4, 2, 5,
            30, 30, 1, 1,
            100, 1, 1,1,
            1,1,1,1,
        },
    },
}


kernel.fragment =
[[

//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
//uniform sampler2D gradient;
uniform P_COLOR mat4 u_UserData0;

float spread          = u_UserData0[0][0];
float cutoff          = u_UserData0[0][1];
float size             = u_UserData0[0][2];
float speed             = u_UserData0[0][3];
float ray1_density     = u_UserData0[1][0];
float ray2_density     = u_UserData0[1][1];
float ray2_intensity   = u_UserData0[1][2];
float core_intensity   = u_UserData0[1][3];
float seed              = u_UserData0[2][0];
bool hdr = u_UserData0[2][1] > 0.5;

const float PI = 3.14159265359;


//----------------------------------------------

float random(vec2 _uv) {
    return fract(sin(dot(_uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0-2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec4 screen(vec4 base, vec4 blend){
    return 1.0 - (1.0 - base) * (1.0 - blend);
}


// -----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime * speed;


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  
    P_UV vec2 SCREEN_UV = UV;
    //----------------------------------------------
  
    vec2 centered_uv = (UV - 0.5) * size;
    float radius = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x) + PI; // Add PI to fix left side cutoff
    
    vec2 ray1 = vec2(angle * ray1_density + TIME * speed + seed + sin(angle * 3.0), radius * 2.0);
    vec2 ray2 = vec2(angle * ray2_density + TIME * speed * 1.5 + seed + cos(angle * 2.0), radius * 2.0);
    
    float cut = 1.0 - smoothstep(cutoff, cutoff + 0.2, radius);
    ray1 *= cut;
    ray2 *= cut;
    
    float rays = hdr ? 
        noise(ray1) + (noise(ray2) * ray2_intensity) :
        clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0., 1.);
    
    rays *= smoothstep(spread, spread * 0.3, radius);
    float core = smoothstep(0.2, 0.0, radius) * core_intensity;
    rays += core;
    
    vec4 gradient_color = texture2D(CoronaSampler1, vec2(rays, 0.5));
    vec3 shine = vec3(rays) * gradient_color.rgb;
    
    float blur_amount = radius * 0.1;
    vec2 blur_uv = SCREEN_UV + centered_uv * blur_amount;
    vec4 blurred = texture2D(CoronaSampler0, blur_uv);
    //vec4 blurred = vec4( 1.0, 1.0, 1.0, .0);
    shine = screen(blurred, vec4(shine, rays)).rgb;
    
    COLOR = vec4(shine, rays * gradient_color.a);

    //----------------------------------------------
    //COLOR.rgb *= blurred.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
    

--]]


