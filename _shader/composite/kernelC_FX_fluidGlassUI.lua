
--[[
    https://godotshaders.com/shader/fluid-glass-ui/
    binbun
    February 15, 2026 (updated March 9, 2026)

    paint1 = the shape (a rounded rect or similar - its alpha edge
    profile drives the warp/rim/curve-light math, matching the
    original's use of COLOR.a before any texture is sampled - Godot
    pre-fills COLOR with the node's own render, this bank has no such
    implicit fill so it's sampled explicitly here instead). paint2 =
    screen capture to refract (feed it a snapshot/render-texture, same
    convention as this bank's other screen-space shaders).

    Two drops: textureLod()'s mip-based blur_amount needs a GLES2
    extension with no working precedent in this bank, so it's a direct
    sample instead. And the original's shadow_color check exists to
    skip processing a shadow baked into the same StyleBoxFlat texture
    as the panel fill - Solar2D has no StyleBox system, so there's
    nothing to exclude; dropped entirely.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "composite"
kernel.group = "FX"
kernel.name = "fluidGlassUI"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Brightness','Chromatic_Shift_Amount','Bend_Amount','Grain_Amount',
            'Curve_Light_Blend','Rim_Light_Blend','','',
            '','','','',
            '','','','',
        },
        default = { .1,.2,.4,.05,  .5,.8,0,0,  0,0,0,0,  0,0,0,0, },
        min =     { 0,0,0,0,       0,0,0,0,    0,0,0,0,  0,0,0,0, },
        max =     { .5,1,1,1,      1,1,1,1,    1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[

#define PI 3.14159265359

uniform P_COLOR mat4 u_UserData0;

float Brightness              = u_UserData0[0][0];
float Chromatic_Shift_Amount  = u_UserData0[0][1];
float Bend_Amount              = u_UserData0[0][2];
float Grain_Amount             = u_UserData0[0][3];
float Curve_Light_Blend        = u_UserData0[1][0];
float Rim_Light_Blend          = u_UserData0[1][1];

//----------------------------------------------

float noiseFn( vec2 uv )
{
    return fract( sin( dot( uv, vec2( 9.82131, 58.234 ) ) ) * 45312.1324 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );
    float shape_alpha = COLOR.a;

    vec2 warp_dir = UV;
    warp_dir.x = 1.0 - mix( mix( 0.5, 1.0, pow( warp_dir.x, 8.0 ) ), 0.0, pow( 1.0 - warp_dir.x, 8.0 ) );
    warp_dir.y = mix( mix( 0.5, 1.0, pow( warp_dir.y, 8.0 ) ), 0.0, pow( 1.0 - warp_dir.y, 8.0 ) );
    warp_dir = warp_dir * 2.0 - 1.0;

    vec2 warp = warp_dir * pow( COLOR.a - 0.1, 2.0 ) * Bend_Amount;
    vec2 warped_uv = UV / ( 1.0 - warp );

    vec2 chromatic_shift = warp * Chromatic_Shift_Amount;

    vec4 screen = vec4(
        texture2D( CoronaSampler1, warped_uv + chromatic_shift ).rg,
        texture2D( CoronaSampler1, warped_uv ).ba
    );

    float edge_mask = COLOR.a;
    float curve_mask = clamp( ( edge_mask - 0.5 ) / ( 1.0 - 0.5 ), 0.0, 1.0 );
    float curve_light = sin( curve_mask * PI ) * edge_mask;
    curve_light *= 1.0 - pow( length( UV ), 2.0 );
    curve_light = clamp( curve_light, 0.0, 1.0 );
    curve_light *= Curve_Light_Blend;

    float rim_mask = abs( ( UV.y + UV.x ) - 1.0 );
    float rim = clamp( ( edge_mask - 0.9 ) / ( 1.0 - 0.9 ), 0.0, 1.0 );
    rim *= Rim_Light_Blend;
    rim *= rim_mask;

    float grain = clamp( noiseFn( UV ), 0.0, 1.0 );
    grain = grain * 2.0 - 1.0;
    grain = ( grain * Grain_Amount ) + 1.0;

    screen *= grain;

    // rim/curve_light/Brightness apply to RGB only - the shape's own alpha
    // (captured above, before any of this math) is what clips the effect
    // to the sprite instead of the whole rect, so it's restored explicitly
    // rather than left to whatever the RGB math happens to leave in .a
    vec3 rgb = ( screen * vec4( COLOR.rgb, 1.0 ) ).rgb + rim + curve_light + Brightness;
    COLOR = vec4( rgb, shape_alpha );

    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

