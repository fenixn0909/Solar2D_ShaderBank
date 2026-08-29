--[[
    https://godotshaders.com/shader/retro-parchment-paper/
    GuoXiaoYao
    March 7, 2026
    Parchment paper with sepia, vignette, fbm noise, ink bleed & dirt.
    CC0. Filter version: CoronaSampler0 is the sprite (line art).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "parchment"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniPaper",
        paramName = {
            'Noise_Scale','Vignette_Strength','Sepia_Strength','Contrast',
            'Glow_Range','Glow_Strength','Glow_Falloff','Dirt_Strength',
            'Dirt_Scale','','','',
            '','','','',
        },
        default = {
            4, .7, .85, 1.2,
            12, .75, 2, .4,
            8, 0,0,0,
            0,0,0,0,
        },
        min = {
            1,.1,0,.5,
            1,0,.5,0,
            1,0,0,0,
            0,0,0,0,
        },
        max = {
            10,2,1,2,
            30,1,4,1,
            100,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Noise_Scale      = u_UserData0[0][0];
float Vignette_Strength= u_UserData0[0][1];
float Sepia_Strength   = u_UserData0[0][2];
float Contrast         = u_UserData0[0][3];
float Glow_Range       = u_UserData0[1][0];
float Glow_Strength    = u_UserData0[1][1];
float Glow_Falloff     = u_UserData0[1][2];
float Dirt_Strength    = u_UserData0[1][3];
float Dirt_Scale       = u_UserData0[2][0];

float rand(vec2 co){ return fract(sin(dot(co,vec2(12.9898,78.233)))*43758.5453); }
float noise(vec2 p){
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(rand(i),rand(i+vec2(1,0)),f.x),mix(rand(i+vec2(0,1)),rand(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){ return noise(p)*0.5+noise(p*2.1)*0.25+noise(p*4.3)*0.125+noise(p*8.7)*0.063; }

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec4 tex = texture2D(CoronaSampler0, UV);
    if (tex.a < 0.1) {
        P_COLOR vec4 COLOR = vec4(0.0);
        return CoronaColorScale(COLOR);
    }
    vec2 px = CoronaTexelSize.zw;
    float closest=1.0;
    vec3 nearest=vec3(0.0);
    float ga=2.399963;
    for(int i=0;i<32;i++){
        float r=sqrt(float(i+1)/32.0);
        float ang=float(i)*ga;
        float nOff=fbm(UV*10.0+vec2(float(i)*0.3))*1.5;
        vec2 off=vec2(cos(ang+nOff), sin(ang+nOff)) * r * px * Glow_Range;
        vec4 s=texture2D(CoronaSampler0, UV+off);
        if(s.a>0.1){
            float b=dot(s.rgb, vec3(0.333));
            if(b<0.45){
                if(r<closest){ closest=r; nearest=s.rgb; }
            }
        }
    }
    float glowAmt=pow(1.0-closest, Glow_Falloff) * Glow_Strength;
    float glowNoise=fbm(UV*15.0+vec2(2.3,5.1));
    glowAmt*=(0.6+glowNoise*0.8);
    glowAmt=clamp(glowAmt,0.0,1.0);
    vec3 col=tex.rgb;
    col=mix(col, nearest, glowAmt);
    float d1=fbm(UV*Dirt_Scale);
    float d2=fbm(UV*Dirt_Scale*2.3+vec2(4.1,2.7));
    float d3=fbm(UV*Dirt_Scale*0.5+vec2(1.2,8.3));
    float dirt=d1*d2*d3;
    col-=pow(dirt,1.5)*Dirt_Strength;
    col=(col-0.5)*Contrast+0.5;
    float gray=dot(col, vec3(0.299,0.587,0.114));
    vec3 sepia=vec3(gray)*vec3(1.12,0.95,0.70);
    col=mix(col, sepia, Sepia_Strength);
    float n=fbm(UV*Noise_Scale);
    float n2=fbm(UV*Noise_Scale*2.5+vec2(3.7,1.9));
    col+=(n-0.5)*0.05;
    col+=(n2-0.5)*0.025;
    float lines=sin(UV.y*500.0)*0.015 + sin(UV.y*180.0)*0.007;
    col+=lines;
    vec2 e=UV*(1.0-UV);
    float vign=pow(clamp(e.x*e.y*16.0,0.0,1.0), Vignette_Strength);
    col*=vign;
    P_COLOR vec4 COLOR=vec4(col, tex.a);
    COLOR.rgb*=COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
