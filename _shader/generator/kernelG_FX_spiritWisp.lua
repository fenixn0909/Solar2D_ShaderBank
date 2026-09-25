
--[[
    Original implementation for this bank. Builds a fading "trail" the
    cheap way, without any actual particle history buffer or feedback
    texture: the wisp's position is a closed-form function of time (a
    Lissajous-style wander), so past positions can be re-evaluated
    directly by just plugging in earlier `t` values - a fixed, compile-
    time-bounded number of trail steps (same GLES-safety reasoning as the
    other loop-based kernels in this bank) each sample the same path
    function slightly further in the past and get progressively dimmer
    and smaller, which reads as a soft trailing tail with zero extra
    state needed between frames.

    Pure generator, transparent background - a floating soul/spirit/will-
    o'-the-wisp companion or collectible. Aspect_Ratio convention matches
    the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "spiritWisp"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed','Wander','Size','Trail_Delay',
            'Brightness','Flicker_Speed','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            1,.3,.05,.045,
            1.2,5,.55,.9,
            .85,1,0,0,
            0,0,0,0,
        },
        min = {
            0,.05,.01,.01,
            0,0,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            4,.5,.2,.15,
            3,15,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Speed         = u_UserData0[0][0];
float Wander        = u_UserData0[0][1];
float Size          = u_UserData0[0][2];
float Trail_Delay   = u_UserData0[0][3];
float Brightness    = u_UserData0[1][0];
float Flicker_Speed = u_UserData0[1][1];
vec3  Color         = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];

const int TAIL_STEPS = 10;

vec2 wispPos( float t )
{
    float a = t * Speed;
    return vec2(
        cos( a * 1.3 ) * 0.5 + sin( a * 0.7 ) * 0.5,
        sin( a * 1.1 ) * 0.5 + cos( a * 0.5 ) * 0.3
    ) * Wander;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float total = 0.0;
    float coreBrightness = 0.0;

    for ( int step_ = 0; step_ < TAIL_STEPS; step_++ ) {
        float fk = float( step_ );
        float t = CoronaTotalTime - fk * Trail_Delay;
        vec2 pos = wispPos( t );

        float dist = length( uv - pos );
        float fade = pow( 1.0 - fk / float( TAIL_STEPS ), 2.0 );
        float size = Size * ( 0.3 + 0.7 * fade );
        float glow = exp( -dist * dist * ( 4.0 / max( size, 0.01 ) ) ) * fade;

        total += glow;
        if ( step_ == 0 ) {
            coreBrightness = glow;
        }
    }

    float flicker = 0.85 + 0.15 * sin( CoronaTotalTime * Flicker_Speed );
    vec3 hot = mix( Color, vec3( 1.0 ), 0.5 );
    vec3 rgb = ( Color * total + hot * coreBrightness * 0.8 ) * Brightness * flicker;
    float alpha = clamp( total * Brightness * flicker, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
