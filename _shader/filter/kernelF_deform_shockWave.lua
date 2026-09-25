--[[
  Origin Author: mrsir8433
  https://godotshaders.com/author/mrsir8433/

  Expanding shockwave ring with chromatic aberration.
  Rebuilt: the 4 old params (intensity/size/tilt/speed) were never read -
  hardcoded `strength = sin(TIME)*1` / `radius = abs(sin(TIME))*1`
  overwrote everything each frame. Now Center / Strength / Radius /
  Width / Feather / Aberration are real-time, Speed sweeps the ring
  0->1 on loop (0 = static ring), and Process fades it in/out.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "shockWave"
kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Center_X','Center_Y','Strength',
            'Radius','Width','Feather','Speed',
            'Aberration','','','',
            '','','','',
        },
        default = {
            1,0.5,0.5,0.08,
            0.25,0.05,0.12,0.8,
            0.4,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,0.3,
            1,0.3,0.5,3,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Process   = u_UserData0[0][0];
vec2  Center    = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Strength  = u_UserData0[0][3];
float Radius    = u_UserData0[1][0];
float Width     = u_UserData0[1][1];
float Feather   = u_UserData0[1][2];
float Speed     = u_UserData0[1][3];
float Aberration = u_UserData0[2][0];

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_UV vec2 UV = texCoord;
  vec4 orig = texture2D( CoronaSampler0, UV );

  // expanding sweep; Speed = 0 parks the ring at Radius
  float radius = Radius;
  if ( Speed > 0.01 ) { radius = fract( CoronaTotalTime * Speed * 0.25 ); }

  float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
  vec2 st = ( UV - Center ) * vec2( aspect, 1.0 );

  float d = length( st );
  float feather = max( Feather, 0.005 );
  float width = max( Width, 0.005 );
  float ringOuter = 1.0 - smoothstep( radius - feather, radius, d );
  float ringInner = smoothstep( radius - width - feather, radius - width, d );
  float mask = clamp( ringOuter * ringInner, 0.0, 1.0 );

  vec2 dir = d > 0.0001 ? st / d : vec2( 0.0 );
  // fade the push near the loop seam so the sweep tiles cleanly
  float env = Speed > 0.01 ? smoothstep( 0.0, 0.08, radius ) * ( 1.0 - smoothstep( 0.9, 1.0, radius ) ) : 1.0;
  vec2 offset = dir * Strength * mask * env;

  vec2 abber = offset * Aberration * mask;
  vec2 base = UV - offset / vec2( aspect, 1.0 );

  vec4 warped;
  warped.r = texture2D( CoronaSampler0, base + abber ).r;
  warped.g = texture2D( CoronaSampler0, base ).g;
  warped.b = texture2D( CoronaSampler0, base - abber ).b;
  warped.a = texture2D( CoronaSampler0, base ).a;

  vec4 outc = mix( orig, warped, mask * clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = outc;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel




--[[



--]]
