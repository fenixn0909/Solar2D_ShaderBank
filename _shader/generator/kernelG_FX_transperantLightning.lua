
--[[
  Transparent Lightning

  https://godotshaders.com/shader/energy-beams/
  Beider
  June 6, 2024

--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "transperantLightning"

kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniTint",
        paramName = {
            'Angle','Base_R','Base_G','Base_B',
            'Glow_R','Glow_G','Glow_B','Thickness',
            'Base_A','Glow_A','Speed','Glow',
            'AmpX','AmpY','','',
        },
        default = {
            0,1,1,1,
            .2,0,.8,.02,
            1,0,1,.08,
            2,1,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,.001,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            6.28318,1,1,1,
            1,1,1,.2,
            1,1,10,2,
            50,50,0,0,
        },
    },
}


kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Bolt_Angle   = u_UserData0[0][0];
vec4 base_color = vec4(u_UserData0[0][1],u_UserData0[0][2],u_UserData0[0][3],u_UserData0[2][0]);
vec4 glow_color = vec4(u_UserData0[1][0],u_UserData0[1][1],u_UserData0[1][2],u_UserData0[2][1]);
float thickness = u_UserData0[1][3];
float Speed = u_UserData0[2][2];
float Glow = u_UserData0[2][3];
float AmpX = u_UserData0[3][0];
float AmpY = u_UserData0[3][1];


//----------------------------------------------

uniform int lightning_number = 5;
vec2 Amplitude = vec2( AmpX, AmpY );
uniform float offset = 0.5;
float alpha = 1.0; // : hint_range(0, 1)


//----------------------------------------------

//P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );
P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;
const float PI = 3.14159265359;

//----------------------------------------------

// plot function 
float plot(vec2 st, float pct, float half_width){
  return  smoothstep( pct-half_width, pct, st.y) -
          smoothstep( pct, pct+half_width, st.y);
}

vec2 hash22(vec2 uv) {
    uv = vec2(dot(uv, vec2(127.1,311.7)),
              dot(uv, vec2(269.5,183.3)));
    return 2.0 * fract(sin(uv) * 43758.5453123) - 1.0;
}

float noise(vec2 uv) {
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, fuv);
    return mix(mix(dot(hash22(iuv + vec2(0.0,0.0)), fuv - vec2(0.0,0.0)),
                   dot(hash22(iuv + vec2(1.0,0.0)), fuv - vec2(1.0,0.0)), blur.x),
               mix(dot(hash22(iuv + vec2(0.0,1.0)), fuv - vec2(0.0,1.0)),
                   dot(hash22(iuv + vec2(1.0,1.0)), fuv - vec2(1.0,1.0)), blur.x), blur.y) + 0.5;
}

float fbm(vec2 n) {
    float total = 0.0, amp = 1.0;
    for (int i = 0; i < 7; i++) {
        total += noise(n) * amp;
        n += n;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------



P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  
  //----------------------------------------------

  vec2 uv = UV;
  // Rotate bolt field around center so Angle tweaks strike direction.
  {
    vec2 cuv = uv - vec2( 0.5 );
    float ca = cos( Bolt_Angle );
    float sa = sin( Bolt_Angle );
    uv = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + vec2( 0.5 );
  }
  vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
  
  vec2 t ;
  float y ;
  float pct ;
  float buffer; 
  // add more lightning
  for ( int i = 0; i < lightning_number; i++){
    t = uv * Amplitude + vec2(float(i), -float(i)) - TIME*Speed;
    y = fbm(t)*offset;
    pct = plot(uv, y, thickness);
    buffer = plot(uv, y, Glow);
    color += pct*base_color;
    color += buffer*glow_color;
  }
  
  color.a *= alpha;
  COLOR = color;

  //COLOR.rgb *= color.a;
  //----------------------------------------------


  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[



--]]


