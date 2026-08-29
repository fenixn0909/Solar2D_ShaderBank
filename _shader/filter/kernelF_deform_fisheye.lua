
--[[
  Origin Author: jamesfrize
  https://godotshaders.com/author/jamesfrize/

  Screen space shader based on: https://gist.github.com/aggregate1166877/a889083801d67917c26c12a98e7f57a7 
  Works great for creating fisheye distortion, barrel distortion or spherical mappings of the screen space. 
  To use this shader, it’s recommended that you add it to a ColorRect node or similar, this makes it easy to position or crop the effect.

--]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "deform"
kernel.name = "fisheye"
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

//----------------------------------------------
uniform vec2 v_aspect = vec2( 1 , 1  ); // default vec2(1.), less to zoomIn more to zoomOut
uniform vec2 v_offset = vec2( 0.00 , -0.1  ); 
float distortion = 30.0; // default: 0.5, more to bulge, less to contract. 100 -> ball
uniform float radius = 1; // hint:(1.0 : 0.0) less to show less
uniform float alpha = 1.0;
uniform float crop = 1.0;
uniform vec4 crop_color = vec4(0,0,0,0);//: hint_color = 

vec2 distort(vec2 p)
{
  float d = length(p);
  float z = sqrt(distortion + d * d * -distortion);
  float r = atan(d, z) / 3.1415926535;
  float phi = atan(p.y, p.x);
  return vec2(r * cos(phi) * (1.0 / v_aspect.x) + 0.5, r * sin(phi) * (1.0 / v_aspect.y) + 0.5);
}


//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    // Pixelization
    P_UV vec2 FRAGCOORD = ( CoronaTexelSize.zw * 0.5 + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw ) );
    //P_COLOR vec4 texColor = texture2D( CoronaSampler0, FRAGCOORD);

    P_UV vec2 SCREEN_UV = texCoord;
    P_COLOR vec4 COLOR;

    float Intensity = CoronaVertexUserData.x;
    float Size      = CoronaVertexUserData.y;
    // tilt/speed drive subtle animate: distortion = base + sin(TIME*speed)*tilt
    float Tilt      = CoronaVertexUserData.z;
    float Speed     = CoronaVertexUserData.w;
    distortion = (Intensity*30.0 + Size*10.0) + sin(CoronaTotalTime*Speed)*Tilt*5.0;
    distortion = clamp(distortion, 0.1, 40.0);
    //----------------------------------------------

      vec2 xy = (SCREEN_UV * 2.0 - 1.0); // move origin of UV coordinates to center of screen
      xy = vec2(xy.x * v_aspect.x, xy.y * v_aspect.y); // adjust aspectXY ratio

      float d = length(xy); // distance from center
      vec4 tex;

      if (d < radius)
      {
        xy = distort(xy);
        xy = (CoronaTexelSize.zw * 0.5) + ( floor( xy / CoronaTexelSize.zw ) * CoronaTexelSize.zw ); // Pixelization
        xy += v_offset;
        tex = texture2D(CoronaSampler0, xy);
        COLOR = tex;
        // Show Crop Color
        //COLOR.a = alpha;
      }

      // radial crop
      if (d > crop)
      {
        COLOR = crop_color;
      }

    //----------------------------------------------
    
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel


--[[

--]]





