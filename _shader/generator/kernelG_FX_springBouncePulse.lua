
--[[
    Original implementation for this bank. A platformer spring/bounce-
    pad feedback pulse: a glowing disc that squashes flat on contact
    then rebounds past its rest shape before settling, using a damped-
    cosine spring function of Bounce_Trigger (0 = at rest, plays once
    per trigger) to drive real squash/stretch geometry - the shape's
    aspect ratio itself deforms, it isn't just a brightness flash.

    Checked against all existing kernels first: nothing else in the
    bank deforms a shape's own geometry via a damped spring response;
    the closest neighbors are kernelF_deform_impact (warps an *existing
    sprite's* UVs from an impact point, not a standalone generated pad
    shape) and kernelG_FX_hitSparkBurst (this batch - a decaying line
    burst, not a squash/stretch deformation). Different mechanic from
    both.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "springBouncePulse"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Bounce_Trigger','Center_X','Center_Y','Pad_Radius',
            'Squash_Amount','Frequency','Decay','Color_R',
            'Color_G','Color_B','Glow','Aspect_Ratio',
            '','','','',
        },
        default = {
            0,.5,.6,.16,
            .5,10,4,.4,
            .85,1,.5,1,
            0,0,0,0,
        },
        min = {
            0,0,0,.05,
            0,2,.5,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            1,1,1,.4,
            1,25,10,1,
            1,1,1.5,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Bounce_Trigger = u_UserData0[0][0];
vec2  Center          = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Pad_Radius      = u_UserData0[0][3];
float Squash_Amount   = u_UserData0[1][0];
float Frequency       = u_UserData0[1][1];
float Decay           = u_UserData0[1][2];
vec3  Pad_Color       = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Glow            = u_UserData0[2][2];
float Aspect_Ratio    = u_UserData0[2][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float spring = cos( Bounce_Trigger * Frequency ) * exp( -Bounce_Trigger * Decay );
    float squashX = 1.0 + Squash_Amount * spring;
    float squashY = 1.0 - Squash_Amount * spring * 0.7;

    vec2 d = ( UV - Center ) * vec2( 1.0, Aspect_Ratio );
    d.x /= max( squashX, 0.05 );
    d.y /= max( squashY, 0.05 );
    float dist = length( d );

    float disc = smoothstep( Pad_Radius, Pad_Radius * 0.7, dist );
    float rim = smoothstep( 0.02, 0.0, abs( dist - Pad_Radius ) );
    float halo = exp( -( dist * dist ) / max( ( Pad_Radius * ( 1.0 + Glow ) ) * ( Pad_Radius * ( 1.0 + Glow ) ), 0.0001 ) ) * 0.4;

    float intensity = smoothstep( 0.0, 0.15, Bounce_Trigger ) * ( 1.0 - smoothstep( 0.7, 1.0, Bounce_Trigger ) );
    float alpha = clamp( ( disc * 0.6 + rim + halo ) * max( intensity, 0.15 ), 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( Pad_Color, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
