
--[[
    https://www.shadertoy.com/view/XXtBRr
    xxidbr9 in 2025-01-14
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "balatro"


kernel.isTimeDependent = true


kernel.uniformData =
{
    {
        index = 0, 
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Spin_Speed','Spin_Rotation','Spin_Amount','Spin_Ease',
            'Offset_X','Offset_Y','Contrast','Ligthing',
            'Pixel_Filter','','','',
            '','','',''
        },
        default = {
            7, -2, .25, 1.,
            0,0, 3.5, .4, 
            745., 0,0,0,
            0,0,0,0,
        },
        min = {
             -100, -5, -4, 0,
             -1, -1, -5, -5,
             .0, 0, 0, 0,
             0, 0, 0, 0,
        },
        max = {
            100, 10, 10, 10,
            1, 1.0, 10, 5,
            1000.0, 1.0, 1.0, 1,
            1.0, 1.0, 1.0, 1,
        },
    },
}




kernel.fragment =
[[

uniform mat4 u_UserData0; 
//----------------------------------------------

float Spin_Speed    = u_UserData0[0][0];
float Spin_Rotation = u_UserData0[0][1];
float Spin_Amount   = u_UserData0[0][2];
float Spin_Ease     = u_UserData0[0][3];
float Offset_X      = u_UserData0[1][0];
float Offset_Y      = u_UserData0[1][1];
float Contrast      = u_UserData0[1][2];
float Ligthing      = u_UserData0[1][3];
float Pixel_Filter  = u_UserData0[2][0];

vec2 Offset = vec2( Offset_X, Offset_Y );

//----------------------------------------------


#define COLOUR_1 vec4(0.871, 0.267, 0.231, 1.0)
#define COLOUR_2 vec4(0.0, 0.42, 0.706, 1.0)
#define COLOUR_3 vec4(0.086, 0.137, 0.145, 1.0)
#define PI 3.14159265359


float TIME = CoronaTotalTime;


//----------------------------------------------

vec4 effect(vec2 screenSize, vec2 screen_coords) {
    float pixel_size = length(screenSize.xy) / Pixel_Filter;
    vec2 uv = (floor(screen_coords.xy*(1./pixel_size))*pixel_size - 0.5*screenSize.xy)/length(screenSize.xy) - Offset;
    float uv_len = length(uv);
    
    float speed = (Spin_Rotation*Spin_Ease*0.2) + 302.2;
    float new_pixel_angle = atan(uv.y, uv.x) + speed - Spin_Ease*20.*(1.*Spin_Amount*uv_len + (1. - 1.*Spin_Amount));
    vec2 mid = (screenSize.xy/length(screenSize.xy))/2.;
    uv = (vec2((uv_len * cos(new_pixel_angle) + mid.x), (uv_len * sin(new_pixel_angle) + mid.y)) - mid);
    
    uv *= 30.;
    speed = TIME*(Spin_Speed);
    vec2 uv2 = vec2(uv.x+uv.y);
    
    for(int i=0; i < 5; i++) {
        uv2 += sin(max(uv.x, uv.y)) + uv;
        uv  += 0.5*vec2(cos(5.1123314 + 0.353*uv2.y + speed*0.131121),sin(uv2.x - 0.113*speed));
        uv  -= 1.0*cos(uv.x + uv.y) - 1.0*sin(uv.x*0.711 - uv.y);
    }
    
    float contrast_mod = (0.25*Contrast + 0.5*Spin_Amount + 1.2);
    float paint_res = min(2., max(0.,length(uv)*(0.035)*contrast_mod));
    float c1p = max(0.,1. - contrast_mod*abs(1.-paint_res));
    float c2p = max(0.,1. - contrast_mod*abs(paint_res));
    float c3p = 1. - min(1., c1p + c2p);
    float light = (Ligthing - 0.2)*max(c1p*5. - 4., 0.) + Ligthing*max(c2p*5. - 4., 0.);
    return (0.3/Contrast)*COLOUR_1 + (1. - 0.3/Contrast)*(COLOUR_1*c1p + COLOUR_2*c2p + vec4(c3p*COLOUR_3.rgb, c3p*COLOUR_1.a)) + light;
}
//-----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);
P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    COLOR = effect(iResolution.xy, UV * iResolution.xy);
    //----------------------------------------------

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


