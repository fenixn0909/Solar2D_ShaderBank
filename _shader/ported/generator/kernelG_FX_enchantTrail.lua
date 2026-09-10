
--[[
    Original implementation for this bank. Unlike this batch's
    kernelG_FX_spiritWisp.lua (a closed-form, self-wandering trail that
    needs zero input), this one is data-driven: five UV-space points you
    update from Lua each frame with your object's own recent positions
    (a thrown weapon, a spell projectile, a sword swing), each rendered as
    a small spinning rune-notch glyph that fades with age. The five points
    are drawn via five explicit calls to one glyph function rather than a
    loop over a local array - GLSL ES 1.00 implementations vary on
    whether dynamic-index array reads are safe on older hardware, and
    this bank's kernels avoid that gray area throughout (fixed compile-
    time loop bounds only, indexed by the loop variable itself, never used
    to index a second local array).

    Pure generator, transparent background. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "enchantTrail"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Point1_X','Point1_Y','Point2_X','Point2_Y',
            'Point3_X','Point3_Y','Point4_X','Point4_Y',
            'Point5_X','Point5_Y','Glyph_Size','Spin_Speed',
            'Color_R','Color_G','Color_B','Aspect_Ratio',
        },
        default = {
            .5,.5,.45,.55,
            .4,.6,.35,.65,
            .3,.7,.05,3,
            .65,.85,1,1,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,.01,-10,
            0,0,0,.2,
        },
        max = {
            1,1,1,1,
            1,1,1,1,
            1,1,.15,10,
            1,1,1,5,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Point1_X     = u_UserData0[0][0];
float Point1_Y     = u_UserData0[0][1];
float Point2_X     = u_UserData0[0][2];
float Point2_Y     = u_UserData0[0][3];
float Point3_X     = u_UserData0[1][0];
float Point3_Y     = u_UserData0[1][1];
float Point4_X     = u_UserData0[1][2];
float Point4_Y     = u_UserData0[1][3];
float Point5_X     = u_UserData0[2][0];
float Point5_Y     = u_UserData0[2][1];
float Glyph_Size   = u_UserData0[2][2];
float Spin_Speed   = u_UserData0[2][3];
vec3  Color        = vec3( u_UserData0[3][0], u_UserData0[3][1], u_UserData0[3][2] );
float Aspect_Ratio = u_UserData0[3][3];

float glyphAt( vec2 uv, vec2 point, float fadeIndex )
{
    vec2 toPoint = uv - point;
    float dist = length( toPoint );
    float ang = atan( toPoint.y, toPoint.x ) + CoronaTotalTime * Spin_Speed;

    float fade = pow( 1.0 - fadeIndex / 5.0, 2.0 );
    float size = Glyph_Size * ( 0.5 + 0.5 * fade );

    float ring = ( 1.0 - smoothstep( size * 0.7, size * 0.85, dist ) ) * smoothstep( size * 0.3, size * 0.45, dist );
    float notch = step( 0.5, fract( ang / 6.28318 * 4.0 ) );
    float mark = ring * mix( 0.3, 1.0, notch );

    float core = exp( -dist * dist * ( 3.0 / max( size * 0.3, 0.005 ) ) );

    return ( mark + core * 0.6 ) * fade;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uvS = vec2( UV.x * Aspect_Ratio, UV.y );

    float total = 0.0;
    total += glyphAt( uvS, vec2( Point1_X * Aspect_Ratio, Point1_Y ), 0.0 );
    total += glyphAt( uvS, vec2( Point2_X * Aspect_Ratio, Point2_Y ), 1.0 );
    total += glyphAt( uvS, vec2( Point3_X * Aspect_Ratio, Point3_Y ), 2.0 );
    total += glyphAt( uvS, vec2( Point4_X * Aspect_Ratio, Point4_Y ), 3.0 );
    total += glyphAt( uvS, vec2( Point5_X * Aspect_Ratio, Point5_Y ), 4.0 );

    total = clamp( total, 0.0, 1.0 );
    vec3 rgb = Color * total;

    P_COLOR vec4 COLOR = vec4( rgb, total );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
