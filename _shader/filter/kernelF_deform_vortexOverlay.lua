--[[
  Origin Author: 9exa
  https://godotshaders.com/shader/vortex-overlay/

  Elliptical vortex that twists the sprite around its center.
  Rebuilt: the old version mixed toward an uninitialized transparent-
  black COLOR and skipped premultiply, so the sprite faded to nearly
  invisible; its sliders were also overridden by a hardcoded
  sin(TIME) line and two params shared one vertex index. Now the twist
  is a clean UV rotation that always keeps the sprite visible:
  Process fades it, Intensity sets the twist, Radius sets the vortex
  size, Speed slowly rotates it (0 = static).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "vortexOverlay"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Process",   default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Intensity", default = 1,   min = 0, max = 4,  index = 1, },
  { name = "Radius",    default = 0.5, min = 0.1, max = 0.75, index = 2, },
  { name = "Speed",     default = 0.6, min = 0, max = 3,  index = 3, },
}

kernel.fragment =
[[

vec2 rotate_vx( vec2 p, float angle )
{
  float c = cos( angle );
  float s = sin( angle );
  return vec2( c * p.x - s * p.y, s * p.x + c * p.y );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process   = CoronaVertexUserData.x;
  float Intensity = CoronaVertexUserData.y;
  float Radius    = CoronaVertexUserData.z;
  float Speed     = CoronaVertexUserData.w;

  vec4 orig = texture2D( CoronaSampler0, UV );

  float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
  vec2 pc = ( UV - vec2( 0.5 ) ) * vec2( aspect, 1.0 );
  float d = length( pc );

  // twist strongest at center, relaxing to the rim + slow spin
  float fall = 1.0 - smoothstep( 0.0, max( Radius, 0.05 ), d );
  float angle = Intensity * fall * fall * 6.28318 + CoronaTotalTime * Speed;

  vec2 warpedUV = vec2( 0.5 ) + rotate_vx( UV - vec2( 0.5 ), angle );
  vec4 warped = texture2D( CoronaSampler0, warpedUV );

  // fade the warp out at the rim so it melts back into the sprite
  float m = ( 1.0 - smoothstep( max( Radius - 0.12, 0.0 ), Radius, d ) )
          * clamp( Process, 0.0, 1.0 );
  vec4 outc = mix( orig, warped, clamp( m, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = outc;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}

]]

return kernel


--[[

--]]
