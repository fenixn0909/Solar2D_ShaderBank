-- 4 color pixel swapping

-- USAGE:
-- require ("multiswap')

--local object = display.newImage("image.png")

--object.fill.effect = "filter.custom.multiswap"
--object.fill.effect.keys = {
--  213/255,  95/255,  96/255, 1,
--  141/255,  76/255, 101/255, 1,
--  218/255, 177/255, 132/255, 1,
--  160/255, 125/255, 121/255, 1
--}
--object.fill.effect.colors = {
--  243/255, 133/255,  11/255, 1,
--  186/255, 102/255,  10/255, 1,
--  102/255,  63/255,  21/255, 1,
--   92/255,  50/255,   4/255, 1
--}

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "swapPxlt"
kernel.name = "multiColor"

-- Expose effect parameters using vertex data
kernel.uniformData = {
  {
    name = "matAimC",
    type="mat4",
    index = 0,
    paramName = {
      'Key1_R','Key1_G','Key1_B','Key1_A',
      'Key2_R','Key2_G','Key2_B','Key2_A',
      'Key3_R','Key3_G','Key3_B','Key3_A',
      'Key4_R','Key4_G','Key4_B','Key4_A',
    },
    default = {
      213/255,  95/255,  96/255, 1,
      141/255,  76/255, 101/255, 1,
      218/255, 177/255, 132/255, 1,
      160/255, 125/255, 121/255, 1
    },
    min = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    max = {
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
  },
  {
    name = "matToC",
    type="mat4",
    index = 1,
    paramName = {
      'To1_R','To1_G','To1_B','To1_A',
      'To2_R','To2_G','To2_B','To2_A',
      'To3_R','To3_G','To3_B','To3_A',
      'To4_R','To4_G','To4_B','To4_A',
    },
    default = {
      243/255, 133/255,  11/255, 1,
      186/255, 102/255,  10/255, 1,
      102/255,  63/255,  21/255, 1,
       92/255,  50/255,   4/255, 1
    },
    min = {
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 0.0
    },
    max = {
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0
    },
  },
}


kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0; // trgtC
uniform P_COLOR mat4 u_UserData1; // toC
P_NORMAL float deadZone = 0.01;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
  //FRAGCOORD Snippet
  P_UV vec2 sample_uv_offset = ( CoronaTexelSize.zw * 0.5 );
  P_UV vec2 uv = ( sample_uv_offset + ( floor( texCoord / CoronaTexelSize.zw ) * CoronaTexelSize.zw ) );

  P_COLOR vec4 texColor = texture2D( CoronaSampler0, uv );
  
  for(int i = 0; i < 4; i++){
      P_COLOR vec4 keys = u_UserData0[i];
      P_COLOR vec4 colors = u_UserData1[i];
      if ((abs(texColor[0] - keys[0]) < deadZone) && (abs(texColor[1] - keys[1]) < deadZone) && (abs(texColor[2] - keys[2]) < deadZone)){
          texColor = colors;
          break;
      }
  }

  return CoronaColorScale(texColor);
}
]]


return kernel
-- graphics.defineEffect( kernel )