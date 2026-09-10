
--[[
    Original implementation for this bank. A holy/angelic halo (a thin
    glowing ring plus rotating radial light spokes) is a common "blessed"
    status-buff or divine-character VFX across RPGs; implemented here as
    two independent, additively combined pieces - a Gaussian-falloff ring
    at Ring_Radius and a sharpened `cos` spoke pattern for the rays,
    counter-fadeable so the rays can extend outward from the ring without
    also bleeding all the way into the center. A slight two-frequency
    sine flicker keeps the glow from reading as a static, pasted-on
    sticker.

    Pure generator, transparent background - center it above a character
    sprite. Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "radiantHalo"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Ring_Radius','Ring_Thickness','Ray_Count','Ray_Length',
            'Rotation_Speed','Color_R','Color_G','Color_B',
            'Core_White','Flicker_Amount','Flicker_Speed','Brightness',
            'Aspect_Ratio','','','',
        },
        default = {
            .28,.02,12,.35,
            .3,1,.92,.6,
            .7,.15,3,1.2,
            1,0,0,0,
        },
        min = {
            .05,.002,2,0,
            -3,0,0,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            .5,.1,32,.6,
            3,1,1,1,
            1,1,10,3,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Ring_Radius    = u_UserData0[0][0];
float Ring_Thickness = u_UserData0[0][1];
float Ray_Count      = u_UserData0[0][2];
float Ray_Length     = u_UserData0[0][3];
float Rotation_Speed = u_UserData0[1][0];
vec3  Color          = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Core_White     = u_UserData0[2][0];
float Flicker_Amount = u_UserData0[2][1];
float Flicker_Speed  = u_UserData0[2][2];
float Brightness     = u_UserData0[2][3];
float Aspect_Ratio   = u_UserData0[3][0];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float rad = length( uv );
    float ang = atan( uv.y, uv.x ) + CoronaTotalTime * Rotation_Speed;

    float ringDist = ( rad - Ring_Radius ) / max( Ring_Thickness, 0.002 );
    float ring = exp( -ringDist * ringDist );

    float rayPattern = pow( abs( cos( ang * Ray_Count * 0.5 ) ), 8.0 );
    float rayFalloff = smoothstep( Ring_Radius + Ray_Length, Ring_Radius, rad )
                      * smoothstep( Ring_Radius * 0.3, Ring_Radius * 0.8, rad );
    float rays = rayPattern * rayFalloff;

    float flicker = 1.0 + sin( CoronaTotalTime * Flicker_Speed ) * Flicker_Amount * 0.5
                        + sin( CoronaTotalTime * Flicker_Speed * 2.3 + 1.0 ) * Flicker_Amount * 0.5;

    vec3 hot = mix( Color, vec3( 1.0 ), Core_White );
    vec3 rgb = ( Color * rays * 0.8 + hot * ring * 1.3 ) * Brightness * flicker;
    float alpha = clamp( ( ring + rays * 0.6 ) * Brightness * flicker, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
