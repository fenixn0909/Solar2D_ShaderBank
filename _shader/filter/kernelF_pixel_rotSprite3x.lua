--[[
  Origin Author: lucrecious
  https://godotshaders.com/author/lucrecious/
  This shader upscales the sprite using the Scale2x algorithm in GPU.
  Fixed: vertexData intensity/size/tilt/speed were defined but fragment
  used hardcoded uniform float pixel_scale=1.0 and vertex used
  u_TexelSize typo. Now intensity blends original vs scaled, size drives
  pixel_scale, tilt adds subtle uv rotation, speed drives time wobble,
  all real-time. Also fixed u_TexelSize -> CoronaTexelSize.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "pixel"
kernel.name = "rotSprite3x"
kernel.isTimeDependent = true

kernel.vertexData   = {
  { name = "Blend", default = 1,   min = 0, max = 1,   index = 0, },
  { name = "Scale", default = 1,   min = 0.5, max = 3, index = 1, },
  { name = "Tilt",  default = 0,   min = -1, max = 1,  index = 2, },
  { name = "Speed", default = 0,   min = 0, max = 10,  index = 3, },
}

kernel.vertex =
[[
varying P_UV vec2 slot_size;
varying P_UV vec2 sample_uv_offset;
P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{
  P_UV float numPixels = 1.0;
  slot_size = ( CoronaTexelSize.zw * numPixels );
  sample_uv_offset = ( slot_size * 0.5 );
  return position;
}
]]

kernel.fragment =
[[

varying P_UV vec2 slot_size;
varying P_UV vec2 sample_uv_offset;

const vec4 background = vec4(1., 1., 1., 0.);

float dist(vec4 c1, vec4 c2) {
  return (c1 == c2) ? 0.0 : abs(c1.r - c2.r) + abs(c1.g - c2.g) + abs(c1.b - c2.b);
}

bool similar(vec4 c1, vec4 c2, vec4 cIpt) {
  return (c1 == c2 || (dist(c1, c2) <= dist(cIpt, c2) && dist(c1, c2) <= dist(cIpt, c1)));
}

bool different(vec4 c1, vec4 c2, vec4 cIpt) {
  return !similar(c1, c2, cIpt);
}

vec4 scale3x(sampler2D tex, vec2 uv, vec2 pixel_size) {
  vec4 cE = texture2D(tex, uv);
  cE = cE.a == 0.0 ? background : cE;
  vec4 cD = texture2D(tex, uv + pixel_size * vec2(-1., .0));
  cD = cD.a == 0.0 ? background : cD;
  vec4 cF = texture2D(tex, uv + pixel_size * vec2(1., .0));
  cF = cF.a == 0.0 ? background : cF;
  vec4 cH = texture2D(tex, uv + pixel_size * vec2(.0, 1.));
  cH = cH.a == 0.0 ? background : cH;
  vec4 cB = texture2D(tex, uv + pixel_size * vec2(.0, -1.));
  cB = cB.a == 0.0 ? background : cB;
  vec4 cA = texture2D(tex, uv + pixel_size * vec2(-1., -1.));
  cA = cA.a == 0.0 ? background : cA;
  vec4 cI = texture2D(tex, uv + pixel_size * vec2(1., 1.));
  cI = cI.a == 0.0 ? background : cI;
  vec4 cG = texture2D(tex, uv + pixel_size * vec2(-1., 1.));
  cG = cG.a == 0.0 ? background : cG;
  vec4 cC = texture2D(tex, uv + pixel_size * vec2(1., -1.));
  cC = cC.a == 0.0 ? background : cC;

  if (different(cD,cF, cE)
     && different(cH,cB, cE)
     && ((similar(cE, cD, cE) || similar(cE, cH, cE) || similar(cE, cF, cE) || similar(cE, cB, cE) ||
         ((different(cA, cI, cE) || similar(cE, cG, cE) || similar(cE, cC, cE)) &&
          (different(cG, cC, cE) || similar(cE, cA, cE) || similar(cE, cI, cE))))))
    {
    vec2 unit = uv - (floor(uv / pixel_size) * pixel_size);
    vec2 pixel_3_size = pixel_size / 3.0;
    if (unit.x < pixel_3_size.x && unit.y < pixel_3_size.y) {
      return similar(cB, cD, cE) ? cB : cE;
    }
    if (unit.x < pixel_3_size.x * 2.0 && unit.y < pixel_3_size.y) {
      return (similar(cB, cD, cE) && different(cE, cC, cE))
        || (similar(cB, cF, cE) && different(cE, cA, cE)) ? cB : cE;
    }
    if (unit.y < pixel_3_size.y) {
      return similar(cB, cF, cE) ? cB : cE;
    }
    if (unit.x < pixel_3_size.x && unit.y < pixel_3_size.y * 2.0) {
      return (similar(cB, cD, cE) && different(cE, cG, cE)
        || (similar(cH, cD, cE) && different(cE, cA, cE))) ? cD : cE;
    }
    if (unit.x >= pixel_3_size.x * 2.0 && unit.x < pixel_3_size.x * 3.0 && unit.y < pixel_3_size.y * 2.0) {
      return (similar(cB, cF, cE) && different(cE, cI, cE))
        || (similar(cH, cF, cE) && different(cE, cC, cE)) ? cF : cE;
    }
    if (unit.x < pixel_3_size.x && unit.y >= pixel_3_size.y * 2.0) {
      return similar(cH, cD, cE) ? cH : cE;
    }
    if (unit.x < pixel_3_size.x * 2.0 && unit.y >= pixel_3_size.y * 2.0) {
      return (similar(cH, cD, cE) && different(cE, cI, cE))
        || (similar(cH, cF, cE) && different(cE, cG, cE)) ? cH : cE;
    }
    if (unit.y >= pixel_3_size.y * 2.0) {
      return similar(cH, cF, cE) ? cH : cE;
    }
    }
  return cE;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Blend = CoronaVertexUserData.x;
    float Scale = CoronaVertexUserData.y;
    float Tilt  = CoronaVertexUserData.z;
    float Speed = CoronaVertexUserData.w;

    P_UV vec2 uv_pix = ( sample_uv_offset + ( floor( texCoord / slot_size ) * slot_size ) );
    // tilt as subtle rotation
    float ang = Tilt * 0.5;
    vec2 uv_rot = vec2( (uv_pix.x - 0.5)*cos(ang) - (uv_pix.y -0.5)*sin(ang) + 0.5,
                        (uv_pix.x - 0.5)*sin(ang) + (uv_pix.y -0.5)*cos(ang) + 0.5 );
    // speed adds tiny time wobble to demo real-time
    vec2 uv_final = mix(uv_pix, uv_rot, abs(Tilt));
    uv_final += sin(CoronaTotalTime * Speed) * 0.001 * Speed;

    vec2 pixel_sz = CoronaTexelSize.zw * max(0.5, Scale);
    P_COLOR vec4 scaled = scale3x(CoronaSampler0, uv_final, pixel_sz);
    P_COLOR vec4 orig   = texture2D(CoronaSampler0, texCoord);
    P_COLOR vec4 COLOR = mix(orig, scaled, clamp(Blend,0.0,1.0));
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale(COLOR);
}
]]

return kernel
