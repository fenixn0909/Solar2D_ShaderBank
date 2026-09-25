
--[[
    https://godotshaders.com/shader/rain-and-snow-with-parallax-scrolling-effect/
    Steampunkdemon July 9, 2023

--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FG"
kernel.name = "rainSnow"


kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'BaseSpd','Amount','Slant','FarRainW',
            'Move_Angle','','','',
            '','','','',
            '','','','',
        },
        default = {
            .5,500,.2,.2,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -5,0,-10,-1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            5,1000,10,1,
            6.28318,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float BaseSpd = u_UserData0[0][0];
float Amount = u_UserData0[0][1];
float Slant = u_UserData0[0][2];    // vec2(0,0.2): rise, vec2(1,-.1): left lines
float FarRainW = u_UserData0[0][3];
float Move_Angle = u_UserData0[1][0];
//----------------------------------------------

//uniform float BaseSpd = 0.0; // : hint_range(0.1, 1.0) 
//uniform float Amount = 500.0; //500
//uniform float Slant = .2; // : hint_range(-1.0, 1.0) 
//uniform float FarRainW = .5; // : hint_range(0.1, 1.0) 


uniform float near_rain_length = 0.015; // : hint_range(0.01, 1.0) 
uniform float far_rain_length = 0.025; // : hint_range(0.01, 1.0) 
uniform float near_rain_width = 1.0; // : hint_range(0.1, 1.0) 
uniform float near_rain_transparency = 1.0; // : hint_range(0.1, 1.0) 
uniform float far_rain_transparency = 1.5; // : hint_range(0.1, 1.0) 
// Replace the below reference to source_color with hint_color if you are using a version of Godot before 4.
uniform vec4 rain_color = vec4(0.6, 0.7, 0.8, 1.0); // : source_color 

uniform float additional_rain_speed = 0.2; // : hint_range(0.1, 1.0) 

uniform vec4 color = vec4( .0, .05, .1, 0); // : hint_range(-1.0, 1.0) 


// -----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    //P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 COLOR = color;

    P_DEFAULT float TIME = CoronaTotalTime;
    //P_DEFAULT float alpha = abs(sin(CoronaTotalTime)) -0.15;
    //----------------------------------------------

    // To control the rainfall from your program comment out the below line and add a new uniform above as:
    // uniform float time = 10000.0;
    // Then update the time uniform from your _physics_process function by adding delta. You can then pause the rainfall by not changing the time uniform.
    float time = 10000.0 + TIME;

    // Uncomment the following line if you are applying the shader to a TextureRect and using a version of Godot before 4.
    //  COLOR = texture(TEXTURE,UV);

    // Move_Angle rotates the fall direction so rain/snow drift is tweakable.
    vec2 baseUV = UV;
    {
        vec2 cuv = baseUV - vec2( 0.5 );
        float ca = cos( Move_Angle );
        float sa = sin( Move_Angle );
        baseUV = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + vec2( 0.5 );
    }

    vec2 uv = vec2(0.0);
    float remainder = mod(baseUV.x - baseUV.y * Slant, 1.0 / Amount);
    uv.x = (baseUV.x - baseUV.y * Slant) - remainder;
    float rn = fract(sin(uv.x * Amount));
    uv.y = fract((baseUV.y + rn));


    vec4 rainC;
    // Blurred trail. Works well for rain:
    //rainC = mix(COLOR, rain_color, smoothstep(1.0 - (far_rain_length + (near_rain_length - far_rain_length) * rn), 1.0, fract(uv.y - time * (BaseSpd + additional_rain_speed * rn))) * (far_rain_transparency + (near_rain_transparency - far_rain_transparency) * rn) * step(remainder * Amount, FarRainW + (near_rain_width - FarRainW) * rn));

    // No trail. Works well for snow:
    rainC = mix(COLOR, rain_color, step(1.0 - (far_rain_length + (near_rain_length - far_rain_length) * rn), fract(uv.y - time * (BaseSpd + additional_rain_speed * rn))) * (far_rain_transparency + (near_rain_transparency - far_rain_transparency) * rn) * step(remainder * Amount, FarRainW + (near_rain_width - FarRainW) * rn));

    COLOR = rainC;
    //----------------------------------------------


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
    
    void fragment() {
    
    }
--]]


