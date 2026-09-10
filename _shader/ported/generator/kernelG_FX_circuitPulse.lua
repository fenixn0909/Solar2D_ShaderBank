
--[[
    Original implementation for this bank. A rectilinear "circuit board"
    look (glowing grid segments with light pulses travelling along them)
    is a recognisable sci-fi/Tron trope with no single canonical shader
    behind it, so this builds it from a grid-cell decomposition: each grid
    cell hashes to whether it carries a horizontal segment, a vertical
    segment, both, or a node dot, then a travelling brightness pulse is
    driven by each cell's own position along a diagonal flow coordinate so
    pulses ripple across the whole board rather than blinking in place.

    Pure generator, transparent background - good as a sci-fi floor/wall
    panel overlay, a UI backdrop, or a "power restored" transition fill.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "circuitPulse"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Density','Line_Width','Base_Glow','Pulse_Intensity',
            'Pulse_Speed','Pulse_Sharpness','Color_R','Color_G',
            'Color_B','Aspect_Ratio','','',
            '','','','',
        },
        default = {
            14,.06,.25,1.1,
            2.5,6,.25,.9,
            1,1,0,0,
            0,0,0,0,
        },
        min = {
            2,.01,0,0,
            -6,1,0,0,
            0,.2,0,0,
            0,0,0,0,
        },
        max = {
            40,.3,1,3,
            6,16,1,1,
            1,5,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Density         = u_UserData0[0][0];
float Line_Width      = u_UserData0[0][1];
float Base_Glow       = u_UserData0[0][2];
float Pulse_Intensity = u_UserData0[0][3];
float Pulse_Speed     = u_UserData0[1][0];
float Pulse_Sharpness = u_UserData0[1][1];
vec3  Color           = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Aspect_Ratio    = u_UserData0[2][1];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    vec2 guv = uv * Density;
    vec2 cell = floor( guv );
    vec2 cuv = fract( guv ) - 0.5;

    float h = hash1( dot( cell, vec2( 127.1, 311.7 ) ) );
    float hasH = step( 0.5, fract( h * 13.0 ) );
    float hasV = step( 0.5, fract( h * 7.0 + 0.37 ) );

    float distH = abs( cuv.y );
    float distV = abs( cuv.x );
    float lineH = ( 1.0 - smoothstep( Line_Width, Line_Width + 0.02, distH ) ) * hasH;
    float lineV = ( 1.0 - smoothstep( Line_Width, Line_Width + 0.02, distV ) ) * hasV;
    float node = ( 1.0 - smoothstep( Line_Width * 1.8, Line_Width * 1.8 + 0.02, length( cuv ) ) ) * step( 0.7, fract( h * 19.0 ) );

    float lineMask = max( max( lineH, lineV ), node );

    float flowCoord = cell.x * 1.3 + cell.y * 1.7;
    float phase = hash1( flowCoord * 3.1 + 11.0 );
    float pulse = pow( 0.5 + 0.5 * sin( flowCoord * 0.6 - CoronaTotalTime * Pulse_Speed + phase * 6.2832 ), Pulse_Sharpness );

    float brightness = Base_Glow + pulse * Pulse_Intensity;

    vec3 rgb = Color * lineMask * brightness;
    float alpha = clamp( lineMask * brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
