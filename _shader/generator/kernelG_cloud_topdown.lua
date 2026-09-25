
--[[

    https://www.shadertoy.com/view/4tdSWr

    

    Find and go #VARIATION and tweak them for different patterns

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "cloud"
kernel.name = "topdown"


kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Brightness','Cover','Zoom',
            'Move_Angle','','','',
            '','','','',
            '','','','',
        },
        default = {
            .25,.85,.1,1.1,
            .785398,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            -20,-2,-10,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            20,2,10,50,
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
float Brightness = u_UserData0[0][1];
float Cover = u_UserData0[0][2];
float Zoom = u_UserData0[0][3];
float Move_Angle = u_UserData0[1][0];
vec2 Move_Dir = vec2( cos( Move_Angle ), sin( Move_Angle ) );

P_UV vec2 iResolution = vec2(1,1);
//----------------------------------------------

const float Darkness = .5;
const float Cloudalpha = 8;
const float Skytint = .5;

P_COLOR const vec3 Col_Sky1 = vec3(0.2, 0.4, 0.6);
P_COLOR const vec3 Col_Sky2 = vec3(0.4, 0.7, 1.0);

// No Sky Color
//const vec3 Col_Sky1 = vec3(0.0, 0.0, 0.0);
//const vec3 Col_Sky2 = vec3(0.0, 0.0, 0.0);

const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

//----------------------------------------------
vec2 hash( vec2 p ) {
    p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}


const float K1 = 0.366025404; // (sqrt(3)-1)/2;
const float K2 = 0.211324865; // (3-sqrt(3))/6;

float noise( in vec2 p ) {
    vec2 i = floor(p + (p.x+p.y)*K1); 
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));  
}

float fbm(vec2 n) {
    float total = 0.0, amplitude = 0.1;
    for (int i = 0; i < 7; i++) {
        total += noise(n) * amplitude;
        n = m * n;
        amplitude *= 0.4;
    }
    return total;
}

float when_gt(float x, float y) { //greater than return 1
    return max(sign(x - y), 0.0);
}

// -----------------------------------------------

P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

    //----------------------------------------------
  
    vec2 p = UV;
    vec2 uv = UV;    

    // Tweaking Shape  #VARIATION
    //TIME = CoronaTotalTime + 100;
    //uv.x = uv.x*TIME* 100;
    //uv.y = uv.y*TIME* 1.5;

    float time = TIME * Speed;
    // Directional drift: at the 45-degree default this equals the
    // original diagonal (time,time) drift exactly.
    vec2 drift = Move_Dir * ( time * 1.41421356 );
    float q = fbm(uv * Zoom * 0.5);

    //ridged noise shape
    float r = 0.0;
    uv *= Zoom;
    uv -= q - drift;
    float weight = 0.8;
    for (int i=0; i<8; i++){
    r += abs(weight*noise( uv ));
        uv = m*uv + drift;
    weight *= 0.7;
    }

    //noise shape
    float f = 0.0;
    uv = p*vec2(iResolution.x/iResolution.y,1.0);
    uv *= Zoom;
    uv -= q - drift;
    weight = 0.7;
    for (int i=0; i<8; i++){
    f += weight*noise( uv );
        uv = m*uv + drift;
    weight *= 0.6;
    }

    f *= r + f;

    //noise colour
    float c = 0.0;
    time = TIME * Speed * 2.0;
    drift = Move_Dir * ( time * 1.41421356 );
    uv = p*vec2(iResolution.x/iResolution.y,1.0);
    uv *= Zoom*2.0;
    uv -= q - drift;
    weight = 0.4;
    for (int i=0; i<7; i++){
    c += weight*noise( uv );
        uv = m*uv + drift;
    weight *= 0.6;
    }

    //noise ridge colour
    float c1 = 0.0;
    time = TIME * Speed * 3.0;
    drift = Move_Dir * ( time * 1.41421356 );
    uv = p*vec2(iResolution.x/iResolution.y,1.0);
    uv *= Zoom*3.0;
    uv -= q - drift;
    weight = 0.4;
    for (int i=0; i<7; i++){
    c1 += abs(weight*noise( uv ));
        uv = m*uv + drift;
    weight *= 0.6;
    }

    c += c1;

    vec3 Col_Sky = mix(Col_Sky2, Col_Sky1, p.y);
    vec3 cloudcolour = vec3(1.1, 1.1, 0.2) * clamp((Darkness + Brightness*c), 0.0, 1.0);

    // No Sky Color
    //vec3 Col_Sky = vec3(0,0,0);
    //vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp((Darkness + Brightness*c), 0.0, 1.0);


    f = Cover + Cloudalpha*f*r;

    vec3 result = mix(Col_Sky, clamp(Skytint * Col_Sky + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));
    
    COLOR = vec4( result, 1.0);

    //----------------------------------------------

    // Rid Off Darker Color  #VARIATION
    float alpha = when_gt( result.r, 0.5) *0.95;
    COLOR = vec4( result, alpha );
    // Cloud Only < Need "Rid Off Darker Color" ON >      #VARIATION
    //COLOR.rgb *= COLOR.a;


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


