--[[
  Origin Author: snesmocha
  https://godotshaders.com/author/snesmocha/

  Tutorial followed from here:
  https://www.youtube.com/watch?v=BZp8DwPdj4s

  Axial skew (slant) for sprites.
  Rebuilt: the old file was a vertex wobble driven by hardcoded
  sin(TIME) lines - the 4 sliders did nothing. Now a fragment UV skew
  where every slider is live: Process (1st, straight -> skewed),
  Skew_X / Skew_Y slant amounts, Speed sways the slant over time
  (0 = hold still). Pushed-out pixels go transparent, never streak.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "skew"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Skew_X",  default = 0.3, min = -1, max = 1, index = 1, },
  { name = "Skew_Y",  default = 0,   min = -1, max = 1, index = 2, },
  { name = "Speed",   default = 0,   min = 0, max = 5,  index = 3, },
}

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process = CoronaVertexUserData.x;
  float Skew_X  = CoronaVertexUserData.y;
  float Skew_Y  = CoronaVertexUserData.z;
  float Speed   = CoronaVertexUserData.w;

  vec4 orig = texture2D( CoronaSampler0, UV );

  // optional sway around the chosen slant; Speed = 0 holds still
  float sway = 1.0;
  if ( Speed > 0.01 ) { sway += sin( CoronaTotalTime * Speed ) * 0.45; }

  vec2 c = UV - vec2( 0.5 );
  vec2 skewUV = vec2( 0.5 ) + vec2(
      c.x + c.y * Skew_X * sway,
      c.y + c.x * Skew_Y * sway );

  vec4 warped;
  if ( skewUV.x < 0.0 || skewUV.x > 1.0 || skewUV.y < 0.0 || skewUV.y > 1.0 )
  {
      warped = vec4( 0.0 );
  }
  else
  {
      warped = texture2D( CoronaSampler0, skewUV );
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
