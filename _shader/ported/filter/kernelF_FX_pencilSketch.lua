
--[[
    Original implementation for this bank. Converts the input sprite
    into hand-drawn pencil/charcoal cross-hatch line art: three
    progressively finer hatch layers (each at its own angle) reveal
    themselves in order as local tone gets darker, so light areas stay
    bare paper, mid-tones get a single hatch direction, and shadows get
    full cross-hatching - the same layering real sketch artists use,
    rather than a flat threshold. A 4-tap luminance-edge pass darkens
    silhouette/detail edges like an ink outline, and a static paper
    grain (UV-seeded, no time input) keeps it looking like a still
    drawing rather than shimmering noise.

    Checked against all existing kernels first: kernelF_FX_squigglePen
    is a geometric UV-warp post-process (wobbles the image's edges, no
    tone-to-hatch mapping); kernelF_FX_watercolorBleed bleeds paint at
    edges rather than drawing line strokes; kernelF_FX_halftoneComic
    uses dot screens, not directional line hatching; kernelF_FX_
    claymationJitter is a stop-motion frame-hold/grain effect with no
    stylization of the art itself; kernelF_FX_toonCelShade posterizes
    existing shading into flat bands rather than linework. None of them
    do tone-driven hatch-line density.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "pencilSketch"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Line_Density','Line_Angle','Edge_Strength','Grain_Amount',
            'Paper_R','Paper_G','Paper_B','Ink_R',
            'Ink_G','Ink_B','Opacity','',
            '','','','',
        },
        default = {
            140,.6,2.5,.05,
            .96,.94,.88,.08,
            .07,.1,1,0,
            0,0,0,0,
        },
        min = {
            20,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            400,3.14159,8,.2,
            1,1,1,.3,
            .3,.3,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Line_Density  = u_UserData0[0][0];
float Line_Angle    = u_UserData0[0][1];
float Edge_Strength = u_UserData0[0][2];
float Grain_Amount  = u_UserData0[0][3];
vec3  Paper_Color   = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Ink_Color     = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Opacity       = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float sketch_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 41.3, 289.1 ) ) ) * 24634.6345 );
}

float sketch_lum( vec4 c )
{
    return dot( c.rgb, vec3( 0.299, 0.587, 0.114 ) );
}

float sketch_lines( vec2 uv, float angle, float freq )
{
    vec2 dir = vec2( cos( angle ), sin( angle ) );
    float p = dot( uv, dir ) * freq;
    float v = abs( sin( p * 3.14159265 ) );
    return smoothstep( 0.0, 0.16, v );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    float lum = sketch_lum( tex );
    float tone = 1.0 - lum;

    float hatchA = sketch_lines( UV, Line_Angle, Line_Density );
    float hatchB = sketch_lines( UV, Line_Angle + 1.5708, Line_Density );
    float hatchC = sketch_lines( UV, Line_Angle + 0.7854, Line_Density * 0.6 );

    float ink = 1.0;
    ink *= mix( 1.0, hatchA, smoothstep( 0.12, 0.5, tone ) );
    ink *= mix( 1.0, hatchB, smoothstep( 0.42, 0.8, tone ) );
    ink *= mix( 1.0, hatchC, smoothstep( 0.75, 1.0, tone ) );

    vec2 texel = CoronaTexelSize.xy * 1.5;
    float lL = sketch_lum( texture2D( CoronaSampler0, UV - vec2( texel.x, 0.0 ) ) );
    float lR = sketch_lum( texture2D( CoronaSampler0, UV + vec2( texel.x, 0.0 ) ) );
    float lD = sketch_lum( texture2D( CoronaSampler0, UV - vec2( 0.0, texel.y ) ) );
    float lU = sketch_lum( texture2D( CoronaSampler0, UV + vec2( 0.0, texel.y ) ) );
    float edge = clamp( ( abs( lum - lL ) + abs( lum - lR ) + abs( lum - lD ) + abs( lum - lU ) ) * Edge_Strength, 0.0, 1.0 );

    float grain = 1.0 - Grain_Amount * sketch_hash( floor( UV * 700.0 ) );

    vec3 sketchRGB = mix( Ink_Color, Paper_Color, ink ) * grain;
    sketchRGB = mix( sketchRGB, Ink_Color, edge );

    vec3 finalRGB = mix( tex.rgb, sketchRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
