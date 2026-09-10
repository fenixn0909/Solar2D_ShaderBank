
--[[
    Original implementation for this bank. Icicles are drawn the same way
    this bank already builds other "distance to a repeating tapered
    shape" effects: each column (`floor(uv.x * Density)`) gets its own
    hashed length and sway phase, and a pixel belongs to that column's
    icicle when it's within a width that narrows linearly toward the tip
    - a simple triangle taper rather than a texture. A droplet at the very
    tip uses the same falling single-hashed-cell idea as this batch's
    kernelG_FX_sakuraPetals.lua, gated to only spawn right at each
    icicle's own tip position and only when Drip_Amount > 0.

    Single-texture filter - the icicles composite OVER whatever
    CoronaSampler0 already shows (an eaves/cave-ceiling sprite works well)
    rather than replacing it, so Base_Alpha_Only lets you preview just the
    icicle layer if needed by feeding a transparent source.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "icicleDrip"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Density','Max_Length','Width','Sway_Amount',
            'Drip_Amount','Drip_Speed','Color_R','Color_G',
            'Color_B','Highlight_Amount','Aspect_Ratio','',
            '','','','',
        },
        default = {
            14,.35,.018,.006,
            .6,.6,.75,.9,
            1,.5,1,0,
            0,0,0,0,
        },
        min = {
            3,.05,.004,0,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            40,.7,.05,.02,
            1,3,1,1,
            1,1,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Density           = u_UserData0[0][0];
float Max_Length        = u_UserData0[0][1];
float Width             = u_UserData0[0][2];
float Sway_Amount       = u_UserData0[0][3];
float Drip_Amount       = u_UserData0[1][0];
float Drip_Speed        = u_UserData0[1][1];
vec3  Color             = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Highlight_Amount  = u_UserData0[2][1];
float Aspect_Ratio      = u_UserData0[2][2];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float col = floor( UV.x * Density );
    float colCenter = ( col + 0.5 ) / Density;
    float hA = hash1( col * 7.31 );
    float hB = hash1( col * 3.17 + 1.0 );

    float icicleLen = Max_Length * ( 0.4 + 0.6 * hA );
    float sway = sin( UV.y * 8.0 + hB * 6.28318 ) * Sway_Amount;

    float distFromCenter = abs( UV.x - colCenter - sway );
    float heightFrac = clamp( UV.y / max( icicleLen, 0.001 ), 0.0, 1.0 );
    float widthAtHeight = Width * ( 1.0 - heightFrac ) * ( 0.5 + 0.5 * hB );

    float inIcicle = step( distFromCenter, widthAtHeight ) * step( UV.y, icicleLen );

    float tipDist = abs( UV.y - icicleLen );
    float highlight = ( 1.0 - smoothstep( 0.0, widthAtHeight * 1.5 + 0.01, distFromCenter ) ) * smoothstep( 0.3, 1.0, heightFrac ) * Highlight_Amount;

    float dropCycle = 1.2 + hA * 1.5;
    float dropT = mod( CoronaTotalTime * Drip_Speed + hB * 10.0, dropCycle ) / dropCycle;
    vec2 dropPos = vec2( colCenter + sway, icicleLen + dropT * 0.25 );
    float dropDist = length( vec2( ( UV.x - dropPos.x ) * 3.0, UV.y - dropPos.y ) );
    float drop = ( 1.0 - smoothstep( 0.006, 0.012, dropDist ) ) * step( dropT, 0.85 ) * Drip_Amount;

    vec3 icicleRGB = Color + vec3( 1.0 ) * highlight;
    float icicleMask = clamp( inIcicle + drop, 0.0, 1.0 );

    vec3 rgb = mix( src.rgb, icicleRGB, icicleMask );
    float alpha = clamp( src.a + icicleMask, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
