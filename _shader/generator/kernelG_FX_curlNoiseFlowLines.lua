
--[[
    Original implementation for this bank of the "flow field" look
    common in generative-art shader demos. Curl noise works by taking
    a scalar potential field and using its rotated gradient as a
    divergence-free flow direction - and by construction, the flow
    lines of that field are exactly the potential's own contour lines,
    so drawing animated contours of an fbm potential (phase-shifted
    over time to slide them "downhill") reproduces genuine curl-noise
    streamlines without needing a separate per-pixel advection loop.

    Checked against all existing kernels first: kernelG_FX_
    signalRipple/kernelG_generator waveForms draw fixed sine-wave line
    patterns with no underlying noise field or flow-direction meaning;
    this bank's fbm-based kernels (arcaneSmoke, sandstormDrift and
    others) use noise for density/coverage masking, not for extracting
    and drawing flow contour lines. No existing kernel visualizes a
    flow field this way.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "curlNoiseFlowLines"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Scale','Density','Speed','Line_Width',
            'Color_R','Color_G','Color_B','BG_R',
            'BG_G','BG_B','Opacity','',
            '','','','',
        },
        default = {
            2.5,10,.3,.12,
            .4,.85,1,.03,
            .04,.07,1,0,
            0,0,0,0,
        },
        min = {
            .5,2,-1,.02,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            6,30,1,.4,
            1,1,1,1,
            1,1,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Scale       = u_UserData0[0][0];
float Density     = u_UserData0[0][1];
float Speed       = u_UserData0[0][2];
float Line_Width  = u_UserData0[0][3];
vec3  Line_Color  = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  BG_Color    = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Opacity     = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float flow_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 12.9, 78.2 ) ) ) * 43758.5453123 );
}

P_RANDOM float flow_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( flow_hash( i ), flow_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( flow_hash( i + vec2( 0.0, 1.0 ) ), flow_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float flow_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 4; i++ )
    {
        total += flow_noise( p ) * amp;
        p *= 2.05;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float potential = flow_fbm( UV * Scale );
    float v = potential * Density - CoronaTotalTime * Speed;
    float lines = abs( fract( v ) - 0.5 ) * 2.0;
    float mask = smoothstep( Line_Width, 0.0, lines );

    vec3 finalRGB = mix( BG_Color, Line_Color, mask );
    finalRGB = mix( BG_Color, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
