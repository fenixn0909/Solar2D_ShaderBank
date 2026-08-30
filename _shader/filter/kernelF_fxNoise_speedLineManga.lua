

--[[
  https://godotshaders.com/shader/speedlines-manga-style/
  yo1
  September 28, 2024
--]]


local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "fxNoise"
kernel.name = "speedLineManga"

--Test
kernel.isTimeDependent = true

kernel.vertexData   = nil
kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Line_Color_A_R','Line_Color_A_G','Line_Color_A_B','Line_Color_A_A',
            'Line_Color_B_R','Line_Color_B_G','Line_Color_B_B','Line_Color_B_A',
            'Back_Color_R','Back_Color_G','Back_Color_B','Back_Color_A',
            'Line_Threshold','Speed','Line_Length','Angle',
        },
        default = {
            1,1,1,1,
            0,1,1,1,
            .171,.1,0,1,
            .999,.07,1000,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,10,0,
        },
        max = {
            3,3,3,1,
            3,3,3,1,
            1,1,1,1,
            1,1,4000,360,
        },
    },
}
kernel.fragment = [[

uniform P_COLOR mat4 u_UserData0;

vec4  line_color_a    = vec4( u_UserData0[0][0], u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3] );
vec4  line_color_b    = vec4( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
vec4  back_color      = vec4( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float line_threshold  = u_UserData0[3][0];
float speed            = u_UserData0[3][1];
float line_length     = u_UserData0[3][2];
float angle             = u_UserData0[3][3];

//----------------------------------------------

P_COLOR vec4 COLOR;

//----------------------------------------------


//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    //P_UV vec2 UV = UV;
    float TIME = mod(CoronaTotalTime, 10);
    //----------------------------------------------

    vec2 uv = vec2(UV.x * cos(radians(angle)) - UV.y * sin(radians(angle)), UV.x * sin(radians(angle)) + UV.y * cos(radians(angle)));
    vec4 noise_line = texture2D(CoronaSampler0, vec2(uv.x / line_length + fract(TIME) * speed, uv.y));
    if (noise_line.r < line_threshold){
      COLOR = back_color;
    } else {
      COLOR = mix(line_color_a, line_color_b, 1.0 - noise_line.r);
    }

    //----------------------------------------------
    //COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]
return kernel

--[[


--]]

