--[[
    https://godotshaders.com/shader/discrete-clouds/
    Moraguma, October 14, 2024

    Fixed: `layer_count` was a non-constant loop bound (GLES compile
    risk), COLOR was left unset when no layer hit (black screen), and
    the only params were boring resolutionX/Y. The sprite image itself
    is the noise source (tiled scroll) - try different sprites.
    Fun tweakings: Process (1st, sprite -> clouds), Speed (drift),
    Layers (2-12 depth slices), Coverage (how much sky turns cloudy).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "BG"
kernel.name = "discreteClouds"

kernel.isTimeDependent = true

kernel.vertexData =
{
  { name = "Process",  default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Speed",    default = 0.2, min = 0, max = 1,  index = 1, },
  { name = "Layers",   default = 7,   min = 2, max = 12, index = 2, },
  { name = "Coverage", default = 0.5, min = 0, max = 1,  index = 3, },
}

kernel.fragment =
[[

vec4 lerp_dc( vec4 a, vec4 b, float w ) { return a + w * ( b - a ); }
float rand_dc( float n ) { return fract( sin( n ) * 43758.5453123 ); }

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Process  = CoronaVertexUserData.x;
  float Speed    = CoronaVertexUserData.y;
  float LayersF  = CoronaVertexUserData.z;
  float Coverage = CoronaVertexUserData.w;

  vec4 bottom_color = vec4( 1.0, 0.95, 0.75, 1.0 );
  vec4 top_color    = vec4( 0.0, 0.20, 0.30, 1.0 );

  float y = 1.0 - UV.y;

  // sky gradient fallback so we never output unset/black
  vec4 clouds = lerp_dc( bottom_color, top_color, y );

  int layers = int( clamp( LayersF + 0.5, 2.0, 12.0 ) );
  for ( int i = 0; i < 12; i++ )
  {
      if ( i >= layers ) break;
      float h = float( i ) / float( layers - 1 );
      // the sprite image itself is the noise source (tiled scroll)
      float n = texture2D( CoronaSampler0, vec2( fract( UV.x * 2.0 + rand_dc( h ) * 3.0 ),
                                                 fract( y * 2.0 - CoronaTotalTime * Speed + h ) ) ).r;
      float shape = y - sqrt( max( 1.0 - pow( y - h, 2.0 ), 0.0 ) )
                        * ( 0.25 + Coverage ) * ( 0.35 + n );
      if ( shape < h )
      {
          clouds = lerp_dc( bottom_color, top_color, h );
          break;
      }
  }

  vec4 orig = texture2D( CoronaSampler0, UV );
  vec3 col = mix( orig.rgb, clouds.rgb, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( col, 1.0 );
  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
