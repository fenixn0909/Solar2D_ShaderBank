
--[[
    https://godotshaders.com/shader/stepped-gradient/
    imakeshaders
    September 28, 2024


--]]


local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "trans"
kernel.name = "steppedGradient"

kernel.isTimeDependent = true

kernel.vertexData = nil

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Progress','Steps','Angle','Smoothness',
            'Col1_R','Col1_G','Col1_B','Col1_A',
            'Col2_R','Col2_G','Col2_B','Col2_A',
            'Glow','','','',
        },
        default = {
            .5,6,0,.08,
            1,1,1,1,
            0,0,0,1,
            .5,0,0,0,
        },
        min = {
            0,2,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,24,6.28318,.5,
            1,1,1,1,
            1,1,1,1,
            2,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
float Progress = u_UserData0[0][0];
float Steps = u_UserData0[0][1];
float Grad_Angle = u_UserData0[0][2];
float Smoothness = u_UserData0[0][3];
vec4 Col_1 = vec4(u_UserData0[1][0],u_UserData0[1][1],u_UserData0[1][2],u_UserData0[1][3]);
vec4 Col_2 = vec4(u_UserData0[2][0],u_UserData0[2][1],u_UserData0[2][2],u_UserData0[2][3]);
float Glow = u_UserData0[3][0];

//----------------------------------------------

float round( float value){
    return floor( value + float(0.5) );
}
//-----------------------------------------------
P_COLOR vec4 COLOR;

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float progress = Progress;
    //----------------------------------------------
    // Rotated stepped gradient: Angle spins the wipe direction,
    // Steps quantizes it into bands, Smoothness softens band edges.
    vec2 cuv = UV - vec2( 0.5 );
    float ca = cos( Grad_Angle );
    float sa = sin( Grad_Angle );
    vec2 ruv = vec2( cuv.x * ca - cuv.y * sa, cuv.x * sa + cuv.y * ca ) + vec2( 0.5 );
    Col_1.a = 1.0 - progress - 0.15;
    float pos = smoothstep(0.0,1.0,ruv.x);
    float stepped = floor( pos * Steps ) / max( Steps - 1.0, 1.0 );
    float bandMix = mix( stepped, pos, clamp( Smoothness * 4.0, 0.0, 1.0 ) );
    COLOR = mix(Col_1,Col_2, bandMix * .25 / (progress+0.00001) );
    // Glow lift near the leading band for extra interest.
    float frontier = abs( bandMix * 0.25 - ( progress * 0.25 ) );
    COLOR.rgb += vec3( 1.0 ) * exp( -frontier * frontier * 180.0 ) * Glow * 0.25;

    //----------------------------------------------
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


