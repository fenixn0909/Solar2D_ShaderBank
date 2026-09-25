
--[[
    https://godotshaders.com/shader/pixel-melting-and-falling/
    HaikaDev
    October 21, 2025

    Original needs 3 textures (the sprite + two gradient lookup
    textures) - reduced to 1 (CoronaSampler0, the sprite) by replacing
    both gradients with flat tint colors instead of full ramps -
    simpler to tune than authoring gradient texture assets, at the
    cost of the smooth multi-stop color transition. Also dropped
    atlas_size/animated-spritesheet support (fixed at a single frame)
    to keep the param count sane.

    fall_distance drove a uniform-bound loop in the original, which
    isn't GLES2-safe - below it's a fixed 32-step constant loop with
    an early break once Fall_Distance is reached.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "pixelMelting"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Animation_Progress','Random_Influence','Melting_Point_X','Melting_Point_Y',
            'Melting_Time','Falling_Time','Fall_Distance','Melt_Color_R',
            'Melt_Color_G','Melt_Color_B','Fall_Color_R','Fall_Color_G',
            'Fall_Color_B','','','',
        },
        default = { 0,.05,.5,.5,  .1,.2,16,1,  .6,0,1,.3,  0,0,0,0, },
        min =     { 0,0,0,0,      .01,.01,4,0, 0,0,0,0,    0,0,0,0, },
        max =     { 1,.3,1,1,     1,1,32,1,    1,1,1,1,    1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Animation_Progress = u_UserData0[0][0];
float Random_Influence   = u_UserData0[0][1];
vec2  Melting_Point       = vec2( u_UserData0[0][2], u_UserData0[0][3] );
float Melting_Time       = u_UserData0[1][0];
float Falling_Time       = u_UserData0[1][1];
float Fall_Distance      = u_UserData0[1][2];
vec3  Melt_Color          = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
vec3  Fall_Color          = vec3( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0] );

vec2 texture_pixel_size = CoronaTexelSize.xy;

//----------------------------------------------

float noiseFn( vec3 v )
{
    float random = dot( v, vec3( 12.9898, 78.233, 37.719 ) );
    random = fract( random );
    return random;
}

float get_melting_progress( float animProgress )
{
    float sum = Melting_Time + 1.0 + Falling_Time;
    float a = Melting_Time / sum;
    float b = 1.0 / sum;
    return ( animProgress - a ) / b;
}

float get_melting_progress_to_point( float animProgress, vec2 uv )
{
    uv = floor( uv / texture_pixel_size ) * texture_pixel_size;
    float distance_from_center = distance( uv, Melting_Point ) / sqrt( 2.0 );
    float progress = get_melting_progress( animProgress ) - distance_from_center;
    float rnd = noiseFn( vec3( uv, 0.0 ) ) * Random_Influence - Random_Influence * 0.5;
    return progress + rnd;
}

float get_falling_progress( float animProgress, vec2 uv )
{
    float progress = get_melting_progress_to_point( animProgress, uv );
    progress /= Falling_Time;
    progress = min( max( progress, 0.0 ), 1.0 );
    return progress;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );

    vec2 uv_whole = floor( UV / texture_pixel_size ) * texture_pixel_size;
    vec2 uv = fract( uv_whole );

    float progress = get_melting_progress_to_point( Animation_Progress, uv );

    if ( progress > 0.0 ) {
        COLOR.a = 0.0;
    } else {
        float melting_progress = ( progress + Melting_Time ) / Melting_Time;
        melting_progress = min( max( melting_progress, 0.0 ), 1.0 );

        if ( melting_progress > 0.0 ) {
            vec4 melt_color = vec4( Melt_Color, melting_progress );
            melt_color.a *= COLOR.a;
            COLOR = mix( COLOR, melt_color, melt_color.a );
        }
    }

    vec4 falling_color = vec4( 0.0 );
    for ( int hi = 0; hi < 96; hi++ ) {
        float height = float( hi ) * 0.33;
        if ( height >= Fall_Distance ) break;

        vec2 fall_uv = uv_whole + vec2( 0.0, -1.0 * height ) * texture_pixel_size;
        vec2 fall_uv_fract = fract( fall_uv );

        float f_progress = get_falling_progress( Animation_Progress, fall_uv_fract );
        float pixel_distance = ( f_progress * f_progress * Fall_Distance ) - height;

        if ( pixel_distance > 0.0 && abs( pixel_distance ) < 0.5 && fall_uv_fract.y > 0.0 ) {
            vec4 particle_color = vec4( Fall_Color, f_progress );
            particle_color.a *= texture2D( CoronaSampler0, fall_uv ).a;
            falling_color = mix( falling_color, particle_color, particle_color.a );
        }
    }

    COLOR = mix( COLOR, falling_color, falling_color.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

