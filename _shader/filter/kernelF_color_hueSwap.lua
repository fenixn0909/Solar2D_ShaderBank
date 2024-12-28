--[[
  
  https://godotshaders.com/shader/color-swap-with-hue-variation-preservation/
  noidexe
  May 4, 2023

--]]



local kernel = {}

kernel.language = "glsl"

kernel.category = "filter"
kernel.group = "color"
kernel.name = "hueSwap"


kernel.uniformData =
{
    {
        index = 0, 
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'From_R', 'From_G', 'From_B','From_A',
            'To_R','To_G','To_B','To_A',    
            'Tolerance','','','',
            '','','','',
        },
        default = {
            1.0, 1.0, 1.0, 1.0,
            0.0, 0.0, 0.0, 0.0,
            0.5, 0.0, 0.0, 0.0,    
            0.0, 0.0, 0.0, 0.0,
        },
        min = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
        },
        max = {
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            10.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        },
    },
}



kernel.fragment =
[[
uniform sampler2D TEXTURE;
uniform mat4 u_UserData0; // uniSetting

vec4 Col_From = u_UserData0[0];
vec4 Col_To = u_UserData0[1];
float Tolerance = u_UserData0[2][1];

//----------------------------------------------

// Color space conversion from https://godotshaders.com/shader/color-range-swap/
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    
    //----------------------------------------------
    float _tol = Tolerance * Tolerance;
        
    vec4 tex = texture2D(TEXTURE, UV);
    vec3 source_hsv = rgb2hsv(tex.rgb);
    vec3 initial_hsv = rgb2hsv(Col_From.rgb);
    vec3 hsv_shift = rgb2hsv(Col_To.rgb) - initial_hsv;
    
    float hue = initial_hsv.r;
    
    // the .r here represents HUE, .g is SATURATION, .b is LUMINANCE
    if (hue - source_hsv.r >= -_tol && hue - source_hsv.r <= +_tol)
    {
        vec3 final_hsv = source_hsv + hsv_shift;
        tex.rgb = hsv2rgb(final_hsv);
    }
    
    COLOR = tex;

    //----------------------------------------------
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[


--]]
