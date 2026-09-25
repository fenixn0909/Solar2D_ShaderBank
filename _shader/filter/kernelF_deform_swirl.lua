--[[
  Origin Author: casualgaragecoder
  https://godotshaders.com/author/casualgaragecoder/

  Swirl the sprite around its center.
  Rebuilt: the 4 old params (intensity/size/tilt/speed) were never read -
  a hardcoded `ratio = abs(sin(TIME*0.5))` overwrote everything. Now
  every slider is live and Process is 1st: Ratio (1 = straight sprite,
  lower = tighter fold), Size (swirl radius), Spin (twist rate).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "swirl"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,    min = 0, max = 1,   index = 0, },
  { name = "Ratio",   default = 0.45, min = 0.05, max = 1, index = 1, },
  { name = "Size",    default = 0.7,  min = 0.1, max = 1, index = 2, },
  { name = "Spin",    default = 1,    min = 0, max = 5,   index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process = CoronaVertexUserData.x;
  float Ratio   = CoronaVertexUserData.y;
  float Size    = CoronaVertexUserData.z;
  float Spin    = CoronaVertexUserData.w;

  vec4 orig = texture2D( CoronaSampler0, texCoord );

  vec2 uv = texCoord * 2.0 - vec2( 1.0 );
  float len = length( uv );

  // twist strongest at center, relaxing to Size; TIME slowly turns it
  float gate = 1.0 - smoothstep( 0.0, max( Size * 1.4142, 0.05 ), len );
  float ang = ( 1.0 - Ratio ) * ( 2.0 + Spin * 3.0 ) * gate
            + CoronaTotalTime * Spin * 0.4 * gate;

  float s = sin( ang );
  float c = cos( ang );
  vec2 trs = uv * mat2( vec2( c, s ), vec2( -s, c ) );
  trs /= pow( max( Ratio, 0.05 ), 2.0 );
  trs = trs * 0.5 + vec2( 0.5 );

  vec4 warped;
  if ( trs.x > 1.0 || trs.x < 0.0 || trs.y > 1.0 || trs.y < 0.0 )
  {
      warped = vec4( 0.0 ); // prevent sprite leaking, stay transparent
  }
  else
  {
      warped = texture2D( CoronaSampler0, trs );
  }

  vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = outc;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}

]]

return kernel


--[[

--]]
