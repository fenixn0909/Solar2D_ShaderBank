--[[
  Origin Author: orbbloff
  https://godotshaders.com/author/orbbloff/
  Magnifier lens with circular crop and outline.
  Fixed: vertexData intensity/size/tilt/speed never read; fragment used
  hardcoded magnification=1.2, circle_radius=0.3 etc. Now:
  X= Magnification (1..3), Y= Radius (0.05..0.71), Z= Outline (0..0.1),
  W= Roundness. Also fixed u_TexelSize typo and removed dead code.
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "scale"
kernel.name = "magnifier"
kernel.isTimeDependent = false

kernel.vertexData   = {
  { name = "Magnification", default = 1.5, min = 1, max = 4, index = 0, },
  { name = "Radius",        default = 0.3, min = 0.05, max = 0.71, index = 1, },
  { name = "Outline",       default = 0.02, min = 0, max = 0.1, index = 2, },
  { name = "Roundness",     default = 1,   min = 0, max = 2, index = 3, },
}

kernel.vertex =
[[
varying P_UV vec2 center_pos;
varying P_UV vec2 frag_pos;
P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{
  center_pos = vec2(0.0, 0.0);
  frag_pos = position;
  return position;
}
]]

kernel.fragment =
[[

varying P_UV vec2 center_pos;
varying P_UV vec2 frag_pos;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    float Magnification = CoronaVertexUserData.x;
    float Radius        = CoronaVertexUserData.y;
    float Outline       = CoronaVertexUserData.z;
    float Roundness     = CoronaVertexUserData.w;

    float magnification = max(1.0, Magnification);
    float circle_radius = clamp(Radius, 0.05, 0.71);
    float outline_thickness = clamp(Outline, 0.0, 0.1);
    float roundness = Roundness;
    vec4 outline_color = vec4(0.4, 0.0, 0.0, 1.0);
    bool is_round = true;
    bool filtering = true;

    vec2 SCREEN_PIXEL_SIZE = CoronaTexelSize.zw;
    vec2 SCREEN_UV = texCoord;
    vec2 UV = texCoord;

    P_UV vec2 texelOffset = ( CoronaTexelSize.zw * 0.5 );
    P_UV vec2 FRAGCOORD = ( texelOffset + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw ) );

    vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv_distance = vec2(0.5) - UV;
    vec2 pixel_distance;
    pixel_distance.x = center_pos.x - FRAGCOORD.x;
    pixel_distance.y = center_pos.y - (screen_resolution.y - FRAGCOORD.y);
    vec2 obj_size = pixel_distance / max(uv_distance, vec2(0.001));
    vec2 ratio = obj_size / screen_resolution;
    float magnify_value = (magnification - 1.0) / magnification;
    if(is_round){
      magnify_value /= smoothstep(0.0, 1.0, length(UV - vec2(0.5))) * roundness + 1.0;
    }
    vec2 local_mapped_uv = mix(UV, vec2(0.5), magnify_value);
    vec2 difference = local_mapped_uv - UV;
    vec2 global_mapped_uv;
    global_mapped_uv.x = SCREEN_UV.x + difference.x * ratio.x;
    global_mapped_uv.y = SCREEN_UV.y - difference.y * ratio.y;

    P_COLOR vec4 COLOR;
    if(filtering){
      COLOR = texture2D(CoronaSampler0, global_mapped_uv);
    } else {
      COLOR = texture2D(CoronaSampler0, texCoord);
    }
    if(length(UV - vec2(0.5)) > circle_radius - outline_thickness){
        COLOR = vec4(0.0);
        if(length(UV - vec2(0.5)) < circle_radius){
            COLOR = outline_color;
        }
    }
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
