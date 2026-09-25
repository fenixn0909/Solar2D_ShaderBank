
--[[
  Origin Author: hei
  https://godotshaders.com/author/hei/

  This shader “fakes” a 3D-camera perspective on CanvasItems.

  The shader works out-of-the-box with nodes Sprite and TextureRect, as long as the rect_size equals the size of the texture. If this isn’t the case, you can do the following change:

  //VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * tang * (1.0 - Inset);
  // to (rect_size is a uniform):
  VERTEX += (UV - 0.5) * rect_size * tang * (1.0 - Inset);
  
  Also, remember to enable mipmaps and anisotropic for the texture to retain quality with harsh angles.

  

--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "perspective2D"


kernel.vertexData =
{
  { name = "Process",  default = 1,  min = 0,   max = 1,   index = 0, },
  { name = "FOV",      default = 30, min = 1, max = 179, index = 1, },
  { name = "RotX",     default = 30, min = -180, max = 180, index = 2, },
  { name = "RotY",     default = 30, min = -180, max = 180, index = 3, },
} 

kernel.vertex =
[[


float FOV = CoronaVertexUserData.y;
float RotX = CoronaVertexUserData.z;
float RotY = CoronaVertexUserData.w;
// Process lives in UserData.x (fragment-only); Inset fixed at 0.5.
float Inset = 0.5;
//----------------------------------------------
// Camera FOV
//float FOV = 30; //: hint_range(1, 179) 

//float RotX = 30.0; //: hint_range(-180, 180) 
//float RotY = 30.0; //: hint_range(-180, 180) 

// At 0, the image retains its size when unrotated.
// At 1, the image is resized so that it can do a full
// rotation without clipping inside its rect.
//float Inset = 0.5; //: hint_range(0, 1) 

// Consider changing this to a uniform and changing it from code
//varying flat vec2 o;
varying vec2 o;
varying vec3 p;

const float PI = 3.14159;

// Creates rotation matrix
P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{
  P_UV vec2 TEXTURE_PIXEL_SIZE = CoronaTexelSize.zw;
  P_UV vec2 UV = CoronaTexCoord.xy;
  P_POSITION vec2 VERTEX = position;


  float sin_b = sin(RotY / 180.0 * PI);
  float cos_b = cos(RotY / 180.0 * PI);
  float sin_c = sin(RotX / 180.0 * PI);
  float cos_c = cos(RotX / 180.0 * PI);
  
  mat3 inv_rot_mat;
  inv_rot_mat[0][0] = cos_b;
  inv_rot_mat[0][1] = 0.0;
  inv_rot_mat[0][2] = -sin_b;
  
  inv_rot_mat[1][0] = sin_b * sin_c;
  inv_rot_mat[1][1] = cos_c;
  inv_rot_mat[1][2] = cos_b * sin_c;
  
  inv_rot_mat[2][0] = sin_b * cos_c;
  inv_rot_mat[2][1] = -sin_c;
  inv_rot_mat[2][2] = cos_b * cos_c;
  
  
  float t = tan(FOV / 360.0 * PI);
  p = inv_rot_mat * vec3((UV - 0.5), 0.5 / t);
  float v = (0.5 / t) + 0.5;
  p.xy *= v * inv_rot_mat[2].z;
  o = v * inv_rot_mat[2].xy;

  VERTEX += (UV - 0.5) / TEXTURE_PIXEL_SIZE * t * (1.0 - Inset);

  return VERTEX;
}
]]



kernel.fragment =
[[
//varying flat vec2 o;
varying vec2 o;
varying vec3 p;

bool cull_back = true;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  float Process = CoronaVertexUserData.x;

  vec4 orig = texture2D( CoronaSampler0, texCoord );
  // at Process 0 the sprite must stay fully visible: skip the discard
  if (cull_back && p.z <= 0.0 && Process > 0.001) { discard; }
  vec2 uv = (p.xy / p.z).xy - o;
  vec4 warped = texture2D( CoronaSampler0, uv + 0.5);
  warped.a *= step(max(abs(uv.x), abs(uv.y)), 0.5);

  vec4 outc = mix( orig, warped, clamp( Process, 0.0, 1.0 ) );
  P_COLOR vec4 COLOR = outc;

  return CoronaColorScale( COLOR );
}
]]


return kernel




--[[



--]]





