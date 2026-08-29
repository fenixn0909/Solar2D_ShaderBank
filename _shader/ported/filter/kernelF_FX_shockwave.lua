
--[[
    https://godotshaders.com/shader/distortion/
    mrsir8433
    April 16, 2022 (updated September 2, 2023)

    CoronaSampler0 stands in for the original's screen-space capture
    (hint_screen_texture) - feed this filter a snapshot/render-to-
    texture of what should ripple, same as any other screen-space
    effect in this bank (no automatic backbuffer access like Godot's).
    Aspect-ratio correction re-derived: the original scales by
    SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x (screen height/width);
    here that becomes Aspect_Ratio, a plain tunable (default 1 = no
    correction, set it to your object's height/width if it's non-
    square). Center/radius/aberration math otherwise ported as-is.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "shockwave"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Strength','Center_X','Center_Y','Radius',
            'Aberration','Width','Feather','Aspect_Ratio',
            '','','','',
            '','','','',
        },
        default = {
            .08, .5, .5, .25,
            .425, .04, .135, 1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0, 0, 0, 0,
            0, 0, 0, .2,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            10, 1, 1, 1,
            1, .1, 1, 5,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Strength     = u_UserData0[0][0];
vec2  Center        = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Radius        = u_UserData0[0][3];
float Aberration   = u_UserData0[1][0];
float Width         = u_UserData0[1][1];
float Feather       = u_UserData0[1][2];
float Aspect_Ratio  = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 st = UV;
    vec2 scaled_st = ( st - vec2( 0.0, 0.5 ) ) / vec2( 1.0, Aspect_Ratio ) + vec2( 0.0, 0.5 );

    vec2 dist_center = scaled_st - Center;
    float mask =
        ( 1.0 - smoothstep( Radius - Feather, Radius, length( dist_center ) ) ) *
        smoothstep( Radius - Width - Feather, Radius - Width, length( dist_center ) );

    vec2 offset = normalize( dist_center ) * Strength * mask;
    vec2 biased_st = scaled_st - offset;

    vec2 abber_vec = offset * Aberration * mask;

    vec2 final_st = st * ( 1.0 - mask ) + biased_st * mask;

    P_COLOR vec4 red  = texture2D( CoronaSampler0, final_st + abber_vec );
    P_COLOR vec4 blue = texture2D( CoronaSampler0, final_st - abber_vec );
    P_COLOR vec4 ori  = texture2D( CoronaSampler0, final_st );

    P_COLOR vec4 COLOR = vec4( red.r, ori.g, blue.b, ori.a );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

