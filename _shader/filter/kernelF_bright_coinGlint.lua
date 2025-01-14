-- pixel-like coin glint

-- USAGE:
-- require ("glint')

--local object = display.newImage("image.png")

--object.fill.effect = "filter.custom.glint"
--object.fill.effect.intensity = 1.0 -- how bright the glint is
--object.fill.effect.size = 0.1 -- how wide the glint is as a percent of the object
--object.fill.effect.tilt = 0.2 -- tilt the direction of the glint
--object.fill.effect.speed = 1.0 -- how fast the glint moves across the object

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
-- By default, the group is "custom"
kernel.group = "bright"
kernel.name = "coinGlint"
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
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR float intensity = CoronaVertexUserData.x;
    P_COLOR vec4 texColor = texture2D( CoronaSampler0, UV );
 
    // Grab a float from the total time * speed
    P_COLOR float glint = floor(20.0 * mod(CoronaVertexUserData.w * CoronaTotalTime, 2.0)) * 0.05;
    glint = glint + (CoronaVertexUserData.z * sin(UV.y - 0.5));
    
    // Calculate where the glint is at
    {
      P_COLOR float size = CoronaVertexUserData.y * 0.5;
      intensity = (step(UV.x, glint + size) - step(UV.x, glint - size)) * intensity * texColor.a;
    }
    // Add the intensity
    texColor.rgb += intensity;
 
    // Modulate by the display object's combined alpha/tint.
    return CoronaColorScale( texColor );
}
]]

return kernel