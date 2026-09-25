
--[[
    Original implementation for this bank of isoline/contour
    extraction, a standard "shader school" technique: treat an fbm
    field as elevation, draw a line wherever fract(height*Density)
    crosses a fixed threshold (the same repeating-contour trick as
    this batch's kernelG_FX_curlNoiseFlowLines, applied here to static
    elevation banding rather than flow visualization), and color each
    band through a cascaded low-to-high elevation ramp the way a real
    topographic map shades water/lowland/highland/snow-cap.

    Checked against all existing kernels first: this bank's own
    kernelG_FX_curlNoiseFlowLines (this batch) extracts the same kind
    of contour line but treats it as a *flow direction* visualization
    with a single line color and a physically-meaningful phase drift;
    this kernel instead colors by absolute elevation band (a multi-
    stop topographic palette, not a single flow-line tint) and reads
    as a static/slow-drifting map rather than a directional flow -
    different purpose and different color model despite the shared
    contour-extraction trick underneath. No other kernel in the bank
    does elevation-band topographic coloring.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "isolineTopographicFlow"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Scale','Speed','Density','Line_Width',
            'Line_R','Line_G','Line_B','Opacity',
            'Seed','','','',
            '','','','',
        },
        default = {
            2.2,.015,10,.05,
            .1,.15,.1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .5,-.1,3,.01,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            5,5,24,.15,
            1,1,1,1,
            50,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Scale       = u_UserData0[0][0];
float Speed       = u_UserData0[0][1];
float Density     = u_UserData0[0][2];
float Line_Width  = u_UserData0[0][3];
vec3  Line_Color  = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Opacity     = u_UserData0[1][3];
float Seed        = u_UserData0[2][0];

//----------------------------------------------

P_RANDOM float topo_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 33.1, 87.4 ) ) ) * 43758.5453123 );
}

P_RANDOM float topo_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( topo_hash( i ), topo_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( topo_hash( i + vec2( 0.0, 1.0 ) ), topo_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float topo_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 4; i++ )
    {
        total += topo_noise( p ) * amp;
        p *= 2.02;
        amp *= 0.5;
    }
    return total;
}

vec3 topo_palette( float h )
{
    vec3 water = vec3( 0.10, 0.25, 0.45 );
    vec3 lowland = vec3( 0.20, 0.45, 0.25 );
    vec3 highland = vec3( 0.55, 0.45, 0.25 );
    vec3 peak = vec3( 0.92, 0.92, 0.95 );

    vec3 col = mix( water, lowland, smoothstep( 0.25, 0.45, h ) );
    col = mix( col, highland, smoothstep( 0.55, 0.72, h ) );
    col = mix( col, peak, smoothstep( 0.8, 0.92, h ) );
    return col;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 seedOff = vec2( Seed * 1.37, Seed * 0.73 );
    float h = topo_fbm( UV * Scale + seedOff + vec2( CoronaTotalTime * Speed, Seed * 0.11 ) );

    float v = h * Density;
    float contour = abs( fract( v ) - 0.5 ) * 2.0;
    float lineMask = smoothstep( Line_Width, 0.0, contour );

    vec3 elevationColor = topo_palette( h );
    vec3 finalRGB = mix( elevationColor, Line_Color, lineMask );
    finalRGB = mix( elevationColor, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
