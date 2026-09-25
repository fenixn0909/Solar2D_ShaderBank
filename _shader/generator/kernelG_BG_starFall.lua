
--[[
  
    Origin Author: Xor
    https://www.shadertoy.com/view/ctXGRn

    -- Volume: overhead if crank it up too much
    
    Settings:
    -- Fire Flies: {-2, 40, -0.15, -0.05}

--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "starFall"

kernel.isTimeDependent = true



kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Volume','LenX','LenY',
            'Move_Angle','','','',
            '','','','',
            '','','','',
        },
        default = {
            -1,20,0,.2,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -50,1,-.7,-.7,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            50,45,1,1,
            6.28318,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform vec4 u_resolution;


uniform P_COLOR mat4 u_UserData0;
float Speed = u_UserData0[0][0];
float Volume = u_UserData0[0][1];
float LenX = u_UserData0[0][2];    // vec2(0,0.2): rise, vec2(1,-.1): left lines
float LenY = u_UserData0[0][3];
float Move_Angle = u_UserData0[1][0];
//----------------------------------------------

int when_gt(float x, float y) { //greater than return 1
  return int(max(sign(x - y), 0.0));
}

//-----------------------------------------------
float iTime = CoronaTotalTime * Speed;
P_COLOR vec4 COLOR = vec4(0,0,0,0);
P_UV vec2 iResolution = vec2( 1, 1);

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
    {
    
    //----------------------------------------------
    // Move_Angle rotates the whole streak field so fall direction is tweakable.
    {
        vec2 cuv = UV - vec2( 0.5 );
        float ca = cos( Move_Angle );
        float sa = sin( Move_Angle );
        UV = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + vec2( 0.5 );
    }

    COLOR *= 0.;
    
    //Line dimensions (box) and position relative to line
    vec2 b = vec2( LenX, LenY), p; 
    int ip = 0 + when_gt( LenY, LenX ); // keep rainbow color after direction changed

    //Rotation matrix
    mat2 R;
    //Iterate 20 times
    for(float i=.9; i++<Volume;
        //Add attenuation
        COLOR += 1e-3/length(clamp(p=R                          //Using rotated boxes
        *(fract((UV/iResolution.y*i*.1+iTime*b)*R)-.5),-b,b)-p)
        *(cos(p[ip]/.1+vec4(0,1,2,3))+1.) )                       //My favorite color palette
        R=mat2(cos(i+vec4(0,33,11,0))                           //Rotate for each iteration
    );                         

    //----------------------------------------------
    //COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


