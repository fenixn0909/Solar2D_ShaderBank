
--[[
    https://godotshaders.com/shader/2d-black-hole/
    Dan
    February 21, 2026

    CoronaSampler0 stands in for the original's screen capture - feed
    it a snapshot/render-to-texture. Direct port, nothing dropped
    (debug-color toggle kept as a param, matching the original).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "blackHole"

kernel.vertexData =
{
  { name = "Distortion_Strength", default = .9,  min = 0, max = 3, index = 0, },
  { name = "Attenuation",         default = 10,  min = 1, max = 30, index = 1, },
  { name = "Show_Debug_Colors",   default = 0,   min = 0, max = 1,  index = 2, },
}


kernel.fragment =
[[

float Distortion_Strength = CoronaVertexUserData.x;
float Attenuation         = CoronaVertexUserData.y;
float Show_Debug_Colors   = CoronaVertexUserData.z;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 dir = ( UV - vec2( 0.5 ) );
    float dist = length( dir );
    dir *= pow( dist, -Distortion_Strength );
    dir *= pow( ( 1.0 - dist ), Attenuation );

    P_COLOR vec4 COLOR = vec4( texture2D( CoronaSampler0, UV - dir ).rgb, 1.0 );

    if ( Show_Debug_Colors > 0.5 ) {
        COLOR = vec4( UV - vec2( 0.5 ), 0.0, 1.0 );
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

