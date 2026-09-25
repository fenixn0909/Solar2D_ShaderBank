--[[
  Origin Author: ChaffDev
  https://godotshaders.com/shader/tilt-shift-shader/

  Miniature tilt-shift: a sharp horizontal band, blur above and below.
  Round 3: Process is now the 1st param, and the blur is a much wider
  2-ring 16-tap blur - the old single 2px ring was nearly invisible on
  small sprites. Alpha is always the sprite's own (never black bars).
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "tiltShift"
kernel.vertexData =
{
  { name = "Process",   default = 1,   min = 0, max = 1,   index = 0, },
  { name = "Blur",      default = 2.5, min = 0, max = 8,   index = 1, },
  { name = "Limit",     default = 0.3, min = 0, max = 0.5, index = 2, },
  { name = "Intensity", default = 0.4, min = 0, max = 1,   index = 3, },
}

kernel.isTimeDependent = false

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process   = CoronaVertexUserData.x;
  float Blur      = CoronaVertexUserData.y;
  float Limit     = CoronaVertexUserData.z;
  float Intensity = CoronaVertexUserData.w;

  vec4 sharp = texture2D( CoronaSampler0, texCoord );

  // explicit 2-ring blur (no lod-bias: sprites have no mipmaps)
  vec2 px = CoronaTexelSize.zw * Blur * 2.0;
  vec2 px2 = px * 2.0;
  vec3 acc = sharp.rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( px.x, 0.0 ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - vec2( px.x, 0.0 ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( 0.0, px.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - vec2( 0.0, px.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + px ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - px ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( px.x, -px.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( -px.x, px.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( px2.x, 0.0 ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - vec2( px2.x, 0.0 ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( 0.0, px2.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - vec2( 0.0, px2.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + px2 ).rgb;
  acc += texture2D( CoronaSampler0, texCoord - px2 ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( px2.x, -px2.y ) ).rgb;
  acc += texture2D( CoronaSampler0, texCoord + vec2( -px2.x, px2.y ) ).rgb;
  vec3 blurred = acc / 17.0;

  // focus band [Limit, 1-Limit]; blur grows outside it.
  float feather = max( Intensity, 0.01 ) * 0.5 + 0.01;
  float mTop = 1.0 - smoothstep( Limit - feather, Limit, texCoord.y );
  float mBot = smoothstep( 1.0 - Limit, 1.0 - Limit + feather, texCoord.y );
  float m = clamp( mTop + mBot, 0.0, 1.0 ) * clamp( Process, 0.0, 1.0 );

  vec3 col = mix( sharp.rgb, blurred, m );

  P_COLOR vec4 COLOR = vec4( col, sharp.a );
  COLOR.rgb *= COLOR.a;

  return CoronaColorScale( COLOR );
}
]]

return kernel
