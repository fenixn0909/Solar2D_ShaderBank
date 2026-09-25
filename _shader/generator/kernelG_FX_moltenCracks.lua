
--[[
    Original implementation for this bank. Voronoi/Worley F2-minus-F1 cell-
    boundary distance is the standard, textbook way to draw cracked-cell
    patterns (Steven Worley's original 1996 cellular texturing paper, and
    reused in essentially every "cracked ground/ice/mud" shader since,
    including this bank's own kernelF_FX_frostbite.lua) - implemented here
    fresh, with its own 3x3-neighbourhood search (compile-time-bounded, the
    same GLES-safety reasoning as that file), for a completely different
    result: a warm, glowing lava-vein rock material rather than an ice
    crack that grows from the screen edge. This one is static/ambient - a
    slow, gentle pulse in the glow brightness rather than any spreading
    animation - closer to a forge floor or cooling obsidian material than
    a damage effect.

    Fully opaque generator (a self-contained rock material, not an
    overlay) - use it as a floor/wall texture in a lava level. Aspect_Ratio
    convention matches the rest of this bank (see kernelF_FX_shockwave.lua's
    header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "moltenCracks"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Cell_Scale','Sharpness','Pulse_Speed','Pulse_Amount',
            'Rock_R','Rock_G','Rock_B','Glow_R',
            'Glow_G','Glow_B','Glow_Brightness','Aspect_Ratio',
            '','','','',
        },
        default = {
            6,60,1.2,.25,
            .07,.05,.05,1,
            .45,.08,1.6,1,
            0,0,0,0,
        },
        min = {
            1,5,0,0,
            0,0,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            20,200,5,1,
            1,1,1,1,
            1,1,4,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cell_Scale     = u_UserData0[0][0];
float Sharpness      = u_UserData0[0][1];
float Pulse_Speed    = u_UserData0[0][2];
float Pulse_Amount   = u_UserData0[0][3];
vec3  Rock_Color     = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Glow_Color     = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Glow_Brightness= u_UserData0[2][2];
float Aspect_Ratio   = u_UserData0[2][3];

const int SEARCH_R = 1;

P_RANDOM vec2 hash22( vec2 p )
{
    vec2 q = vec2( dot( p, vec2( 127.1, 311.7 ) ), dot( p, vec2( 269.5, 183.3 ) ) );
    return fract( sin( q ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;
    vec2 p = uv * Cell_Scale;

    vec2 cellId = floor( p );
    vec2 localP = fract( p );

    float f1 = 8.0;
    float f2 = 8.0;

    for ( int y = -SEARCH_R; y <= SEARCH_R; y++ ) {
        for ( int x = -SEARCH_R; x <= SEARCH_R; x++ ) {
            vec2 neighbor = vec2( float( x ), float( y ) );
            vec2 point = hash22( cellId + neighbor );
            vec2 diff = neighbor + point - localP;
            float dist = length( diff );
            if ( dist < f1 ) {
                f2 = f1;
                f1 = dist;
            } else if ( dist < f2 ) {
                f2 = dist;
            }
        }
    }

    float crackDist = f2 - f1;
    float glowMask = exp( -crackDist * crackDist * Sharpness );

    float pulse = 1.0 + sin( CoronaTotalTime * Pulse_Speed ) * Pulse_Amount;

    vec3 rgb = mix( Rock_Color, Glow_Color * Glow_Brightness * pulse, glowMask );

    P_COLOR vec4 COLOR = vec4( rgb, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
