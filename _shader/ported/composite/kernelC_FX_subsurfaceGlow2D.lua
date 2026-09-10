
--[[
    Original implementation for this bank. True subsurface scattering
    needs real depth/thickness information that a flat 2D sprite doesn't
    have, so - like most practical 2D/mobile "fake SSS" approaches - this
    trades the physically-based version for a cheap, art-directable one:
    CoronaSampler1 is a grayscale thickness map you paint by hand (white
    = thin, translucent areas like ear/leaf/finger edges or a candle
    wall; black = thick, opaque interior), and Backlight_Amount is a
    single 0-1 scalar you drive from your own lighting logic (how much
    the current light is behind the subject) rather than full per-pixel
    light-vector math - simple enough to hand-tune per sprite without a
    lighting rig, at the cost of not reacting automatically to a moving
    light the way a true normal-mapped shader would (see this batch's own
    kernelC_Lit_normalMap2D.lua for that instead, if you need it).

    CoronaSampler0 = albedo. CoronaSampler1 = thickness map (only the red
    channel is read, so a plain grayscale image is fine). Aspect_Ratio is
    unused here (no directional falloff to correct) but kept for
    consistency with the rest of this bank.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "subsurfaceGlow2D"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Backlight_Amount','Intensity','Power','Scatter_R',
            'Scatter_G','Scatter_B','Base_Brightness','Aspect_Ratio',
            '','','','',
            '','','','',
        },
        default = {
            .6,1.4,2,1,
            .35,.2,1,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.5,0,
            0,0,0,.2,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,4,6,1,
            1,1,1.5,5,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Backlight_Amount = u_UserData0[0][0];
float Intensity        = u_UserData0[0][1];
float Power            = u_UserData0[0][2];
vec3  Scatter_Color    = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Base_Brightness  = u_UserData0[1][2];
float Aspect_Ratio     = u_UserData0[1][3];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 albedo = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 thicknessSample = texture2D( CoronaSampler1, UV );

    float thickness = thicknessSample.r;
    vec3 scatter = Scatter_Color * pow( thickness, Power ) * Backlight_Amount * Intensity;

    vec3 rgb = albedo.rgb * Base_Brightness + scatter * albedo.a;

    P_COLOR vec4 COLOR = vec4( rgb, albedo.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
