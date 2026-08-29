
--[[
    https://www.youtube.com/watch?v=fgdc_2WoaD0
    

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "twistLines"


kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0, 
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed', 'Amp', 'Thick','Freq',
            'Lines','Bright','Edge','',    
            'Col1_R','Col1_G','Col1_B','Col1_A',
            '','','','',
        },
        default = {
            1.0, .5, .1, 1,
            16,  .5, 1.75, 0.0,
            .4, .81, .64, 1.0,     
            0.0, 1.0, 0.0, 1.0,
        },
        min = {
            -10, .05, 0.0, -10,
            1, 0., 0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
        },
        max = {
            10, 2, 1, 10,
            30, 1.0, 2.5, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        },
    },
}


kernel.fragment =
[[

uniform mat4 u_UserData0; // uniSetting

float Speed   = u_UserData0[0][0];
float Amp     = u_UserData0[0][1];
float Thick   = u_UserData0[0][2];
float Freq    = u_UserData0[0][3];

float Lines   = u_UserData0[1][0];
float Bright  = u_UserData0[1][1];
float Edge    = u_UserData0[1][2];

vec4 Col_Line = u_UserData0[2];

//----------------------------------------------

#define S smoothstep
#define IS(x,y,z) (1.0 - smoothstep( x,y,z ))

vec3 draw_line( vec2 uv, vec3 color, float shift, float freq ){
    uv.y += IS( 0, 1, abs(uv.x*Edge)) * sin(uv.x + shift * freq) * Amp;
    return IS( 0.0, Thick * S(-0.2, 0.9, abs(uv.x)), abs(uv.y) ) * color;
}

//-----------------------------------------------

P_COLOR vec4 COLOR = vec4(0);
vec2 iResolution = 1.0 / CoronaTexelSize.zw;
float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    vec2 uv = UV - .5;
    uv.x *= iResolution.x / iResolution.y;

    //----------------------------------------------
    float shift = TIME * Speed;
    vec3 color = vec3(0);
    
    for( float i = 0.0; i < Lines; i+= 1.0 ){
        color += draw_line( uv, Col_Line.rgb, shift + i*.4, Freq );
    }
    // was opaque black (alpha 1) even where no lines – made background invisible
    float alpha = clamp( dot(color, vec3(0.299,0.587,0.114)) * 2.0, 0.0, 1.0 );
    COLOR = vec4( color * Bright, alpha);
    COLOR.rgb *= COLOR.a;

    //----------------------------------------------

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


