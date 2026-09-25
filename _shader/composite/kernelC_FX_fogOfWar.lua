
--[[
    https://godotshaders.com/shader/fog-of-war-with-alpha-cut-off-as-white-color/
    eligijusk
    November 23, 2023

    paint1 = the scene/sprite being fogged (CoronaSampler0), paint2 = a
    tileable greyscale noise texture (CoronaSampler1, matches the
    original's NOISE_PATTERN). Direct port - the original's unused
    `negative_fog_value` variable (flagged as dead in the post's own
    comments) is dropped rather than carried over.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "fogOfWar"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Octaves','Starting_Amplitude','Starting_Frequency','Shift',
            'White_Cutoff','Velocity_X','Velocity_Y','Fog_Color_R',
            'Fog_Color_G','Fog_Color_B','Fog_Color_A','',
            '','','','',
        },
        default = {
            4, .5, 1, 0,
            .999, 1, 1, 0,
            0, 0, 1, 0,
            0,0,0,0,
        },
        min = {
            1, 0, .1, -1,
            0, -3, -3, 0,
            0, 0, 0, 0,
            0,0,0,0,
        },
        max = {
            8, .5, 6, 0,
            1, 3, 3, 1,
            1, 1, 1, 1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Octaves              = u_UserData0[0][0];
float Starting_Amplitude   = u_UserData0[0][1];
float Starting_Frequency   = u_UserData0[0][2];
float Shift                = u_UserData0[0][3];
float White_Cutoff         = u_UserData0[1][0];
vec2  Velocity              = vec2( u_UserData0[1][1], u_UserData0[1][2] );
vec4  Fog_Color             = vec4( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );

float TIME = CoronaTotalTime;

//----------------------------------------------

float fog_noise( vec2 uv )
{
    float amplitude = Starting_Amplitude;
    float frequency = Starting_Frequency;
    float result = 0.0;
    int octaves_i = int( Octaves );

    for ( int i = 0; i < 8; i++ ) {
        if ( i >= octaves_i ) {
            break;
        }
        result += texture2D( CoronaSampler1, uv * frequency ).x * amplitude;
        amplitude /= 2.0;
        frequency *= 2.0;
    }
    return clamp( result + Shift, 0.0, 1.0 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 mainTexture = texture2D( CoronaSampler0, UV );
    vec2 motion = vec2( fog_noise( UV + TIME * Starting_Frequency * Velocity ) );

    P_COLOR vec4 COLOR = mix( mainTexture, Fog_Color, fog_noise( UV + motion ) );

    float real_alpha_cutoff = 1.0 - White_Cutoff;
    if ( COLOR.r * COLOR.g * COLOR.b > real_alpha_cutoff ) {
        COLOR.a = 0.0;
    }

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

