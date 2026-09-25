
--[[
    Original implementation for this bank. A procedural (no texture
    needed) lens-dirt overlay: a handful of soft hashed smudge blobs
    plus a handful of thin hashed scratch lines, both additively lit
    rather than flat-drawn so they only really show up where the
    underlying image is already bright - the same "grime catches the
    light" adaptive behavior AAA post-process stacks use for lens-dirt
    passes, rather than a constant-opacity decal.

    Checked against all existing kernels first: kernelF_FX_risoGrain/
    kernelF_FX_claymationJitter/kernelF_FX_ditherClassic all apply a
    flat, luminance-independent grain/dither pattern uniformly - none
    scale their visibility by the underlying image's own brightness,
    and none combine soft circular smudges with separate thin scratch
    lines. This is the only luminance-adaptive lens-grime kernel here.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "lensDustOverlay"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Dust_Amount','Smudge_Size','Scratch_Length','Color_R',
            'Color_G','Color_B','Seed','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            .5,.25,.35,1,
            1,.95,0,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,.08,.1,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1.5,.5,.7,1,
            1,1,50,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Dust_Amount    = u_UserData0[0][0];
float Smudge_Size    = u_UserData0[0][1];
float Scratch_Length = u_UserData0[0][2];
vec3  Dust_Color     = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
float Seed           = u_UserData0[1][2];
float Opacity        = u_UserData0[1][3];

//----------------------------------------------

P_RANDOM float dust_hash( float n )
{
    return fract( sin( n * 43.27 ) * 19781.31 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    float sceneLum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );

    float smudges = 0.0;
    for ( int i = 0; i < 5; i++ )
    {
        float fi = float( i );
        vec2 pos = vec2( dust_hash( fi + Seed ), dust_hash( fi + Seed + 7.3 ) );
        float size = mix( Smudge_Size * 0.6, Smudge_Size, dust_hash( fi + Seed + 13.1 ) );
        float d = length( UV - pos );
        smudges = max( smudges, exp( -( d * d ) / max( size * size, 0.0001 ) ) * 0.35 );
    }

    float scratches = 0.0;
    for ( int i = 0; i < 6; i++ )
    {
        float fi = float( i );
        float ang = dust_hash( fi + Seed + 50.0 ) * 3.14159265;
        vec2 dir = vec2( cos( ang ), sin( ang ) );
        vec2 side = vec2( -dir.y, dir.x );
        vec2 pos = vec2( dust_hash( fi + Seed + 90.0 ), dust_hash( fi + Seed + 91.0 ) );
        vec2 rel = UV - pos;
        float along = dot( rel, dir );
        float across = dot( rel, side );
        float len = mix( Scratch_Length * 0.5, Scratch_Length, dust_hash( fi + Seed + 120.0 ) );
        float line = smoothstep( 0.0018, 0.0, abs( across ) ) * step( abs( along ), len * 0.5 );
        scratches = max( scratches, line * 0.5 );
    }

    float adaptive = mix( 0.25, 1.0, sceneLum );
    float dustAlpha = clamp( ( smudges + scratches ) * Dust_Amount * adaptive, 0.0, 1.0 );

    vec3 finalRGB = clamp( tex.rgb + Dust_Color * dustAlpha, 0.0, 1.0 );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
