
--[[

  Origin Author:  tomorrowevening
  https://www.shadertoy.com/view/XsX3zl

  THE COLORS MAN, THE COLORS.
  Inspired by @WAHa_06x36's sine puke

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "color"
kernel.name = "melt70s"


kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Zoom','Brightness','Scale',
            'Swirl','Color_Shift','Vignette','Flow',
            '','','','',
            '','','','',
        },
        default = {
            6,40,.95,1,
            1,0,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,2,.5,-8,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            20,200,2,8,
            3,6.28318,2,3,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Speed = u_UserData0[0][0];
float Zoom = u_UserData0[0][1];
float Brightness = u_UserData0[0][2];
float Scale = u_UserData0[0][3];
float Swirl = u_UserData0[1][0];
float Color_Shift = u_UserData0[1][1];
float Vignette = u_UserData0[1][2];
float Flow = u_UserData0[1][3];

//----------------------------------------------

#ifdef GL_ES
precision mediump float;
#endif
#define RADIANS 0.017453292519943295


//----------------------------------------------
float cosRange(float degrees, float range, float minimum) {
    return (((1.0 + cos(degrees * RADIANS)) * 0.5) * range) + minimum;
}

//----------------------------------------------

P_UV vec2 iResolution = vec2( 1, 1 );
P_DEFAULT float iTime = CoronaTotalTime;
P_COLOR vec4 COLOR;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_UV vec2 fragCoord = UV / iResolution;
    
    //----------------------------------------------

    float time = iTime * Speed;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 p  = (2.0*fragCoord.xy-iResolution.xy)/max(iResolution.x,iResolution.y);
    // Swirl spins the domain; Flow scales the drift boosts.
    {
        vec2 cuv = p;
        float ca = cos( Swirl * time * 0.1 );
        float sa = sin( Swirl * time * 0.1 );
        p = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca );
    }
    float ct = cosRange(time*5.0, 3.0, 1.1);
    float xBoost = cosRange(time*0.2, 5.0, 5.0) * Flow;
    float yBoost = cosRange(time*0.1, 10.0, 5.0) * Flow;

    float fScale = cosRange(time * 15.5, 1.25, 0.5) * Scale ;

    for(int i=1;i<Zoom;i++) {
        float _i = float(i);
        vec2 newp=p;
        newp.x+=0.25/_i*sin(_i*p.y+time*cos(ct)*0.5/20.0+0.005*_i)*fScale+xBoost;       
        newp.y+=0.25/_i*sin(_i*p.x+time*ct*0.3/40.0+0.03*float(i+15))*fScale+yBoost;
        p=newp;
    }

    vec3 col=vec3(0.5*sin(3.0*p.x+Color_Shift)+0.5,0.5*sin(3.0*p.y+Color_Shift*1.3)+0.5,sin(p.x+p.y+Color_Shift));
    col *= Brightness;
      
    // Add border
    float vigAmt = 5.0 * Vignette;
    float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));
    float extrusion = (col.x + col.y + col.z) / 4.0;
    extrusion *= 1.5;
    extrusion *= vignette;

    //----------------------------------------------
    COLOR = vec4(col, extrusion);

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


