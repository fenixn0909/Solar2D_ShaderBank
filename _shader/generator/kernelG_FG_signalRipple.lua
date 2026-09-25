
--[[
    https://godotshaders.com/shader/colorful-signal-effect/
    LoganB September 4, 2023
    A colorful signal effect for 2D games.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FG"
kernel.name = "signalRipple"


kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Speed','Size','Zoom','Color_Mix',
            'Color_R','Color_G','Color_B','Glow',
            'Center_X','Center_Y','Ring_Sharp','Swirl',
            'Pulse','','','',
        },
        default = {
            5,.8,8,.7,
            .3,.6,1,.8,
            .5,.5,2.5,0,
            1,0,0,0,
        },
        min = {
            -30,0,-150,0,
            0,0,0,0,
            0,0,.5,-3,
            0,0,0,0,
        },
        max = {
            30,20,150,1,
            1,1,1,2,
            1,1,8,3,
            3,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Speed = u_UserData0[0][0];
float Size = u_UserData0[0][1];
float Zoom = u_UserData0[0][2];
float Color_Mix = u_UserData0[0][3];
vec3 Tint = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Glow = u_UserData0[1][3];
vec2 Center = vec2( u_UserData0[2][0], u_UserData0[2][1] );
float Ring_Sharp = u_UserData0[2][2];
float Swirl = u_UserData0[2][3];
float Pulse = u_UserData0[3][0];
//----------------------------------------------

// -----------------------------------------------

P_COLOR vec4 fragColor;
P_DEFAULT float TIME = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{

  //----------------------------------------------

  vec2 cuv = UV - Center;
  float ca = cos( Swirl );
  float sa = sin( Swirl );
  vec2 ruv = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + Center;

  float d = length((ruv-Center)*2.0);
  float t = pow(smoothstep(0.9,0.2,d),0.35);

  // Rainbow base, tintable toward a solid signal color.
  vec3 rainbow = 0.5 + 0.5*cos(TIME*Pulse+ruv.xyx*3.0+vec3(0,2,4));
  vec3 base = mix( Tint, rainbow, Color_Mix );
  vec4 color = vec4(base,1.0);

  d = sin(Zoom*d - Speed*TIME);
  d = abs(d);
  d = pow( max( d, 0.0001 ), 1.0 / max( Ring_Sharp, 0.1 ) );
  d = Size/max(d, 0.0001);
  float intensity = clamp( d*t*( 0.5 + Glow ), 0.0, 1.0 );

  // No black fill: transparent where the rings are dark.
  vec3 rgb = base * intensity;
  fragColor = vec4( rgb, intensity );

  //----------------------------------------------

  return CoronaColorScale( fragColor );
}
]]

return kernel

--[[
    
--]]


