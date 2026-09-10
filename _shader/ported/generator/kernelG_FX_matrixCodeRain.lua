
--[[
    Original implementation for this bank. Falling-glyph "digital rain"
    (The Matrix's signature look, and a recurring hacking-minigame/loading-
    screen effect in games since) is built the standard way: independent
    vertical columns, each scrolling at its own speed, with a bright lead
    character at the head of each column and a fading trail behind it -
    implemented here with a single hashed-cell lookup per pixel rather
    than simulating actual characters (each "glyph" is just a flickering
    hashed brightness block, matching this bank's other font-free
    stylization kernels like kernelF_pixel_asciiTerminal.lua rather than
    needing a font atlas).

    Pure generator, transparent background - overlay for a hacking/
    terminal/loading scene. Aspect_Ratio convention matches the rest of
    this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "matrixCodeRain"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Column_Count','Cell_Height','Fall_Speed','Trail_Length',
            'Flicker_Speed','Color_R','Color_G','Color_B',
            'Head_White','Brightness','Aspect_Ratio','',
            '','','','',
        },
        default = {
            30,18,1.4,.85,
            8,.15,1,.35,
            .8,1.1,1,0,
            0,0,0,0,
        },
        min = {
            5,4,0,.3,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            80,40,4,1,
            20,1,1,1,
            1,3,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Column_Count = u_UserData0[0][0];
float Cell_Height   = u_UserData0[0][1];
float Fall_Speed    = u_UserData0[0][2];
float Trail_Length  = u_UserData0[0][3];
float Flicker_Speed = u_UserData0[1][0];
vec3  Color         = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Head_White    = u_UserData0[2][0];
float Brightness    = u_UserData0[2][1];
float Aspect_Ratio  = u_UserData0[2][2];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float colId = floor( uv.x * Column_Count );
    float colSpeed = Fall_Speed * ( 0.5 + hash1( colId * 7.31 ) );
    float colPhase = hash1( colId * 3.19 + 1.0 ) * 40.0;

    float rowCoord = uv.y / max( Cell_Height * 0.01, 0.001 ) * 0.1 - CoronaTotalTime * colSpeed * 3.0 + colPhase;
    float rowId = floor( rowCoord );
    float rowFrac = fract( rowCoord );

    float headDist = fract( rowCoord + hash1( colId * 5.5 ) * 5.0 );
    float trail = clamp( 1.0 - rowFrac / max( Trail_Length, 0.05 ), 0.0, 1.0 );

    float glyphHash = hash1( rowId * 12.9 + colId * 78.2 );
    float flicker = 0.6 + 0.4 * sin( CoronaTotalTime * Flicker_Speed + glyphHash * 30.0 );
    float glyphVisible = step( 0.15, glyphHash ) * flicker;

    float isHead = 1.0 - smoothstep( 0.0, 0.12, rowFrac );

    vec3 rgb = mix( Color, vec3( 1.0 ), isHead * Head_White ) * trail * glyphVisible * Brightness;
    float alpha = clamp( trail * glyphVisible * Brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
