 
--[[
    https://godotshaders.com/shader/radial-plasma-shield/
    Vaquers
    January 30, 2022

--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "plasmaShield"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0, 
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Angle','Angle_Spread','Border_Offset',
            'Edges_Value','Edges_Fade','','',
            'Col1_R','Col1_G','Col1_B','Col1_A',
            'Col2_R','Col2_G','Col2_B','Col2_A',
        },
        default = {
            .5, 0, 0, .5,
            .5, .5, 0, 0,
            0.0, 0.0, 1.0, 1.0,     
            0.0, 1.0, 0.0, 1.0,
        },
        min = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
        },
        max = {
            1., 6.283184, 6.283184, 1.,
            1., 1., 0, 0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        },
    },
}

kernel.fragment =
[[

uniform mat4 u_UserData0; // uniSetting
//----------------------------------------------


float Progress = u_UserData0[0][0];    //: hint_range(0.0, 1.0);
float Angle = u_UserData0[0][1];   //: hint_range(0.0, 6.283184);
float Angle_Spread = u_UserData0[0][2];    //: hint_range(0.1, 3.141592);
float Border_Offset = u_UserData0[0][3];    //: hint_range(0.0, 1.0);
float Edges_Value = u_UserData0[1][0]; //: hint_range(0.0, 1.0);
float Edges_Fade = u_UserData0[1][1];  //: hint_range(0.0, 1.0);
vec4 Col_Plasma = u_UserData0[2];    //: hint_color;
vec4 Col_Edge = u_UserData0[3] ;  //: hint_color;



//float Progress = 1.0  ;    //: hint_range(0.0, 1.0);
//float Angle =  6.283184 ;   //: hint_range(0.0, 6.283184);
//float Angle_Spread =  3.141592 ;    //: hint_range(0.1, 3.141592);
//float Border_Offset = .5  ;    //: hint_range(0.0, 1.0);
//float Edges_Value = .5  ; //: hint_range(0.0, 1.0);
//float Edges_Fade =  .5 ;  //: hint_range(0.0, 1.0);
//vec4 Col_Plasma = vec4(1)  ;    //: hint_color;
//vec4 Col_Edge = vec4(.5)  ;  //: hint_color;

//----------------------------------------------

//----------------------------------------------

P_COLOR vec4 COLOR;
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  
    //----------------------------------------------
    vec2 center = vec2(0.5);
    vec2 center_uv = normalize(UV - center);
    float is = 1.0 - smoothstep(max(0.49*Progress, 0.001), max(0.5*Progress, 0.002), distance(center, UV));
    
    vec2 frst_border = vec2(cos(Angle+Angle_Spread/2.0), sin(Angle+Angle_Spread/2.0));
    vec2 sec_boreder = vec2(cos(Angle-Angle_Spread/2.0), sin(Angle-Angle_Spread/2.0));
    
    vec2 radial_center = vec2(cos(Angle), sin(Angle));
    
    float posx = step(0.0, radial_center.x); // is radial_center.x positive
    float posy = step(0.0, radial_center.y); // is radial_center.y positive
    
    // using different formulas for different radial_center.x signs
    float is2 = step(min(frst_border.x, sec_boreder.x), center_uv.x)*posx; 
    float is3 = step(center_uv.x, max(frst_border.x, sec_boreder.x))*(1.0 - posx);
    
    // using different formulas for different radial_center.y signs
    float is4 = step(min(frst_border.y, sec_boreder.y), center_uv.y)*posy;
    float is5 = step(center_uv.y, max(frst_border.y, sec_boreder.y))*(1.0-posy);
    
    // how close to frontier is
    float border_factor = 1.0 - distance(2.0*(UV - center), center_uv);
    border_factor = pow(border_factor, Border_Offset*50.0); // speeding up center fading
    
    // how close to radial center is
    float radial_center_factor = 1.0 - distance(center_uv, radial_center)/distance(frst_border, radial_center);
    
    // how close ro radial edges is
    float edge_radial_factor = (1.0 - radial_center_factor) * Edges_Value;
    
    // applying edge fading
    float edge_fade_factor = mix(radial_center_factor, 1.0, 1.0-Edges_Fade);
    
    COLOR.a = min(1.0, is2+is3)*min(1.0, is4+is5)*is*border_factor*mix(Col_Plasma.a, Col_Edge.a, edge_radial_factor)*edge_fade_factor;
    COLOR.rgb = mix(Col_Plasma.rgb, Col_Edge.rgb, edge_radial_factor);
    //----------------------------------------------
    //COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


