
--[[
  Origin Author: orbbloff
  https://godotshaders.com/author/orbbloff/
  

  A Godot shader that magnifies what’s behind it. Written in Godot Engine v3.4.4.

  This shader reads from screen texture. So if the image you want to zoom in isn’t rendered properly, you may end up with an unwanted result.

  In order to get this shader working in Godot, you must attach this to a node with a texture. It might work with nodes without textures too, but it’s not tested yet.

  For more information or to contribute: https://github.com/Orbbloff/Godot-Magnifier-Shader

  https://orbbloff.itch.io/godot-magnifier-shader


  This is a magnifier shader written in Godot Shading Language which is similar to GLSL ES 3.0. 
  
  In order to get this shader working, you must attach this to a node with a texture.
  It might work with nodes without textures too, but isn't tested yet.
  
  Author is Yavuz Burak Yalçın @orbbloff
  
  MIT License

--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
-- By default, the group is "custom"
kernel.group = "scale"
kernel.name = "magnifier"
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




kernel.vertex =
[[

bool is_object_centered; // Note that this needs to match with the sprite's centered property

varying P_UV vec2 center_pos; //flat vec2
varying P_UV vec2 frag_pos;

//uniform gl_ModelViewMatrix;

P_POSITION vec2 VertexKernel( P_POSITION vec2 position )
{

  if(is_object_centered){
      center_pos = vec2(0.0, 0.0); 
     }
  else{
      //center_pos = (1.0 / TEXTURE_PIXEL_SIZE) / 2.0; 
      center_pos = (1.0 / CoronaTexelSize.zw) / 2.0; 
     }

  /*
  mat4 WORLD_MATRIX = mat4[
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0
  ];
  */
  //center_pos = (gl_ModelViewMatrix * vec4(center_pos, 0.0, 1.0)).xy; // From local space texel coordinates 
  //center_pos = (gl_ModelViewMatrix * vec4(center_pos, 0.0, 1.0)).xy; // From local space texel coordinates 
  center_pos = vec2(0,0);

  //center_pos = (WORLD_MATRIX * vec4(center_pos, 0.0, 1.0)).xy; // From local space texel coordinates 
                                                               // to screen space pixel coordinates
  
  frag_pos = position;

  return position;
}
]]






kernel.fragment =
[[

float magnification = 1.2; // :hint_range(0.0, 400.0)
bool filtering = true;
bool is_round = true;
float roundness = 100.0; //:hint_range(0.0, 2.0)
float circle_radius = 0.3; //:hint_range(0.0, 0.71) 
float outline_thickness = 0.00; //:hint_range(0.0, 0.1)
vec4 outline_color = vec4(0.4, 0.0, 0.0, 1.0); //:hint_color

varying P_UV vec2 center_pos;
varying P_UV vec2 frag_pos;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    vec2 SCREEN_PIXEL_SIZE = vec2(1.0,1.0);
    //vec4 SCREEN_TEXTURE = CoronaSampler0;
    //vec2 SCREEN_UV = vec2(1.0 ,1.0);
    //vec2 SCREEN_UV = gl_FragCoord.xy / frag_pos;
    //vec2 SCREEN_UV = frag_pos;
    //vec2 SCREEN_UV = gl_FragCoord;
    vec2 SCREEN_UV = texCoord;
    vec2 UV = texCoord;

    P_UV vec2 texelOffset = ( u_TexelSize.zw * 0.5 );
    P_UV vec2 FRAGCOORD = ( texelOffset + ( floor( texCoord / u_TexelSize.zw ) * u_TexelSize.zw ) );
    //P_COLOR vec4 texColor = texture2D( CoronaSampler0, FRAGCOORD);
    P_COLOR vec4 COLOR;


    vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv_distance = vec2(0.5) - UV; // UV distance between fragment and object center in local space
    vec2 pixel_distance;               // Pixel distance between fragment and object center
    pixel_distance.x = center_pos.x - FRAGCOORD.x;
    pixel_distance.y = center_pos.y - (screen_resolution.y - FRAGCOORD.y); // Since y component of FRAGCOORD built-in is
                                                                           // inverted it is extracted from screen resolution
    vec2 obj_size = pixel_distance / uv_distance; // Ratio of pixel distance to uv distance gives the objects dimensions
    vec2 ratio = obj_size / screen_resolution;    // This gives the ratio of object to screen
    float magnify_value = (magnification - 1.0) / magnification; // Maps the magnification value to range[0.0, 1.0)
                                                                 // while magnification is higher than 1.0
    if(is_round){
      magnify_value /= smoothstep(0.0, 1.0, length(UV - vec2(0.5))) * roundness + 1.0; // It slightly reduces the magnification 
                                                                                     // of points that are far to the center 
    }
    
    vec2 local_mapped_uv = mix(UV, vec2(0.5 /*center*/), magnify_value); // Calculates a local UV position towards
                                                                         // the center, proportional to magnification
    vec2 difference = local_mapped_uv - UV; 
    vec2 global_mapped_uv; // Calculates a global UV position to from screen texture
    global_mapped_uv.x = SCREEN_UV.x + difference.x * ratio.x;
    global_mapped_uv.y = SCREEN_UV.y - difference.y * ratio.y;
    


    if(filtering){
    // Applies filter while reading from screen texture
    COLOR = texture2D(CoronaSampler0, global_mapped_uv);
    //COLOR = texture2D(CoronaSampler0, texCoord);
    
    }
    else{
    // Doesn't apply filter.
    // Since texelFetch function uses screen space pixel coordinates, global_mapped_uv is transformed to pixel coordinates.
    //COLOR = texelFetch(CoronaSampler0, ivec2(int(global_mapped_uv.x * screen_resolution.x), int((global_mapped_uv.y) * screen_resolution.y)), 0); 
    //COLOR = texture2D(CoronaSampler0, vec2(( 2 * int(global_mapped_uv.x * screen_resolution.x), int(global_mapped_uv.y * screen_resolution.y) ) /2)  );
    COLOR = texture2D( CoronaSampler0, texCoord  );

    }
    // Creates outline
    if(length(UV - vec2(0.5)) > circle_radius - outline_thickness){
        COLOR = vec4(0.0); // Makes fragments transparent 
        if(length(UV - vec2(0.5)) < circle_radius){
            COLOR = outline_color;
        }
    }
    
    return CoronaColorScale( COLOR );
}
]]

return kernel


--[[
/*
    
*/

--]]





