
--[[
    Original implementation for this bank. A standalone, self-
    contained loading spinner: a partial ring arc that rotates
    continuously via CoronaTotalTime with a soft fading tail, on a
    transparent background - an *indeterminate* "please wait"
    indicator with no progress value at all.

    Checked against all existing kernels first: kernelF_ui_cooldown is
    a *filter* that masks an existing sprite/icon with a determinate
    radial wedge driven by a live Progress value (0 = full cooldown, 1
    = ready) - it dims/reveals someone else's art to show a known
    remaining fraction. This is the opposite case: nothing to reveal, no
    known fraction, just a generated ring that spins to show activity
    is ongoing, same category of difference as a browser spinner vs. a
    download-percentage bar. kernelG_UI_radarSweep rotates a full
    beam across an entire disc with detection blips, a different
    read (scanning) and shape (full sweep, not a short arc with a
    tail) entirely.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "UI"
kernel.name = "loadingSpinnerRing"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Center_X','Center_Y','Radius','Thickness',
            'Arc_Length','Speed','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            .5,.5,.12,.016,
            .7,3,.4,.75,
            1,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.02,.004,
            .1,-8,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,1,.4,.05,
            .95,8,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Center        = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Radius        = u_UserData0[0][2];
float Thickness     = u_UserData0[0][3];
float Arc_Length    = u_UserData0[1][0];
float Speed         = u_UserData0[1][1];
vec3  Spin_Color    = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];

const float PI = 3.14159265;
const float TAU = 6.28318530718;

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 d = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( d );
    float ang = atan( d.y, d.x );

    float rotation = CoronaTotalTime * Speed;
    float rel = mod( ang - rotation + PI, TAU ) - PI;
    float relN = mod( rel + TAU, TAU ) / TAU;

    float ringMask = smoothstep( Thickness, 0.0, abs( dist - Radius ) );
    float arcMask = smoothstep( Arc_Length, Arc_Length - 0.08, relN ) * step( 0.0, relN );
    float tailFade = mix( 0.15, 1.0, smoothstep( Arc_Length, 0.0, relN ) );

    float alpha = clamp( ringMask * arcMask * tailFade, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( Spin_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
