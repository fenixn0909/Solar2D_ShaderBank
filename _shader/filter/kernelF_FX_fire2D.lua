
--[[
    https://godotshaders.com/shader/anime-style-fire-2d/
    ProfesorShader
    July 26, 2026

    Original samples 3-4 textures (draw_tex, normal_tex, noise_tex,
    optional mask_tex). Solar2D filter kernels only get one input
    texture, so normal_tex and noise_tex are replaced here with
    procedural value noise (same look, self-contained); the optional
    distortion-exclusion mask is dropped (it was optional in the
    original too). draw_tex is kept as-is and maps to CoronaSampler0 -
    IMPORTANT: this still needs a texture whose RED channel is the
    "outside" flame-lick shape and GREEN channel is the "inside" core
    shape, same as the original required (that mask is hand-authored
    artwork, not something proceduraly generated - see the original
    post's github for an example one; per godotshaders.com's own
    license note, code is CC0 but textures/assets are not, so no
    texture is bundled here).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "fire2D"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed','Fps','Normal_Scl_Out','Normal_Scl_In',
            'Noise_Scl_Out','Noise_Scl_In','Distortion_Scl_Out','Distortion_Scl_In',
            '','','','',
            '','','','',
        },
        default = {
            .5, 12, 1.5, 2.0,
            .4, .2, .10, .08,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0, 1, .1, .1,
            .05, .05, 0, 0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3, 30, 6, 6,
            2, 2, .5, .5,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Speed              = u_UserData0[0][0];
float Fps                = u_UserData0[0][1];
float Normal_Scl_Out     = u_UserData0[0][2];
float Normal_Scl_In      = u_UserData0[0][3];
float Noise_Scl_Out      = u_UserData0[1][0];
float Noise_Scl_In       = u_UserData0[1][1];
float Distortion_Scl_Out = u_UserData0[1][2];
float Distortion_Scl_In  = u_UserData0[1][3];

// fixed 2-tone gradients (outside flame licks / inner core), matching
// the original shader's default palette - edit here to recolor.
P_COLOR vec4 Color_Out_A = vec4( 1.0, 0.0,  0.0, 1.0 );
P_COLOR vec4 Color_Out_B = vec4( 1.0, 0.25, 0.0, 1.0 );
P_COLOR vec4 Color_In_A  = vec4( 1.0, 1.0,  0.0, 1.0 );
P_COLOR vec4 Color_In_B  = vec4( 1.0, 1.0,  0.5, 1.0 );

float TIME = CoronaTotalTime;

//----------------------------------------------
// procedural stand-in for the original's noise_tex / normal_tex samples

float hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash( i );
    float b = hash( i + vec2( 1.0, 0.0 ) );
    float c = hash( i + vec2( 0.0, 1.0 ) );
    float d = hash( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( a, b, u.x ) + ( c - a ) * u.y * ( 1.0 - u.x ) + ( d - b ) * u.x * u.y;
}

vec2 noise2( vec2 p )
{
    return vec2( valueNoise( p ), valueNoise( p + vec2( 37.2, 91.7 ) ) );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv_out = UV;
    vec2 uv_in = UV;

    float t = floor( TIME * Fps ) / Fps;
    uv_out.y += t * Speed;
    uv_in.y += ( 0.5 + t ) * Speed;

    vec2 noi_out = ( noise2( uv_out * Noise_Scl_Out ) * 2.0 ) - 1.0;
    vec2 noi_in  = ( noise2( uv_in  * Noise_Scl_In  ) * 2.0 ) - 1.0;

    vec2 nrm_out = ( noise2( ( uv_out * Normal_Scl_Out ) + noi_out ) * 2.0 ) - 1.0;
    vec2 nrm_in  = ( noise2( ( uv_in  * Normal_Scl_In  ) + noi_in  ) * 2.0 ) - 1.0;

    vec2 distorted_uv_out = UV + vec2( nrm_out.x, -nrm_out.y ) * Distortion_Scl_Out;
    vec2 distorted_uv_in  = UV + vec2( nrm_in.x,  -nrm_in.y  ) * Distortion_Scl_In;

    // draw_tex: R channel = outside flame-lick mask, G channel = inner core mask
    float outside = texture2D( CoronaSampler0, distorted_uv_out ).r;
    float inside  = texture2D( CoronaSampler0, distorted_uv_in  ).g;

    P_COLOR vec4 COLOR = outside * mix( Color_Out_A, Color_Out_B, UV.y );
    COLOR = mix( COLOR, mix( Color_In_A, Color_In_B, UV.y ), inside );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

