
--[[
    Original implementation for this bank of the standard Mandelbrot-
    set escape-time algorithm - pure public mathematics (z -> z^2 + c,
    iterated until |z| escapes past 2, or a max iteration count is
    hit), the single most-replicated fractal demo in the entire shader
    community. Zoom_Speed continuously scales the sampled region down
    around Zoom_Center for an endless zoom; iteration count is mapped
    through a cosine palette (cheap HSV-free rainbow, same trick as
    this bank's kernelG_FX_butterflyDrift hue cycle) rather than a
    literal escape-time grayscale, since a game background wants color.

    Checked against all existing kernels first: nothing else in the
    bank iterates a complex-plane recurrence at all - the closest
    surface look, kernelG_scene_starnest.lua (Kali's "Star Nest",
    ported in this bank's original non-AI-batch collection), is a
    raymarched volumetric fractal noise field, a completely different
    algorithm (3D raymarch accumulation vs 2D complex-plane escape
    time) that only resembles this one in the loose "trippy fractal
    background" sense.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "mandelbrotZoomStylized"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Zoom_Center_X','Zoom_Center_Y','Zoom_Scale','Zoom_Speed',
            'Palette_Freq','Palette_Shift','Inside_R','Inside_G',
            'Inside_B','Aspect_Ratio','Opacity','Seed',
            '','','','',
        },
        default = {
            -.745,.1,3,.06,
            3,0,.02,.02,
            .05,1,1,0,
            0,0,0,0,
        },
        min = {
            -2,-1.2,.001,0,
            .5,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,1.2,3,.3,
            10,1,.3,.3,
            .3,5,1,50,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Zoom_Center   = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Zoom_Scale    = u_UserData0[0][2];
float Zoom_Speed    = u_UserData0[0][3];
float Palette_Freq  = u_UserData0[1][0];
float Palette_Shift = u_UserData0[1][1];
vec3  Inside_Color  = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];
float Opacity       = u_UserData0[2][2];
float Seed          = u_UserData0[2][3];

const float TAU = 6.28318530718;
const int MAX_ITER = 28;

//----------------------------------------------

vec3 mandel_palette( float t )
{
    return 0.5 + 0.5 * cos( TAU * ( t * Palette_Freq + Palette_Shift + vec3( 0.0, 0.33, 0.67 ) ) );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float zoom = Zoom_Scale * exp( -CoronaTotalTime * Zoom_Speed );
    vec2 seedJitter = vec2( fract( Seed * 0.371 ), fract( Seed * 0.717 ) ) * 0.35;
    vec2 c = ( UV - vec2( 0.5 ) ) * vec2( 1.0, Aspect_Ratio ) * zoom + Zoom_Center + ( seedJitter - 0.175 * step( 0.5, Seed ) );

    vec2 z = vec2( 0.0 );
    float iter = 0.0;
    for ( int i = 0; i < MAX_ITER; i++ )
    {
        if ( dot( z, z ) > 4.0 )
        {
            break;
        }
        z = vec2( z.x * z.x - z.y * z.y, 2.0 * z.x * z.y ) + c;
        iter += 1.0;
    }

    float t = iter / float( MAX_ITER );
    float escaped = step( iter, float( MAX_ITER ) - 1.5 );
    float seedShift = fract( Seed * 0.6180339 );

    vec3 finalRGB = mix( Inside_Color, mandel_palette( fract( t + seedShift ) ), escaped );
    finalRGB = mix( Inside_Color, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
