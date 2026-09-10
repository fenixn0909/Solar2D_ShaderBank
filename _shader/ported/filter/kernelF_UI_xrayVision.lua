
--[[
    Original implementation for this bank. The "see allies/enemies through
    walls" detective-vision trope (Arkham's Detective Mode, Metal Gear's
    soliton radar silhouettes) is generally built from two layers over a
    rendered-on-top silhouette: a bright rim outline and a scan-line hatch
    fill so the interior doesn't read as a flat cutout. Rim uses the same
    alpha-vs-neighbours edge trick as this batch's other outline-adjacent
    kernels; the hatch is a single scrolling `fract(uv.y * density)` band
    test, cheaper than an actual line-texture overlay. A slow sine pulse
    keeps the whole silhouette from looking static/pasted-on.

    Meant to be applied to a duplicate of the occluded sprite rendered
    above the wall/occluder (this shader only handles the look, not the
    render-order/occlusion logic - that's a scene-graph decision on the
    Lua side). Single-texture filter. Aspect_Ratio convention matches the
    rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "xrayVision"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Edge_Width','Edge_Brightness','Hatch_Density','Hatch_Brightness',
            'Scan_Speed','Pulse_Speed','Pulse_Amount','Color_R',
            'Color_G','Color_B','Aspect_Ratio','',
            '','','','',
        },
        default = {
            1.5,1.6,40,.35,
            .6,2,.15,1,
            .55,.15,1,0,
            0,0,0,0,
        },
        min = {
            0,0,5,0,
            -3,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            4,3,100,1,
            3,8,1,1,
            1,1,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Edge_Width      = u_UserData0[0][0];
float Edge_Brightness = u_UserData0[0][1];
float Hatch_Density   = u_UserData0[0][2];
float Hatch_Brightness= u_UserData0[0][3];
float Scan_Speed      = u_UserData0[1][0];
float Pulse_Speed     = u_UserData0[1][1];
float Pulse_Amount    = u_UserData0[1][2];
vec3  Color           = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Aspect_Ratio    = u_UserData0[2][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );
    float mask = src.a;

    vec2 offs = CoronaTexelSize.xy * Edge_Width;
    float aXp = texture2D( CoronaSampler0, UV + vec2( offs.x, 0.0 ) ).a;
    float aXn = texture2D( CoronaSampler0, UV - vec2( offs.x, 0.0 ) ).a;
    float aYp = texture2D( CoronaSampler0, UV + vec2( 0.0, offs.y ) ).a;
    float aYn = texture2D( CoronaSampler0, UV - vec2( 0.0, offs.y ) ).a;
    float maxNeighbor = max( max( aXp, aXn ), max( aYp, aYn ) );
    float edge = clamp( maxNeighbor - mask, 0.0, 1.0 ) + clamp( mask - min( min( aXp, aXn ), min( aYp, aYn ) ), 0.0, 1.0 ) * mask;

    float hatch = step( 0.5, fract( UV.y * Hatch_Density + CoronaTotalTime * Scan_Speed ) ) * mask;

    float pulse = 1.0 + sin( CoronaTotalTime * Pulse_Speed ) * Pulse_Amount;

    vec3 rgb = Color * ( edge * Edge_Brightness + hatch * Hatch_Brightness ) * pulse;
    float alpha = clamp( ( edge * Edge_Brightness * 0.9 + hatch * Hatch_Brightness * 0.7 ) * pulse, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
