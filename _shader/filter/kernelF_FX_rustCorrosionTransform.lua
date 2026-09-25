
--[[
    Original implementation for this bank. Modeled on the "rust /
    corrosion" character-transform category from commercial 2D/3D
    character shader packs (e.g. the well-known "Character Shader
    Pack" bundles list rust as a standard toggle alongside dissolve,
    hologram, freeze, petrify and similar) - nothing was copied from
    any of them (all paid, closed-source). Progress 0 -> 1 spreads
    noise-seeded rust patches outward (a coarse mask threshold that
    grows with Progress), tinting toward orange-brown oxidation with
    darker pitting in a second, finer noise layer, so it reads as
    corrosion eating across the surface rather than a flat color wash.

    Checked against all existing kernels first: kernelF_FX_stone (batch
    3) desaturates toward gray with a top-light gradient for a
    petrification read - no color-shift-to-orange, no patch growth, no
    pitting; kernelF_FX_moltenCracks/crackOverlay grow branching
    Voronoi fissure *lines*, not broad patchy discoloration. No
    existing kernel does patch-based oxidation color shift.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "rustCorrosionTransform"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Scale','Rust_Dark_R','Rust_Dark_G',
            'Rust_Dark_B','Rust_Light_R','Rust_Light_G','Rust_Light_B',
            'Pit_Amount','Seed','Opacity','',
            '','','','',
        },
        default = {
            0,14,.25,.12,
            .04,.75,.4,.15,
            .35,0,1,0,
            0,0,0,0,
        },
        min = {
            0,4,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,30,1,1,
            1,1,1,1,
            .8,50,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress    = u_UserData0[0][0];
float Scale       = u_UserData0[0][1];
vec3  Rust_Dark   = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
vec3  Rust_Light  = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
float Pit_Amount  = u_UserData0[2][0];
float Seed        = u_UserData0[2][1];
float Opacity     = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float rust_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 27.1, 61.7 ) ) ) * 43758.5453123 );
}

P_RANDOM float rust_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( rust_hash( i ), rust_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( rust_hash( i + vec2( 0.0, 1.0 ) ), rust_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );

    float n = rust_noise( UV * Scale + Seed );
    float rustMask = smoothstep( 1.0 - Progress, 1.0 - Progress + 0.35, n );

    vec3 rustColor = mix( Rust_Dark, Rust_Light, clamp( n * 0.7 + lum * 0.3, 0.0, 1.0 ) );
    float pit = rust_noise( UV * Scale * 3.3 + Seed + 50.0 ) * Pit_Amount;
    rustColor = clamp( rustColor - pit * rustMask, 0.0, 1.0 );

    vec3 finalRGB = mix( tex.rgb, rustColor, rustMask * Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
