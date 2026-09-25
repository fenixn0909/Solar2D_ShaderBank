
--[[
    Original implementation for this bank, stylized after Turing
    reaction-diffusion patterns (the same class of math behind animal
    coat markings, and a recurring generative-art shader subject). A
    true reaction-diffusion system needs iterative multi-pass
    simulation, which a single fragment pass can't do - this instead
    fakes the *look* with two offset noise layers, folding one of them
    through abs(n-0.5)*2.0 to turn smooth bands into isolated blob
    shapes, and Spot_Blend crossfades between the raw banded look and
    the folded spotted look. Documented here as a closed-form stylized
    approximation, not a claim of simulating real reaction-diffusion.

    Checked against all existing kernels first: kernelG_FX_gemSparkle/
    starField and other multi-point kernels place discrete hashed
    points, not a continuous thresholded noise mask; this bank's other
    fbm-based kernels (arcaneSmoke, sandstormDrift) use noise for soft
    density/coverage, not a hard Threshold-based spot/stripe mask with
    a blend control between the two organic-pattern families.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "reactionDiffusionSpots"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Scale','Spot_Blend','Threshold','Speed',
            'Base_R','Base_G','Base_B','Spot_R',
            'Spot_G','Spot_B','Aspect_Ratio','Opacity',
            '','','','',
        },
        default = {
            4,.6,.5,.03,
            .85,.8,.7,.15,
            .1,.08,1,1,
            0,0,0,0,
        },
        min = {
            1,0,.2,0,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            10,1,.8,5,
            1,1,1,1,
            1,1,5,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Scale         = u_UserData0[0][0];
float Spot_Blend    = u_UserData0[0][1];
float Threshold     = u_UserData0[0][2];
float Speed         = u_UserData0[0][3];
vec3  Base_Color    = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Spot_Color    = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Aspect_Ratio  = u_UserData0[2][2];
float Opacity       = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float rd_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 19.4, 53.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float rd_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( rd_hash( i ), rd_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( rd_hash( i + vec2( 0.0, 1.0 ) ), rd_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float rd_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 4; i++ )
    {
        total += rd_noise( p ) * amp;
        p *= 2.08;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p = UV * vec2( 1.0, Aspect_Ratio ) * Scale + vec2( CoronaTotalTime * Speed, 0.0 );
    float n = rd_fbm( p );

    float spotted = abs( n - 0.5 ) * 2.0;
    float pattern = mix( n, spotted, Spot_Blend );

    float mask = smoothstep( Threshold - 0.06, Threshold + 0.06, pattern );
    vec3 finalRGB = mix( Base_Color, Spot_Color, mask );
    finalRGB = mix( Base_Color, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
