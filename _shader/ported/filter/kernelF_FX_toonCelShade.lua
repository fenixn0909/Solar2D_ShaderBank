
--[[
    Original implementation for this bank. Rather than a normal-mapped
    lighting model (this batch's kernelC_Lit_normalMap2D.lua already
    covers that), this is the "apply a toon look to art that's already
    shaded" version: posterize the existing luminance response into a
    fixed number of hard bands while dividing back out to preserve each
    pixel's original hue, boost saturation to counteract the flatness
    posterizing tends to cause, then add a black ink outline using the
    same alpha-gradient edge trick as this batch's other outline-adjacent
    kernels (compare CoronaSampler0's alpha against 4 neighbours a
    tunable number of texels away). The combination - hard light bands
    plus a clean outline - is the two-part recipe behind most "cel
    shaded"/anime-style Unity toon shaders.

    Single-texture filter, works directly on already-colored/shaded
    sprite art (no normal map or extra input needed).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "toonCelShade"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Bands','Posterize_Amount','Outline_Width','Outline_Color_R',
            'Outline_Color_G','Outline_Color_B','Saturation_Boost','',
            '','','','',
            '','','','',
        },
        default = {
            4,.85,1.4,.05,
            .05,.08,1.25,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            2,0,0,0,
            0,0,.5,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            8,1,4,1,
            1,1,2.5,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Bands             = u_UserData0[0][0];
float Posterize_Amount  = u_UserData0[0][1];
float Outline_Width     = u_UserData0[0][2];
vec3  Outline_Color     = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Saturation_Boost  = u_UserData0[1][2];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    float luminance = dot( src.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float banded = clamp( floor( luminance * Bands ) / max( Bands - 1.0, 1.0 ), 0.0, 1.0 );
    vec3 toonColor = mix( src.rgb, src.rgb * banded / max( luminance, 0.001 ), Posterize_Amount );

    float satLuma = dot( toonColor, vec3( 0.299, 0.587, 0.114 ) );
    vec3 satColor = mix( vec3( satLuma ), toonColor, Saturation_Boost );

    vec2 offs = CoronaTexelSize.xy * Outline_Width;
    float aC = src.a;
    float aXp = texture2D( CoronaSampler0, UV + vec2( offs.x, 0.0 ) ).a;
    float aXn = texture2D( CoronaSampler0, UV - vec2( offs.x, 0.0 ) ).a;
    float aYp = texture2D( CoronaSampler0, UV + vec2( 0.0, offs.y ) ).a;
    float aYn = texture2D( CoronaSampler0, UV - vec2( 0.0, offs.y ) ).a;
    float maxNeighbor = max( max( aXp, aXn ), max( aYp, aYn ) );
    float outline = clamp( maxNeighbor - aC, 0.0, 1.0 ) * step( 0.5, maxNeighbor );

    vec3 rgb = mix( satColor, Outline_Color, outline );
    float alpha = clamp( src.a + outline, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
