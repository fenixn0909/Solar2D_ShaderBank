--[[
  Origin Author: nimitz (Shadertoy lslXRS, flow-noise lava)
  https://www.shadertoy.com/view/lslXRS

  Fixed: it never rendered - `gl_FragCoord` is screen-space (wrong for
  a sprite filter) and `p *= mat2` is illegal GLSL. The flow field is
  UV-based and the sprite image itself is the noise source (like the
  original) - try different sprites for different lava.
  Fun tweakings: Process (1st, sprite -> lava), Speed (flow rate,
  0 = frozen), Scale (zoom), Style (0 lava / 1 ocean / 2 gold / 3 poison).
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "BG"
kernel.name = "noiseAnimLava"

kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Process", default = 1,   min = 0, max = 1,  index = 0, },
  { name = "Speed", default = 0.6, min = 0, max = 2,  index = 1, },
  { name = "Scale", default = 8,   min = 2, max = 16, index = 2, },
  { name = "Style", default = 0,   min = 0, max = 3,  index = 3, },
}

kernel.fragment =
[[
mat2 makem2_lava( float theta )
{
    float c = cos( theta );
    float s = sin( theta );
    return mat2( c, -s, s, c );
}

// the sprite image itself is the noise source (tiled)
float vnoise_lava( vec2 x )
{
    return texture2D( CoronaSampler0, fract( x * 0.08 ) ).x;
}

vec2 gradn_lava( vec2 p )
{
    float ep = 0.25;
    float gx = vnoise_lava( vec2( p.x + ep, p.y ) ) - vnoise_lava( vec2( p.x - ep, p.y ) );
    float gy = vnoise_lava( vec2( p.x, p.y + ep ) ) - vnoise_lava( vec2( p.x, p.y - ep ) );
    return vec2( gx, gy );
}

float flow_lava( vec2 p, float t )
{
    float z = 2.0;
    float rz = 0.0;
    vec2 bp = p;
    for ( int i = 1; i <= 6; i++ )
    {
        float fi = float( i );
        p += t * 0.6;
        bp += t * 1.9;
        vec2 gr = gradn_lava( fi * p * 0.34 + t );
        gr *= makem2_lava( t * 6.0 - ( 0.05 * p.x + 0.03 * p.y ) * 40.0 );
        p += gr * 0.5;
        rz += ( sin( vnoise_lava( p ) * 7.0 ) * 0.5 + 0.5 ) / z;
        p = mix( bp, p, 0.77 );
        z *= 1.4;
        p *= 2.0;
        bp *= 1.9;
    }
    return rz;
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

  float rz = flow_lava( p, t );

  vec3 base = vec3( 0.30, 0.10, 0.02 );
  if ( Style == 1 )      base = vec3( 0.03, 0.20, 0.38 );
  else if ( Style == 2 ) base = vec3( 0.45, 0.30, 0.05 );
  else if ( Style == 3 ) base = vec3( 0.16, 0.05, 0.35 );

  vec3 col = base / max( rz, 0.15 );
  col = pow( clamp( col, 0.0, 4.0 ), vec3( 1.2 ) );

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
