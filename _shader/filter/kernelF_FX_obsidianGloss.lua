
--[[
    Original implementation for this bank. A "polished volcanic glass"
    material look built from three cheap, independent layers over the
    darkened source art: a moving specular band (`dot(uv, angleDir)`
    compared against a sliding position - Highlight_Speed at 0 keeps it
    perfectly static via `sin(0) = 0`, so the same uniform covers both a
    fixed raking-light look and a slow sweeping one), an edge brightening
    term approximating a Fresnel response by comparing each pixel's alpha
    against its four neighbours a couple of texels out (cheap stand-in for
    a real normal-based Fresnel term, same alpha-comparison idea as this
    batch's other edge-aware kernels), and a fixed (non-animated, so it
    doesn't read as flickering noise) hashed sparkle grain for the fine
    flecked look real obsidian has.

    Single-texture filter - a material treatment for any sprite (rock
    props, armor, potion glass, a "wet floor" tile).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "obsidianGloss"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Darken','Highlight_Angle','Highlight_Pos','Highlight_Speed',
            'Highlight_Width','Highlight_Brightness','Edge_Boost','Color_Tint_R',
            'Color_Tint_G','Color_Tint_B','Grain_Density','Grain_Amount',
            '','','','',
        },
        default = {
            .75,.9,0,.4,
            .12,.9,1.5,.55,
            .35,.85,180,.4,
            0,0,0,0,
        },
        min = {
            0,0,-1,-3,
            .02,0,0,0,
            0,0,20,0,
            0,0,0,0,
        },
        max = {
            1,6.28318,1,3,
            .5,2,3,1,
            1,1,400,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Darken               = u_UserData0[0][0];
float Highlight_Angle      = u_UserData0[0][1];
float Highlight_Pos        = u_UserData0[0][2];
float Highlight_Speed      = u_UserData0[0][3];
float Highlight_Width      = u_UserData0[1][0];
float Highlight_Brightness = u_UserData0[1][1];
float Edge_Boost           = u_UserData0[1][2];
vec3  Color_Tint           = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Grain_Density        = u_UserData0[2][2];
float Grain_Amount         = u_UserData0[2][3];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );
    vec3 darkened = src.rgb * Darken;

    vec2 dir = vec2( cos( Highlight_Angle ), sin( Highlight_Angle ) );
    float proj = dot( UV - vec2( 0.5 ), dir );
    float movingPos = Highlight_Pos + sin( CoronaTotalTime * Highlight_Speed ) * 0.6;
    float band = 1.0 - smoothstep( 0.0, Highlight_Width, abs( proj - movingPos ) );

    vec2 offs = CoronaTexelSize.xy * 2.0;
    float aXp = texture2D( CoronaSampler0, UV + vec2( offs.x, 0.0 ) ).a;
    float aXn = texture2D( CoronaSampler0, UV - vec2( offs.x, 0.0 ) ).a;
    float aYp = texture2D( CoronaSampler0, UV + vec2( 0.0, offs.y ) ).a;
    float aYn = texture2D( CoronaSampler0, UV - vec2( 0.0, offs.y ) ).a;
    float minNeighbor = min( min( aXp, aXn ), min( aYp, aYn ) );
    float edge = clamp( ( src.a - minNeighbor ) * Edge_Boost, 0.0, 1.0 );

    float grainHash = hash1( dot( floor( UV * Grain_Density ), vec2( 12.9898, 78.233 ) ) );
    float sparkle = step( 1.0 - Grain_Amount * 0.08, grainHash ) * grainHash;

    vec3 rgb = darkened
             + vec3( 1.0 ) * band * Highlight_Brightness * src.a
             + Color_Tint * edge * 0.5 * src.a
             + vec3( 1.0 ) * sparkle * 0.5 * src.a;

    P_COLOR vec4 COLOR = vec4( rgb, src.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
