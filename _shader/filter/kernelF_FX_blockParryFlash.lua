
--[[
    Original implementation for this bank. A combat block/parry hit-
    stop flash: a bright cross-flash plus a single hard-edged expanding
    ring at Point, both keyed to Progress (0 = the instant of contact,
    fades out by ~0.4) - meant for a very short tween (a few frames),
    distinct in shape and purpose from this batch's kernelG_FX_
    hitSparkBurst (eight radiating spark lines, a "hit landed" read)
    since a parry/block needs the sharper, more geometric "clean stop"
    read of a cross-flash and ring rather than scattered sparks.

    Checked against all existing kernels first: kernelF_FX_shockwave
    distorts the image via a radial UV push (bends what's already
    there) rather than compositing a flash+ring on top; nothing else
    in the bank draws a cross-flash. Different from hitSparkBurst as
    noted above despite both being combat one-shots in this batch.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "blockParryFlash"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Point_X','Point_Y','Flash_Size',
            'Ring_Speed','Ring_Width','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            0,.5,.5,.1,
            1.4,.015,1,1,
            .85,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,.02,
            .3,.004,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,.3,
            4,.05,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress      = u_UserData0[0][0];
vec2  Point         = vec2( u_UserData0[0][1], u_UserData0[0][2] );
float Flash_Size    = u_UserData0[0][3];
float Ring_Speed    = u_UserData0[1][0];
float Ring_Width    = u_UserData0[1][1];
vec3  Flash_Color   = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio  = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 d = ( UV - Point ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( d );

    float fade = 1.0 - smoothstep( 0.0, 0.4, Progress );

    float flashCore = exp( -( dist * dist ) / max( Flash_Size * Flash_Size, 0.0001 ) );
    float cross = exp( -( d.y * d.y ) / max( Flash_Size * Flash_Size * 0.02, 0.0001 ) ) +
                  exp( -( d.x * d.x ) / max( Flash_Size * Flash_Size * 0.02, 0.0001 ) );
    cross = clamp( cross, 0.0, 1.0 ) * smoothstep( Flash_Size * 3.0, 0.0, dist );

    float ringR = Flash_Size * 0.6 + Progress * Ring_Speed * Flash_Size * 4.0;
    float ring = smoothstep( Ring_Width, 0.0, abs( dist - ringR ) );

    float overlay = clamp( ( flashCore + cross * 0.7 + ring ) * fade, 0.0, 1.0 );

    vec3 finalRGB = tex.rgb + Flash_Color * overlay;
    P_COLOR vec4 COLOR = vec4( finalRGB, max( tex.a, overlay ) );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
