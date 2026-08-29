
--[[
    https://godotshaders.com/shader/analog-monitor/
    cyanone
    November 15, 2023
--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "blur"
kernel.name = "monitorAM" -- Analog Monochrome Monitor

kernel.isTimeDependent = true
kernel.textureWrap = 'repeat'



kernel.vertexData =
{
    { name = "Progress",      default =  1, min = 0, max = 1, index = 0, },
  { name = "Mix",           default =  1, min = 0., max = 1, index = 1, },
    { name = "Pixel_Size",    default = .02, min = 0.005, max = 0.05, index = 2, },
    { name = "Contrast",      default = .5, min = -1, max = 1, index = 3, },
} 



kernel.fragment =
[[

float Mix = CoronaVertexUserData.y;
float Pixel_Size = CoronaVertexUserData.z;
float Contrast = CoronaVertexUserData.w;  

//----------------------------------------------

bool greyscale = false;  // whether to greyscale the image or not before applying tiletexture

//float Mix = 0.5 ; //: hint_range(0.0, 1.0)  // how much of the tiled texture to show (1 recommended) 
//float Pixel_Size = 0.01;    // size of pixelation effect
//float Contrast = 0.5;     // whether to greyscale the image or not before applying tiletexture

vec4 Col_Pixel = vec4( 0.6, 1.0, 0.6, 1 );   // the overriding color of the tiled texture, white by default
vec4 Col_BG = vec4( 0.2, 0.7, 0.7, 1 ); // : source_color;   // the overriding color of the background, black by default

//----------------------------------------------

// Convert to Greyscale using luminosity method if aplicable
vec4 to_grayscale(vec4 color) {
    float luminance = 0.21 * color.r + 0.72 * color.g + 0.07 * color.b;
    return vec4(luminance, luminance, luminance, color.a);
}

// Adjust contrast of the greyscale image
vec4 adjust_contrast(vec4 color) {
    color.rgb = (color.rgb - 0.5) * max(Contrast, 0.0) + 0.5;
    return color;
}

// Applies the tiled texture on top of the original texture imitating 
// photoshop's HARD MIX blending mode
vec4 hard_mix(vec4 color1, vec4 color2) {
    vec4 result; // The resulting texture
    for (int i = 0; i < 4; i++) { // loop through the four channels
        float value = color1[i] + color2[i]; // add the values of the two colors
        if (value >= 1.0) { // if the value is greater than or equal to 1.0, set it to 1.0
            result[i] = 1.0;
        } else { // otherwise, set it to 0.0
            result[i] = 0.0;
        }
    }
    return result; // return the result color
}

//----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);
P_DEFAULT float TIME = CoronaTotalTime; // * speed

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    P_UV vec2 SCREEN_UV = UV;

    //----------------------------------------------

    vec2 uv = SCREEN_UV;
    vec2 uv2 = SCREEN_UV;
    
    // apply pixelation on the base texture
    uv = floor(uv / Pixel_Size) * Pixel_Size;
    vec4 color1 = texture2D( CoronaSampler0, uv );
    float alpha = color1.a;

    // apply greyscale adjustments if applicable
    if (greyscale) {
        color1 = to_grayscale(color1);
        color1 = adjust_contrast(color1);
    }
    
    // apply hard mix blending
    vec4 color2 = texture2D( CoronaSampler1, uv2 / Pixel_Size );
    vec4 final_result = mix(color1, hard_mix(color1, color2), Mix);
    //vec4 final_result = mix(color1, hard_mix(color1, Col_Pixel), Mix);
    
    // replace default white with desired color
    if (final_result == vec4(1.0, 1.0, 1.0, 1.0)) {
        //final_result = Col_Pixel;
        //final_result = mix(final_result, Col_Pixel, sin(mod(TIME,4.) ) );
        final_result = mix(final_result, Col_Pixel, 1 );
        // replace default black background with desired color
    } else {
        if (final_result == vec4(0.0, 0.0, 0.0, 1.0)) {
            //final_result = Col_BG;
            
        }
    }
    
    // assign final texture
    COLOR = final_result;
    //----------------------------------------------
    
    // Restrict to texture alpha
    COLOR.a = alpha;
    COLOR.rgb *= COLOR.a;


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


