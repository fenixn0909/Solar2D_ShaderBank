
--[[
    Original implementation for this bank. A diagonal caution/hazard
    stripe overlay for platformer moving/crumbling/warning platforms -
    two alternating colors in a repeating diagonal band, with an
    optional slow scroll (reads as "this platform is in motion") and a
    slow brightness pulse (reads as "pay attention to this one").

    Checked against all existing kernels first: nothing else in the
    bank draws a two-tone diagonal hazard-stripe pattern; closest by
    surface pattern are kernelG_generator/checkerboard (orthogonal
    squares, not diagonal stripes, no scroll/pulse) and this bank's
    various wobble/sway filters (deform an existing sprite's UVs,
    don't paint a stripe pattern on top). No overlap.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "movingPlatformStripe"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Stripe_Freq','Stripe_Angle','Scroll_Speed','Pulse_Speed',
            'Color1_R','Color1_G','Color1_B','Color2_R',
            'Color2_G','Color2_B','Opacity','',
            '','','','',
        },
        default = {
            30,.7854,.15,2,
            .95,.75,.05,.1,
            .1,.1,.8,0,
            0,0,0,0,
        },
        min = {
            5,0,-1,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            80,3.14159,1,6,
            1,1,1,1,
            1,1,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Stripe_Freq   = u_UserData0[0][0];
float Stripe_Angle  = u_UserData0[0][1];
float Scroll_Speed  = u_UserData0[0][2];
float Pulse_Speed   = u_UserData0[0][3];
vec3  Color1        = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Color2        = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Opacity       = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 dir = vec2( cos( Stripe_Angle ), sin( Stripe_Angle ) );
    float proj = dot( UV, dir ) * Stripe_Freq + CoronaTotalTime * Scroll_Speed * Stripe_Freq;

    float stripe = step( 0.5, fract( proj ) );
    vec3 stripeColor = mix( Color1, Color2, stripe );

    float pulse = 0.75 + 0.25 * sin( CoronaTotalTime * Pulse_Speed );

    vec3 finalRGB = mix( tex.rgb, stripeColor * pulse, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
