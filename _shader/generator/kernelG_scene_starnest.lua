
--[[
  Origin Author: haruyou27
  https://godotshaders.com/author/haruyou27/
  
  Origin shader from

  https://www.shadertoy.com/view/XlfGRj

  A beautiful yet simple shader.

  Play with parameter to see all kinds of amazing thing this shader can do.

  I use low precision in the iterations to speed up the caculation at least twice as fast. 
  Not sure if it will cause any problem.

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "scene"
kernel.name = "starnest"
kernel.isTimeDependent = true 

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Formuparam','Stepsize','Zoom',
            'Angle','','','',
            '','','','',
            '','','','',
        },
        default = {
            .3,.865,.3,.8,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -3,.5,0,-10,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3,1,.8,10,
            6.28318,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}



kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Speed = u_UserData0[0][0];
float Formuparam = u_UserData0[0][1];
float Stepsize = u_UserData0[0][2];
float Zoom = u_UserData0[0][3];
float Spin_Angle = u_UserData0[1][0];

//----------------------------------------------

int iterations = 20;
int volsteps = 20; // OVERHEAD if set it too much!

//float Formuparam = 1.00;
//float Stepsize = .3;
//float Speed = .001;
//float Zoom = .800;
float Tile = 1.857; //957

float brightness = 0.002;
float darkmatter = 0.100;
float distfading = 0.650;
float saturation = 0.750;
//----------------------------------------------

P_DEFAULT float SCurve (P_DEFAULT float value) {

    if (value < 0.5)
    {
        return value * value * value * value * value * 16.0; 
    }
    
    value -= 1.0;
    
    return value * value * value * value * value * 16.0 + 1.0;
}

//----------------------------------------------
float TIME = CoronaTotalTime*Speed;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    vec2 iResolution = 1.0 / vec2(1.0,1.0);

//----------------------------------------------

    //get coords and direction
    //vec2 uv=FRAGCOORD.xy/iResolution.xy;
    vec2 uv=UV.xy/iResolution.xy;
    uv.y*=iResolution.y/iResolution.x;
    {
        float ca = cos( Spin_Angle );
        float sa = sin( Spin_Angle );
        uv = vec2( uv.x * ca - uv.y * sa, uv.x * sa + uv.y * ca );
    }
    vec3 dir=vec3(uv*Zoom,1.);

    vec3 from=vec3(1.0,0.5,0.5);
    from-=vec3(0.0,TIME,0.0);

    //volumetric rendering
    float s=0.1,fade=1.;
    vec3 v=vec3(0.);
    for (int r=0; r<volsteps; r++) {
        lowp vec3 p=from+s*dir*0.5;
        p = abs(vec3(Tile)-mod(p,vec3(Tile*2.))); // tiling fold
        lowp float pa,a=pa=0.;
        for (int i=0; i<iterations; i++) { 
          p=abs(p)/dot(p,p)-Formuparam; // the magic formula
          a+=abs(length(p)-pa); // absolute sum of average change
          pa=length(p);
        }
        lowp float dm=max(0.,darkmatter-a*a*.001); //dark matter
        a = pow(a, 2.3); // add contrast
        if (r>6) fade*=1.-dm; // dark matter, don't render near
        v+=fade;
        v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade; // coloring based on distance
        fade*=distfading; // distance fading
        s+=Stepsize;
    }

    v=mix(vec3(length(v)),v,saturation); //color adjust

    vec4 C = vec4(v*.01,1.);

    C.r = pow(C.r, 0.35); 
    C.g = pow(C.g, 0.36); 
    C.b = pow(C.b, 0.38); 

    vec4 L = C;     

    P_COLOR vec4 finColor;

    finColor.r = mix(L.r, SCurve(C.r), 0.7); 
    finColor.g = mix(L.g, SCurve(C.g), 1.0); 
    finColor.b = mix(L.b, SCurve(C.b), 0.2); 
    finColor.a = 1;

    return CoronaColorScale(finColor);
}
]]

return kernel
