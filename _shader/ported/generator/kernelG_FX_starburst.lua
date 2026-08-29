--[[
    https://godotshaders.com/shader/starburst-effect-astronomy/
    T360
    March 9, 2026
    Starburst for space stars, procedural spikes + glow. CC0.
    Original samples noise_tex for burst variation; here procedural
    valueNoise replaces it (no extra texture).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "starburst"

kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Star_R','Star_G','Star_B','Star_A',
            'Spike_Count','Rotation_Offset','Flare_Intensity','Spike_Length',
            'Central_Glow','Glow_Size','Glow_Intensity','Master_Brightness',
            'Alpha_Thresh','Edge_Smooth','Inner_Thick','Outer_Thick',
        },
        default = {
            1, .6, .2, 1,
            4, 0, 1, 3,
            1, .01, 10, 1,
            .3, .3, .01, .01,
        },
        min = {
            0,0,0,0,
            1,0,0,.1,
            0,.01,0,0,
            0,.1,0,0,
        },
        max = {
            1,1,1,1,
            8,6.28,5,10,
            1,.04,10,5,
            1,.5,.1,.1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
vec4 Star_Color = vec4(u_UserData0[0][0],u_UserData0[0][1],u_UserData0[0][2],u_UserData0[0][3]);
float Spike_Count     = u_UserData0[1][0];
float Rotation_Offset = u_UserData0[1][1];
float Flare_Intensity = u_UserData0[1][2];
float Spike_Length    = u_UserData0[1][3];
float Central_Glow    = u_UserData0[2][0];
float Glow_Size       = u_UserData0[2][1];
float Glow_Intensity  = u_UserData0[2][2];
float Master_Brightness= u_UserData0[2][3];
float Alpha_Thresh    = u_UserData0[3][0];
float Edge_Smooth     = u_UserData0[3][1];
float Inner_Thick     = u_UserData0[3][2];
float Outer_Thick     = u_UserData0[3][3];

float hash(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
float valueNoise(vec2 p){
    vec2 i=floor(p); vec2 f=fract(p);
    float a=hash(i); float b=hash(i+vec2(1,0)); float c=hash(i+vec2(0,1)); float d=hash(i+vec2(1,1));
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 center=vec2(0.5);
    vec2 rel=UV-center;
    float dist=length(rel);
    float glow=exp(-dist / max(Glow_Size,0.001)) * Glow_Intensity;
    float angle=atan(rel.y, rel.x) / (2.0 * 3.14159265) + 0.5;
    float radial = valueNoise(vec2(angle*5.0, 0.5));
    radial = radial * Central_Glow;
    float burst = (radial / (dist + 0.1)) * 0.5;
    float spikes=0.0;
    float curThick = mix(Inner_Thick, Outer_Thick, clamp(dist*2.0,0.0,1.0));
    int count=int(Spike_Count);
    for(int i=0;i<8;i++){
        if(i>=count) break;
        float spike_ang=(float(i)*6.28318/float(count))+Rotation_Offset;
        vec2 dir=vec2(cos(spike_ang), sin(spike_ang));
        float proj=abs(rel.x*dir.y - rel.y*dir.x);
        float side=step(0.0, dot(rel, dir));
        float line=smoothstep(curThick, 0.0, proj) * side;
        spikes=max(spikes, line);
    }
    spikes *= exp(-dist * Spike_Length);
    float combined=(glow + (burst*0.5) + (spikes*Flare_Intensity)) * Master_Brightness;
    float alpha=smoothstep(Alpha_Thresh, Alpha_Thresh+Edge_Smooth, combined);
    vec3 col=mix(vec3(0.0), Star_Color.rgb, combined);
    col+=pow(combined,4.0);
    P_COLOR vec4 COLOR=vec4(col, alpha);
    COLOR.rgb*=COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
