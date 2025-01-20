 
--[[
    https://www.shadertoy.com/view/M33BD7
    Created by FabriceNeyret2 in 2025-01-19
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "geometricArt"


kernel.isTimeDependent = true


kernel.vertexData =
{
  { name = "Speed",     default = 15, min = 0, max = 100, index = 0, },
  { name = "Step",      default = 289, min = 150, max = 300, index = 1, },
  { name = "Const",     default = 17, min = 9, max = 34, index = 2, },
} 
kernel.fragment =
[[


float Speed = CoronaVertexUserData.x;
int Step = int(CoronaVertexUserData.y);
int Const = int(CoronaVertexUserData.z);



//-----------------------------------------------
int modi( int a, int b ){ return (a)-((a)/(b))*(b); }
//-----------------------------------------------

P_COLOR vec4 COLOR = vec4(1);
P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;
P_DEFAULT float TIME = CoronaTotalTime; // * speed


P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_UV vec2 U = UV * iResolution;

    float alpha = texture2D(CoronaSampler0, UV ).a;
    //----------------------------------------------
    for (int k=0; k<Step; k++) {                                                 // check 17x17 neighborhood
        vec2 P = ceil( U/4. + vec2( modi(k,Const) ,k/ float(Const)) - 9. );                   // cell Id
        
        P += fract( 1e4* sin( P * mat2(12.1,-37.4,-17.3,31.7) )) -.5 * sin(TIME*Speed*0.00001) ;           // random point in cell
        P *= 4.;
        
        float v = texture2D(CoronaSampler0, P/iResolution.xy ).r ,              // check texture there
              r = 2.+30.*v;                                                     // circle radius
        fract( 1e4* sin( dot(P,vec2(12.1,31.7))  )) * r/8. < 1.-v               // drawing proba ~ darkness/circumference
          ?  COLOR -= .2 * smoothstep(1.5,0.,abs( length(P-U) - r )) :COLOR;    // draw antialiased circle
    }

    //----------------------------------------------
    COLOR.a = alpha;
    COLOR.rgb *= COLOR.a;


    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


