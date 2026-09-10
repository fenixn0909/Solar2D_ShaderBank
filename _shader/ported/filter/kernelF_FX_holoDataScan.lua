
--[[
    Original implementation for this bank. Distinct from this batch's
    kernelF_pixel_asciiTerminal.lua (which maps the *source image's own
    luminance* to glyph density) and kernelF_FX_wireframeReveal.lua (a
    static mesh grid) - this fakes a sci-fi data readout that has nothing
    to do with the underlying art: rows of blocky "characters" are pure
    hashed noise keyed to a `floor(time * Update_Speed)` step per row, so
    the whole readout periodically snaps to new "content" like a terminal
    refreshing, with different rows updating on their own offset cycle
    and carrying their own brightness (some rows read as headers, others
    as body text, purely from hashing).

    Single-texture filter - composites the readout over whatever
    CoronaSampler0 already shows, masked by its own alpha.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "holoDataScan"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Row_Density','Char_Density','Update_Speed','Opacity',
            'Glow_Amount','Color_R','Color_G','Color_B',
            '','','','',
            '','','','',
        },
        default = {
            40,25,2,.85,
            .3,.2,.95,.9,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            5,5,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            100,80,10,1,
            1,1,1,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Row_Density  = u_UserData0[0][0];
float Char_Density = u_UserData0[0][1];
float Update_Speed = u_UserData0[0][2];
float Opacity      = u_UserData0[0][3];
float Glow_Amount  = u_UserData0[1][0];
vec3  Color        = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float row = floor( UV.y * Row_Density );
    float rowHash = hash1( row * 17.3 );
    float updateCycle = floor( CoronaTotalTime * Update_Speed + rowHash * 5.0 );

    float charX = fract( UV.x * Char_Density );
    float charIndex = floor( UV.x * Char_Density );
    float charHash = hash1( charIndex * 7.1 + row * 31.7 + updateCycle * 3.3 );
    float charFilled = step( 0.35, charHash );

    float blockShape = step( 0.15, charX ) * step( charX, 0.75 );
    float rowBrightness = 0.5 + 0.5 * hash1( row * 5.5 + updateCycle * 1.1 );
    float scanline = 0.85 + 0.15 * sin( UV.y * 300.0 );

    float total = charFilled * blockShape * rowBrightness * scanline;

    vec3 rgb = mix( src.rgb, Color, total * Opacity ) + Color * total * Glow_Amount;
    float alpha = max( src.a, total * src.a );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
