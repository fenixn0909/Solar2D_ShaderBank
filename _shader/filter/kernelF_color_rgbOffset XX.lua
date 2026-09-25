--[[
  Origin Author: snesmocha
  https://godotshaders.com/author/snesmocha/

  RGB channel split / offset with optional animated scanline glitch.
  Fixed: the old file only had a vertex-deformation kernel and no
  fragment stage (plus 4 boring unused params), so no RGB effect was
  ever visible. Now Amount/Angle/Glitch/Process drive a real fragment
  RGB-split. See the trailing comment for the original Godot draft.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "rgbOffset"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,     min = 0,   max = 1,    index = 0, },
  { name = "Amount",  default = 0.012, min = 0,   max = 0.1,  index = 1, },
  { name = "Angle",   default = 0,     min = 0,   max = 360,  index = 2, },
  { name = "Glitch",  default = 0,     min = 0,   max = 1,    index = 3, },
}

kernel.fragment =
[[
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process = CoronaVertexUserData.x;
  float Amount  = CoronaVertexUserData.y;
  float Angle   = CoronaVertexUserData.z;
  float Glitch  = CoronaVertexUserData.w;

  vec2 dir = vec2( cos( radians( Angle ) ), sin( radians( Angle ) ) ) * Amount;

  // animated per-scanline jitter; 0 = clean static split
  if ( Glitch > 0.001 )
  {
      float line = floor( UV.y * 220.0 );
      float tick = floor( CoronaTotalTime * 24.0 );
      float n = fract( sin( line * 12.9898 + tick * 78.233 ) * 43758.5453 );
      dir.x += ( n - 0.5 ) * Glitch * 0.12;
  }

  P_COLOR vec4 orig = texture2D( CoronaSampler0, UV );
  float r = texture2D( CoronaSampler0, UV - dir ).r;
  float b = texture2D( CoronaSampler0, UV + dir ).b;

  vec3 split = vec3( r, orig.g, b );
  vec3 col = mix( orig.rgb, split, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, orig.a );
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel


--[[

shader_type canvas_item;
render_mode unshaded;

uniform sampler2D displace : hint_albedo;
uniform float dispAmt: hint_range(0,0.1);
uniform vec2 abberationAmtXR = vec2(0,0);
uniform vec2 abberationAmtXG =  vec2(0,0);
uniform vec2 abberationAmtXB =  vec2(0,0);

uniform float dispSize: hint_range(0.1, 2.0);
uniform float maxAlpha : hint_range(0.1,1.0);

void fragment()
{
    //displace effect
    vec4 disp = texture(displace, SCREEN_UV * dispSize);
    vec2 newUV = SCREEN_UV + disp.xy * dispAmt;
    //abberation
    COLOR.r = texture(SCREEN_TEXTURE, newUV - abberationAmtXR).r;
    COLOR.g = texture(SCREEN_TEXTURE, newUV + abberationAmtXG).g;
    COLOR.b = texture(SCREEN_TEXTURE, newUV + abberationAmtXB).b;
    COLOR.a = texture(SCREEN_TEXTURE, newUV).a * maxAlpha;
    }

--]]
