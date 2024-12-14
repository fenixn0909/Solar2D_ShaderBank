--[[
    https://godotshaders.com/shader/qi-aura-outline/
    JInDaifer
    August 31, 2024

    Enable texure mipmaps:
    Texture file > Import > Generate Mipmaps

    Enable any mipmaps filter:
    CanvasItem > Filter > LinearMipmaps

    In pixel art it looks weird.

    Hi, this is a “simple” shader (I mean, I can only change colors :V), after hours of typing, plus about 2 tutorials (there aren’t many, or I don’t know how to search :V) I got this.

    I hope you like it and enjoy it.

    Hola, este es un sombreador “simple” (quiero decir, solo puedo cambiar colores :V), después de horas de escribir, además de unos 2 tutoriales (no hay muchos, o no sé buscar :V) Tengo esto
  
    ✳️ NEED mipmap! ✳️ not working on Solar2D?

]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "aura"
kernel.name = "qiAura"
kernel.isTimeDependent = true

-- Expose effect parameters using vertex data
kernel.vertexData   = {
  {
    name = "intensity",
    default = 0.65, 
    min = 0,
    max = 1,
    index = 0,  -- This corresponds to "CoronaVertexUserData.x"
  },
  {
    name = "size",
    default = 0.1, 
    min = 0,
    max = 1,
    index = 1,  -- This corresponds to "CoronaVertexUserData.y"
  },
  {
    name = "tilt",
    default = 0.2, 
    min = 0.0,
    max = 2.0,
    index = 2,  -- This corresponds to "CoronaVertexUserData.z"
  },
  {
    name = "speed",
    default = 1.0, 
    min = 0.1,
    max = 10.0,
    index = 3,  -- This corresponds to "CoronaVertexUserData.w"
  },
}

kernel.fragment =
[[
uniform vec2 ScaleMult = vec2(1.0);

float Progress = 0.0; //:hint_range(0.0, 1.0, 0.1)
uniform float TextureLaodMult = 8.0; //:hint_range(0.0, 10.0, 0.01) 
uniform float Tilling = 26.0; //:hint_range(0.0, 60.0, 0.01) = 
uniform vec2 MovementDirSpeed = vec2(-0.6, 1.0);
uniform vec2 MovementDirSpeed2 = vec2(0.6, 1.0);
uniform vec2 Noise_Seed = vec2(1.0);
//uniform sampler2D color_gradiant :repeat_enable, filter_linear_mipmap;

uniform P_DEFAULT float texNoiseScaler = 0.8;


//GradientColors
P_COLOR vec4 grad_S = vec4( 1.0, 0.7, 0.7, 1.0 );
P_COLOR vec4 grad_E = vec4( 0.5, 0.7, 1.0, 1.0 );


float Freq = 10;    // Frequency
float Amplitude = 1.5;     // Amplitude 



P_DEFAULT float TIME = CoronaTotalTime;

//----------------------------------------------

vec2 random(vec2 uv){
  uv += Noise_Seed;
  uv = vec2( dot(uv, vec2(127.1,311.7) ),
    dot(uv, vec2(269.5,183.3) ) );
  return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);
    float bottom_left = dot(random(uv_index + vec2(0.0, 0.0)), uv_fract - vec2(0.0, 0.0));
    float bottom_right = dot(random(uv_index + vec2(1.0, 0.0)), uv_fract - vec2(1.0, 0.0));
    float top_left = dot(random(uv_index + vec2(0.0, 1.0)), uv_fract - vec2(0.0, 1.0));
    float top_right = dot(random(uv_index + vec2(1.0, 1.0)), uv_fract - vec2(1.0, 1.0));
    float bottom_mix = mix(bottom_left, bottom_right, blur.x);
    float top_mix = mix(top_left, top_right, blur.x);
    float final_value = mix(bottom_mix, top_mix, blur.y);
    // Ajustamos para que el resultado esté en el rango de 0.0 a 1.0
    return (final_value + 1.0) * 0.5;
}
vec4 AuraEffect(vec2 uv, vec4 CurrentColor, sampler2D OriginTexTure){
  vec2 TimeUV = MovementDirSpeed * TIME;//direction
  vec2 TimeUV2 = MovementDirSpeed2 * TIME;//direction
  vec2 ScaleMultFractment = (1.0 - ScaleMult)/2.0;//Scale the outline
  vec2 compos_uv = uv * ScaleMult + ScaleMultFractment; //Scale the outline
  //I don't know about shaders but I got this, this was the key.----> noise(uv * Tilling + TimeUV) * 8.0
  //vec4 alpha = textureLod(OriginTexTure, compos_uv, noise(uv * Tilling + TimeUV) * TextureLaodMult);
  vec4 alpha = texture2D(OriginTexTure, compos_uv);
  alpha += noise(uv * Tilling + TimeUV) * TextureLaodMult;
  //vec4 GradientColors = texture(color_gradiant, fract( vec2(-uv.y, uv.x) + (TimeUV * 0.4)) ) * 3.0;
  vec4 GradientColors = mix( grad_S, grad_E, uv.x);
  

  vec4 sil = GradientColors * noise(uv * Tilling - TimeUV);
  sil.a = alpha.a * noise(uv * Tilling + TimeUV) * noise(uv * Tilling + TimeUV2) * 5.0;
  //return sil;
  //return sil * Progress;
  //return GradientColors;
  return mix(CurrentColor, sil * Progress,  (1.0 - CurrentColor.a));
}

//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // Test
    Progress = abs(sin(CoronaTotalTime * Freq)) * Amplitude ;

    
    //----------------------------------------------


    P_UV vec2 uvSpr = UV;
    P_UV vec2 uvNoise = UV * texNoiseScaler;
    P_COLOR vec4 colorSpr = texture2D(CoronaSampler0, uvSpr);
    //P_COLOR vec4 colorNoise = texture2D(CoronaSampler1, uvNoise);


    //P_COLOR vec4 COLOR = AuraEffect(UV, colorSpr, colorNoise);
    P_COLOR vec4 COLOR = AuraEffect(UV, colorSpr, CoronaSampler1);
    
    //----------------------------------------------
    //COLOR.r = 1.0;
    COLOR.rgb *= COLOR.a;


    return CoronaColorScale( COLOR );


    

}
]]

return kernel





--[[

]]









