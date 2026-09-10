
--[[
    Original implementation for this bank. Domain-warped fractal Brownian
    motion (warp a noise field's sample coordinate by a second noise
    field, then a third) is the standard technique behind most "painterly
    smoke/fire/marble" shaders - popularised for real-time use by Inigo
    Quilez's "domain warping" article and reused everywhere since - so
    this is a from-scratch implementation of that generic technique with
    its own value-noise/FBM functions, not a copy of any specific existing
    shader.

    Tuned specifically for a contained, object-attached "curse/dark magic"
    look rather than a weather system: the whole field is masked down to a
    soft Radius so it reads as tendrils curling around a cursed item or
    character rather than a screen-filling sky (this bank's existing
    kernelC_FG_topdownCloud2D.lua / kernelG_BG_radialClouds.lua /
    kernelF_BG_discreteClouds.lua are all backdrop weather; this is a
    tighter, warmer-toned VFX prop instead), and the palette runs from a
    near-black base to a saturated magic-glow core rather than white/grey.

    Pure generator, transparent background. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "arcaneSmoke"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Scale','Speed','Warp','Radius',
            'Brightness','Color_Dark_R','Color_Dark_G','Color_Dark_B',
            'Color_Bright_R','Color_Bright_G','Color_Bright_B','Aspect_Ratio',
            '','','','',
        },
        default = {
            2.2,.25,1.1,.42,
            1.1,.12,.02,.18,
            .65,.15,.85,1,
            0,0,0,0,
        },
        min = {
            .5,-2,0,.05,
            0,0,0,0,
            0,0,0,.2,
            0,0,0,0,
        },
        max = {
            6,2,3,.6,
            3,1,1,1,
            1,1,1,5,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Scale        = u_UserData0[0][0];
float Speed        = u_UserData0[0][1];
float Warp         = u_UserData0[0][2];
float Radius       = u_UserData0[0][3];
float Brightness   = u_UserData0[1][0];
vec3  Color_Dark   = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
vec3  Color_Bright = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Aspect_Ratio = u_UserData0[2][3];

const int FBM_OCTAVES = 4;

P_RANDOM float hash21( vec2 p )
{
    p = fract( p * vec2( 123.34, 456.21 ) );
    p += dot( p, p + 45.32 );
    return fract( p.x * p.y );
}

float valueNoise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    float a = hash21( i );
    float b = hash21( i + vec2( 1.0, 0.0 ) );
    float c = hash21( i + vec2( 0.0, 1.0 ) );
    float d = hash21( i + vec2( 1.0, 1.0 ) );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( a, b, u.x ), mix( c, d, u.x ), u.y );
}

float fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for ( int octave = 0; octave < FBM_OCTAVES; octave++ ) {
        total += valueNoise( p * freq ) * amp;
        freq *= 2.0;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float t = CoronaTotalTime * Speed;

    vec2 q = vec2(
        fbm( uv * Scale + t * vec2( 0.1, 0.3 ) ),
        fbm( uv * Scale + vec2( 5.2, 1.3 ) + t * vec2( -0.15, 0.2 ) )
    );
    vec2 r = vec2(
        fbm( uv * Scale + Warp * q + vec2( 1.7, 9.2 ) + t * 0.2 ),
        fbm( uv * Scale + Warp * q + vec2( 8.3, 2.8 ) - t * 0.25 )
    );
    float f = fbm( uv * Scale + Warp * r );

    float rad = length( uv );
    float containMask = smoothstep( Radius, Radius * 0.4, rad );

    float density = clamp( f, 0.0, 1.0 ) * containMask;
    float core = smoothstep( 0.6, 0.9, f ) * containMask;

    vec3 smokeColor = mix( Color_Dark, Color_Bright, core );
    vec3 rgb = smokeColor * density * Brightness;
    float alpha = clamp( density * Brightness, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
