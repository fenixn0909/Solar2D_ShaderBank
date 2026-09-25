--[[
  Origin Author: nimitz (Shadertoy MdlXRS, flow-noise with swirls)
  https://www.shadertoy.com/view/MdlXRS

  Fixed: `p *= mat2` is illegal GLSL (needs m * v), and the only
  params were boring texWidth/texHeight. The flow field is UV-based and
  the sprite image itself is the noise source (like the original).
  Fun tweakings: Process (1st, sprite -> flow), Speed (0 = frozen),
  Scale (zoom), Style (0 poison / 1 lava / 2 ocean / 3 gold).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "BG"
kernel.name = "noiseAnimFlow"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Speed", default = 0.6, min = 0, max = 2,  index = 1, },
  { name = "Scale", default = 6,   min = 2, max = 14, index = 2, },
  { name = "Style", default = 0,   min = 0, max = 3,  index = 3, },
}

kernel.fragment =
[[
#define TAU_FLOW 6.2831853

mat2 makem2_flow( float theta )
{
    float c = cos( theta );
    float s = sin( theta );
    return mat2( c, -s, s, c );
}

// the sprite image itself is the noise source (tiled)
float vnoise_flow( vec2 x )
{
    return texture2D( CoronaSampler0, fract( x * 0.08 ) ).x;
}

float grid_flow( vec2 p ) { return sin( p.x ) * cos( p.y ); }

float flow_main( vec2 p, float t )
{
    float z = 6.0;
    float rz = 0.0;
    vec2 bp = p;
    mat2 m2 = mat2( 0.80, 0.60, -0.60, 0.80 );
    for ( int i = 1; i <= 4; i++ )
    {
        bp += t * 1.5;
        vec2 gr = vec2( grid_flow( p * 3.0 - t * 2.0 ),
                        grid_flow( p * 3.0 + 4.0 - t * 2.0 ) ) * 0.4;
        gr = normalize( gr + vec2( 0.0001 ) ) * 0.4;
        gr *= makem2_flow( ( p.x + p.y ) * 0.3 + t * 10.0 );
        p += gr * 0.5;
        rz += ( sin( vnoise_flow( p ) * 8.0 ) * 0.5 + 0.5 ) / z;
        p = mix( bp, p, 0.5 );
        z *= 1.7;
        p = m2 * ( p * 2.5 );
        bp = m2 * ( bp * 2.5 );
    }
    return rz;
}

float spiral_flow( vec2 p, float scl )
{
    float r = length( p ) + 0.001;
    r = log( r );
    float a = atan( p.y, p.x );
    return abs( mod( scl * ( r - 2.0 / scl * a ), TAU_FLOW ) - 1.0 ) * 2.0;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process = CoronaVertexUserData.x;
  float Speed = CoronaVertexUserData.y;
  float Scale = CoronaVertexUserData.z;
  int   Style = int( CoronaVertexUserData.w + 0.5 );

  float t = CoronaTotalTime * 0.35 * Speed;

  float aspect = CoronaTexelSize.w / max( CoronaTexelSize.z, 0.00001 );
  vec2 p = texCoord - vec2( 0.5 );
  p.x *= aspect;
  p *= Scale;

  float rz = flow_main( p, t );
  vec2 sp = p / exp( mod( t * 3.0, 2.1 ) );
  rz *= ( 6.0 - spiral_flow( sp, 3.0 ) ) * 0.9;

  vec3 base = vec3( 0.16, 0.05, 0.38 );
  if ( Style == 1 )      base = vec3( 0.32, 0.10, 0.02 );
  else if ( Style == 2 ) base = vec3( 0.03, 0.20, 0.38 );
  else if ( Style == 3 ) base = vec3( 0.45, 0.30, 0.05 );

  vec3 col = base / max( rz, 0.12 );
  col = pow( clamp( abs( col ), 0.0, 4.0 ), vec3( 1.01 ) );

  vec4 orig = texture2D( CoronaSampler0, texCoord );
  vec3 outc = mix( orig.rgb, col, clamp( Process, 0.0, 1.0 ) );
  float outa = mix( orig.a, 1.0, clamp( Process, 0.0, 1.0 ) );

  P_COLOR vec4 COLOR = vec4( outc, outa );
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
