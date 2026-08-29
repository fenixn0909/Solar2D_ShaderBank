
--[[
    https://godotshaders.com/shader/speed-shader/
    m152027350@gmail.com
    February 25, 2026

    CoronaSampler0 stands in for the original's screen capture - feed
    it a snapshot/render-to-texture. aspect correction uses
    CoronaTexelSize.zw instead of SCREEN_PIXEL_SIZE - same value.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "speedLines"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Line_Count','Line_Density','Line_Speed','Line_Falloff',
            'Line_Color_R','Line_Color_G','Line_Color_B','Line_Color_A',
            '','','','',
            '','','','',
        },
        default = { 40,.4,8,.3,  1,1,1,.5,  0,0,0,0,  0,0,0,0, },
        min =     { 1,0,0,0,     0,0,0,0,   0,0,0,0,  0,0,0,0, },
        max =     { 100,1,20,1,  1,1,1,1,   1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Line_Count    = u_UserData0[0][0];
float Line_Density  = u_UserData0[0][1];
float Line_Speed    = u_UserData0[0][2];
float Line_Falloff  = u_UserData0[0][3];
vec4  Line_Color     = vec4( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );

float TIME = CoronaTotalTime;

//----------------------------------------------

float hash( float n )
{
    return fract( sin( n ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    vec2 centered_uv = uv - vec2( 0.5 );

    float aspect = CoronaTexelSize.z / CoronaTexelSize.w;
    centered_uv.x /= aspect;

    float angle = atan( centered_uv.y, centered_uv.x );
    float dist = length( centered_uv );

    float n = hash( floor( angle * Line_Count ) );
    float thickness = abs( sin( angle * Line_Count + n ) );

    float speed = TIME * Line_Speed * ( 0.5 + n );
    float lines = step( Line_Density, fract( thickness + speed ) );

    float mask = smoothstep( Line_Falloff, Line_Falloff + 0.2, dist );
    float final_effect = lines * mask * Line_Color.a;

    vec4 screen_col = texture2D( CoronaSampler0, uv );
    vec3 mixed_color = mix( screen_col.rgb, Line_Color.rgb, final_effect );

    P_COLOR vec4 COLOR = vec4( mixed_color, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

