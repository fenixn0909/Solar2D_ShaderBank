--[[
    Whole-sprite color tween: overlay tint + animated rainbow cycle.
    Fixed: used non-Solar2D API (u_FillSampler0/v_UserData/v_ColorScale)
    so it never rendered, and the blend amount was a hardcoded
    sin(TIME*1450) strobe. Now R/G/B tint, Blend and Speed (rainbow
    cycle rate; 0 = static tint) are all real-time params.
    Creator: phoenixongogo       License: MIT
]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "colorTmr"
kernel.name = "tweenWhole"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Process','R','G','B',
            'Speed','','','',
            '','','','',
            '','','','',
        },
        default = {
            1.0,0.2,0.6,1.0,
            0.6,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            3,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Process = u_UserData0[0][0];
float Tint_R  = u_UserData0[0][1];
float Tint_G  = u_UserData0[0][2];
float Tint_B  = u_UserData0[0][3];
float Speed   = u_UserData0[1][0];

const P_COLOR vec3 kWeights = vec3( 0.2125, 0.7154, 0.0721 );

vec3 hsv2rgb_tw( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.www );
    return c.z * mix( K.xxx, clamp( p - K.xxx, 0.0, 1.0 ), c.y );
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_COLOR vec4 texColor = texture2D( CoronaSampler0, texCoord );
    P_COLOR float luminance = dot( texColor.rgb, kWeights );

    vec3 tint = vec3( Tint_R, Tint_G, Tint_B );
    vec3 desat = vec3( luminance );
    // overlay blend of the luminance with the tint
    vec3 tinted = mix( 2.0 * desat * tint,
                       1.0 - 2.0 * ( 1.0 - desat ) * ( 1.0 - tint ),
                       step( 0.5, desat ) );

    // animated rainbow cycle; Speed = 0 keeps the static tint
    float h = fract( luminance + CoronaTotalTime * Speed * 0.15 );
    vec3 cycl = hsv2rgb_tw( vec3( h, 0.75, 1.0 ) );
    float cycAmt = clamp( Speed * 0.4, 0.0, 0.85 );
    vec3 fx = mix( tinted, cycl, cycAmt );

    vec3 col = mix( texColor.rgb, fx * texColor.a, clamp( Process, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( col, texColor.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
