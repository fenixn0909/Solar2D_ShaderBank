--[[
  Origin Author: Nevoski
  https://godotshaders.com/author/Nevoski/
  Converted from ShaderToy https://www.shadertoy.com/view/ldBXDD ripple.
  Fixed: hardcoded wave_count=2000, speed=3, height=0.003 and
  height = sin(TIME)*0.1 override ignored vertexData screenPxX/Y/tilt/speed.
  Round 3: added Center_Y (center is now freely placeable). All 5 params
  live in one uniform block (vertexData only holds 4 floats).
  Also removed erroneous u_resolution/gl_FragCoord uniforms; use
  CoronaTexelSize + CoronaTotalTime like other time-dependent filters.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "ripple"
kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','Wave_Count','Speed','Height',
            'Center_X','Center_Y','','',
            '','','','',
            '','','','',
        },
        default = {
            1,12,3,0.03,
            0.5,0.5,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,1,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,40,10,0.15,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Process    = u_UserData0[0][0];
float Wave_Count = u_UserData0[0][1];
float Speed      = u_UserData0[0][2];
float Height     = u_UserData0[0][3];
float Center_X   = u_UserData0[1][0];
float Center_Y   = u_UserData0[1][1];

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  P_DEFAULT float TIME = CoronaTotalTime;
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;

  P_UV vec2 UV = texCoord;
  // ripple center in UV space, freely placeable via Center_X / Center_Y
  vec2 center = vec2( Center_X, Center_Y );
  // simpler: use UV distance from center
  vec2 dUV = UV - center;
  float cLength = length(dUV * vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y) * 0.002);
  // use wave_count directly
  vec2 uv = UV + normalize(dUV + vec2(0.0001)) * cos(cLength * Wave_Count - TIME * Speed) * Height * 0.5;
  uv = clamp(uv, vec2(0.0), vec2(1.0));
  vec4 warped = texture2D(CoronaSampler0, uv);
  vec4 orig = texture2D(CoronaSampler0, UV);
  vec4 tex = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );
  // preserve original texture alpha; no black opaque where no ripple
  P_COLOR vec4 COLOR = tex;
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale( COLOR );
}
]]

return kernel
