
--[[
    https://godotshaders.com/shader/shine/
    KingToot
    May 13, 2024

    Direct port, single texture (CoronaSampler0). Note: the original
    never explicitly samples TEXTURE - Godot pre-fills COLOR with the
    sprite's own pixel before fragment() runs, then this shader adds
    the shine on top. Solar2D has no such implicit pre-fill, so the
    base texture sample below is added explicitly to match the
    original's effective behavior.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "shine"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Line_Width','Angle','Speed','Wait_Cycles',
            'Shine_Color_R','Shine_Color_G','Shine_Color_B','Shine_Color_A',
            '','','','',
            '','','','',
        },
        default = { .1,.785398,1,1,  1,1,1,.25,  0,0,0,0,  0,0,0,0, },
        min =     { 0,0,0,0,         0,0,0,0,    0,0,0,0,  0,0,0,0, },
        max =     { 2,6.28319,10,10, 1,1,1,1,    1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Line_Width  = u_UserData0[0][0];
float Angle       = u_UserData0[0][1];
float Speed       = u_UserData0[0][2];
float Wait_Cycles = u_UserData0[0][3];
vec4 Shine_Color = vec4( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );

float TIME = CoronaTotalTime;

//----------------------------------------------

vec2 rotate_precalculated( vec2 pos, float s, float c )
{
    return vec2( pos.x * c + pos.y * -s, pos.x * s + pos.y * c );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );

    float s = sin( Angle );
    float c = cos( Angle );
    float len = 1.5 - max( abs( s ), abs( c ) ) + Line_Width;

    float wait = max(Wait_Cycles, 1.0);
    float cycle = ( len * 2.0 ) * wait;
    float t = mod( TIME * Speed, cycle );
    float line = smoothstep(
        -Line_Width, Line_Width,
        rotate_precalculated( UV - vec2( 0.5 ), s, c ).y - t + len
    );

    COLOR.rgb += Shine_Color.rgb * Shine_Color.a * vec3( line * ( 1.0 - line ) * 4.0 );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

