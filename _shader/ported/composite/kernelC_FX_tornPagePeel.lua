
--[[
    Original implementation for this bank. Peels a corner of the base
    image back like a torn page: CoronaSampler1 is a grayscale tear
    map (white = torn away, black = intact); wherever that map exceeds
    Peel_Amount, the base image is replaced by a paper-back color with
    a shading gradient that darkens near the peel edge (faking the
    curl catching shadow) plus a soft drop shadow cast just past the
    edge onto the still-intact page.

    Checked against all existing kernels first: kernelF_FX_
    paperCutoutShadow only adds a static offset drop shadow beneath an
    already-cutout sprite - no tear map, no peel/curl shading, no
    reveal of a paper-back color; kernelF_trans_pageScroll (this
    bank's transition catalog) scrolls a *whole page* off during a
    scene change, not a static partial-corner peel driven by an
    authored mask. Different mechanic and purpose from both.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "tornPagePeel"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Peel_Amount','Curl_Shade','Back_R','Back_G',
            'Back_B','Shadow_Amount','Edge_Width','',
            '','','','',
            '','','','',
        },
        default = {
            .3,.6,.9,.86,
            .74,.5,.05,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,.01,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            1,1,.15,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Peel_Amount   = u_UserData0[0][0];
float Curl_Shade    = u_UserData0[0][1];
vec3  Back_Color    = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Shadow_Amount = u_UserData0[1][1];
float Edge_Width    = u_UserData0[1][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 base = texture2D( CoronaSampler0, UV );
    float tear = texture2D( CoronaSampler1, UV ).r;

    float peeled = step( Peel_Amount, tear );
    float edgeDist = tear - Peel_Amount;

    float curlShading = 1.0 - Curl_Shade * smoothstep( Edge_Width, 0.0, abs( edgeDist ) );
    vec3 backSide = Back_Color * curlShading;

    float shadow = smoothstep( 0.0, Edge_Width * 2.0, -edgeDist ) * smoothstep( Edge_Width * 2.0, 0.0, -edgeDist ) * Shadow_Amount;
    vec3 shadowedBase = base.rgb * ( 1.0 - shadow );

    vec3 finalRGB = mix( shadowedBase, backSide, peeled );

    P_COLOR vec4 COLOR = vec4( finalRGB, base.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
