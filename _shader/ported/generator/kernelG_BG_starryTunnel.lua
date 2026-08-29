--[[
    https://godotshaders.com/shader/2dstarry-tunnel/
    xcv145336
    May 17, 2025 (ver1.3 Sep 23 2025)

    CC0.

    Full-screen starry tunnel / warp tunnel. Original canvas_item shader
    with toggleable neon glow (hasNeonEffect) and solid dots (hasDot),
    optional z-expand (haszExpend), and mask modes (isdarktotransparent,
    bemask, iswhite). The 1.3 update adds rotate_speed,
    rotate_plane_speed, theta_sine_change_speed time-driven theta motion.

    Port notes:
    - Uniform bools (hasNeonEffect, hasDot, haszExpend, iswhite,
      isdarktotransparent, bemask) become 0/1 floats for slider UI;
      int m/n stay as floats (loop bounds). GLES2-safe loops use
      const MAX_M=8 / MAX_N=30 with early break if i>=m or j>=n, same
      pattern as torchFlame (512/50 caps) in this bank.
    - Uniform ranges preserved from original hints where given; bools
      as 0..1. hasNeonEffect/hasDot gate the outer j loop exactly like
      the source: `j<n && (hasDot||hasNeonEffect)`.
    - scale is small (0.001-0.01) so Size uniform maps 1:1.
    - No textures, pure generator (category generator.BG) like
      starField/stars; uses UV -> suv = (UV-0.5)*2 like the original.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "starryTunnel"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Theta','Add_H','Scale','Light_Disperse',
            'Stertch','Speed','Mod_Time','Rotate_Speed',
            'Rotate_Plane_Speed','Theta_Sine_Change_Speed','M','N',
            'Has_Neon','Has_Dot','Has_Z_Expend','Is_White',
        },
        default = {
            80, 30, .01, 2,
            30, 10, 20, 0,
            0, 0, 8, 30,
            1, 0, 0, 1,
        },
        min = {
            0, 0, .001, .1,
            1, -50, 1, -50,
            -50, -50, 1, 1,
            0, 0, 0, 0,
        },
        max = {
            80, 90, .01, 10,
            1000, 50, 50, 50,
            50, 50, 8, 30,
            1, 1, 1, 1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniMode",
        paramName = {
            'Is_Dark_To_Transparent','Be_Mask','', '',
            '','','','',
            '','','','',
            '','','','',
        },
        default = {
            0, 0, 0,0,
            0,0,0,0,
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
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
//----------------------------------------------

float Theta                      = u_UserData0[0][0];
float Add_H                      = u_UserData0[0][1];
float Scale                      = u_UserData0[0][2];
float Light_Disperse             = u_UserData0[0][3];
float Stertch                    = u_UserData0[1][0];
float Speed                      = u_UserData0[1][1];
float Mod_Time                   = u_UserData0[1][2];
float Rotate_Speed               = u_UserData0[1][3];
float Rotate_Plane_Speed         = u_UserData0[2][0];
float Theta_Sine_Change_Speed    = u_UserData0[2][1];
float M                          = u_UserData0[2][2];
float N                          = u_UserData0[2][3];
float Has_Neon                   = u_UserData0[3][0];
float Has_Dot                    = u_UserData0[3][1];
float Has_Z_Expend               = u_UserData0[3][2];
float Is_White                   = u_UserData0[3][3];

float Is_Dark_To_Transparent     = u_UserData1[0][0];
float Be_Mask                    = u_UserData1[0][1];

float TIME = CoronaTotalTime;
const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const int MAX_M = 8;
const int MAX_N = 30;

//----------------------------------------------

float random( vec2 uv )
{
    return fract( sin( dot( uv.xy, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

bool vec3lower( vec3 A, float v )
{
    return A.r <= v && A.b <= v && A.g <= v;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = vec4( 0.0 );

    vec2 suv = ( UV - 0.5 ) * 2.0;

    bool hasNeon = Has_Neon > 0.5;
    bool hasDot = Has_Dot > 0.5;
    bool haszExpend = Has_Z_Expend > 0.5;
    bool iswhite = Is_White > 0.5;

    int m_i = int( M );
    int n_i = int( N );
    float modTime = max( Mod_Time, 1.0 );
    float scale = max( Scale, 0.0001 );
    float light_disperse = max( Light_Disperse, 0.1 );
    float theta = Theta;
    float addH = Add_H;

    // outer j loop gated by (hasDot||hasNeonEffect) exactly like source
    for ( int j = 0; j < MAX_N; j++ ) {
        if ( j >= n_i ) break;
        if ( !(hasDot || hasNeon) ) break;

        float seed = random( vec2( 2.0 - float( j ), float( j ) * 37.0 ) );

        for ( int i = 0; i < MAX_M; i++ ) {
            if ( i >= m_i ) break;

            float z = mod( 5.0 + float( n_i ) / float( max( j, 1 ) ) * 10.0 + TIME * Speed + 8.0 + float( i ) * scale * Stertch, modTime ) * scale;
            float aphla = seed * TAU + TIME * Rotate_Speed;
            float H = addH * scale + z * tan( ( theta + TIME * Theta_Sine_Change_Speed ) / 180.0 * PI );
            float zscale = haszExpend ? min( z + 0.06, modTime ) * scale * modTime * 0.5 : scale;
            vec2 nuv = vec2( H * cos( aphla + TIME * Rotate_Plane_Speed ), H * sin( aphla ) );

            if ( hasNeon ) {
                float l = max( exp( -( distance( suv / zscale, nuv / zscale ) / light_disperse ) ), 0.0 );
                vec4 L;
                if ( iswhite ) {
                    L = vec4( vec3( l ), 1.0 );
                } else {
                    float r = random( vec2( seed, float( j ) * 37.0 ) );
                    float g = random( vec2( 7.0 + float( j ), seed ) );
                    float b = random( vec2( seed, 3.0 - float( j ) ) );
                    L = vec4( r * l, g * l, b * l, 1.0 );
                }
                COLOR = min( COLOR + L, vec4( 1.0 ) );
            }

            if ( distance( suv, nuv ) < 1.0 * zscale && hasDot ) {
                COLOR = vec4( 1.0 );
            }
        }
    }

    bool isdark = Is_Dark_To_Transparent > 0.5;
    bool bemask = Be_Mask > 0.5;

    if ( isdark ) {
        COLOR = ( vec3lower( COLOR.rgb, 0.16 ) ) ? vec4( 0.0 ) : COLOR;
    } else {
        COLOR = bemask ? ( ( !vec3lower( COLOR.rgb, 0.16 ) ) ? vec4( 0.0 ) : COLOR ) : COLOR;
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
--]]
