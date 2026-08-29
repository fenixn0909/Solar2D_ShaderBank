
--[[
  Origin Author: mrsir8433
  https://godotshaders.com/author/mrsir8433/
  
  A basic distortion shader with chromatic abberation, with modular parameters.

  [EDIT]

  1. Ok. First of all, it is a screen-space shader. If one wants to add this to specific node with texture, it has to be modified a bit. Like the screen-texture has to be changed to node-specific texture with sampler2d.

  2. I created it in Godot 4 {alpha10}. You can download the demo-project here. godot_shaders_distortion

  3. You have to animate the radius and center parameters from outside. Add this shader to a color-rect above all nodes as a canvas layer. The center property is in range 0 to 1. So you have to normalise the position u want the distortion to originate from.

  4. If any problem happens, comment here; I will try to response accordingly.

  Peace!!!

--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "shockWave"
kernel.isTimeDependent = true

-- Expose effect parameters using vertex data
kernel.vertexData   = {
  {
    name = "intensity",
    default = 0.65, 
    min = 0,
    max = 1,
    index = 0,  -- This corresponds to "CoronaVertexUserData.x"
  },
  {
    name = "size",
    default = 0.1, 
    min = 0,
    max = 1,
    index = 1,  -- This corresponds to "CoronaVertexUserData.y"
  },
  {
    name = "tilt",
    default = 0.2, 
    min = 0.0,
    max = 2.0,
    index = 2,  -- This corresponds to "CoronaVertexUserData.z"
  },
  {
    name = "speed",
    default = 1.0, 
    min = 0.1,
    max = 10.0,
    index = 3,  -- This corresponds to "CoronaVertexUserData.w"
  },
}


kernel.fragment =
[[
float strength = 0.1; //: hint_range(0.0, 0.1, 0.001) 
uniform vec2 center = vec2(0.5, 0.5);
float radius = 0.25; //: hint_range(0.0, 1.0, 0.001) 


uniform float aberration = 0.425; //: hint_range(0.0, 1.0, 0.001) 
uniform float width = 0.04; //: hint_range(0.0, 0.1, 0.0001) 
uniform float feather = 0.135; //: hint_range(0.0, 1.0, 0.001)


P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{

  // Pixelate
  P_UV vec2 UV_Pix = (CoronaTexelSize.zw * 0.5) + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw );
  P_UV vec2 SCREEN_UV = UV_Pix;
  // Smooth
  //P_UV vec2 SCREEN_UV = texCoord;

  P_UV vec2 SCREEN_PIXEL_SIZE = CoronaTexelSize.zw;

  //Test
  strength = sin(CoronaTotalTime*2)*1;
  radius = abs(sin(CoronaTotalTime*2))*1;


  vec2 st = SCREEN_UV;
  float aspect_ratio = SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
  vec2 scaled_st = (st -vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0,0.5); 
  vec2 dist_center = scaled_st - center;
  float mask =  (1.0 - smoothstep(radius-feather, radius, length(dist_center))) * smoothstep(radius - width - feather, radius-width , length(dist_center));
  vec2 offset = normalize(dist_center)*strength*mask;
  vec2 biased_st = scaled_st - offset;
  
  vec2 abber_vec = offset*aberration*mask;
  
  vec2 final_st = st*(1.0-mask) + biased_st*mask;

  vec4 red = texture2D(CoronaSampler0, final_st + abber_vec);
  vec4 blue = texture2D(CoronaSampler0, final_st - abber_vec);
  vec4 ori = texture2D(CoronaSampler0, final_st);
  vec4 origTex = texture2D(CoronaSampler0, texCoord);
  // preserve original alpha outside mask; transparent where mask=0 (origTex.a)
  P_COLOR vec4 COLOR = vec4(red.r, ori.g, blue.b, mix(origTex.a, ori.a, mask));
  COLOR.rgb *= COLOR.a;


  return CoronaColorScale( COLOR );
}
]]

return kernel


--[[



--]]





