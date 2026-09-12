
--[[
    Original implementation for this bank. A real point-focus depth-
    of-field approximation: a sharp circle at Focus_Point stays crisp,
    and a stationary 8-tap ring blur (each pixel blurs with its own
    neighborhood, no directional streaking) grows with distance past
    Focus_Radius up to Max_Blur - the "spotlight the important thing,
    soften the rest" read used for hero-item close-ups and dialogue
    portraits, not a motion effect.

    Checked against all existing kernels first: kernelF_blur_tiltShift
    blurs by *vertical band* (a horizontal in-focus strip, blur above
    and below it) - a linear axis, not a point/radius; kernelF_blur_
    radial is a Yui Kinomoto port that blurs via a directional zoom-
    streak driven by Progress (motion-blur read, no fixed focus point
    that stays crisp) - see its own header for the distinction from
    this bank's other radial-sounding kernels. Neither keeps a
    stationary point in focus while blurring outward from it.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "blur"
kernel.name = "pointFocusDOF"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Focus_X','Focus_Y','Focus_Radius','Falloff',
            'Max_Blur','Focus_Boost','Aspect_Ratio','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            .5,.5,.18,.35,
            .018,.15,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.02,.05,
            .002,0,.2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,.5,.8,
            .05,.5,5,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Focus_Point   = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Focus_Radius  = u_UserData0[0][2];
float Falloff       = u_UserData0[0][3];
float Max_Blur      = u_UserData0[1][0];
float Focus_Boost   = u_UserData0[1][1];
float Aspect_Ratio  = u_UserData0[1][2];
float Opacity       = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float dist = length( ( UV - Focus_Point ) * vec2( 1.0, Aspect_Ratio ) );
    float blurAmt = clamp( ( dist - Focus_Radius ) / max( Falloff, 0.0001 ), 0.0, 1.0 ) * Max_Blur;

    vec3 accum = tex.rgb;
    float total = 1.0;
    for ( int i = 0; i < 8; i++ )
    {
        float a = float( i ) / 8.0 * 6.28318530718;
        vec2 offs = vec2( cos( a ), sin( a ) ) * blurAmt;
        accum += texture2D( CoronaSampler0, UV + offs ).rgb;
        total += 1.0;
    }
    vec3 blurred = accum / total;

    float inFocus = 1.0 - smoothstep( 0.0, Focus_Radius, dist );
    float lum = dot( blurred, vec3( 0.299, 0.587, 0.114 ) );
    vec3 boosted = mix( vec3( lum ), blurred, 1.0 + Focus_Boost * inFocus );

    vec3 finalRGB = mix( tex.rgb, clamp( boosted, 0.0, 1.0 ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
