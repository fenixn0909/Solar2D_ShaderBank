
--[[
    Original implementation for this bank. False-color thermal/FLIR
    "vision mode" - remaps input luminance through a seven-stop
    black -> purple -> blue -> green -> yellow -> red -> white ramp
    (the classic infrared-camera palette), then layers sensor grain,
    a slow scanline flicker, a bloom boost on the hottest pixels, and
    a soft edge vignette to sell the handheld-scanner feel.

    Checked against all existing kernels first: kernelF_UI_xrayVision
    is a see-through silhouette/skeleton reveal (different goal - it
    exposes what's *behind* a sprite); kernelC_FX_heatHazeShimmer is a
    refraction/distortion effect (bends the image, doesn't recolor
    it); kernelF_color_HSV/invertFlash/colorCycling only rotate or
    invert existing hue, none build a fixed thermal gradient. This is
    the only luminance-to-heat-palette remap in the bank.

    Palette_Shift lets you bias the mapping warmer/cooler (e.g. for a
    "cold vision" variant, push it negative) without touching the
    stops themselves. Opacity blends back to the original image, so
    you can dial in a partial "vision mode activating" transition.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "UI"
kernel.name = "thermalVision"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Sensitivity','Grain_Amount','Scan_Speed','Scan_Amount',
            'Hot_Boost','Vignette_Amount','Palette_Shift','Opacity',
            '','','','',
            '','','','',
        },
        default = {
            1.2,.08,2,.06,
            .4,.25,0,1,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .2,0,0,0,
            0,0,-.3,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            3,.5,10,.3,
            2,1,.3,1,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Sensitivity     = u_UserData0[0][0];
float Grain_Amount    = u_UserData0[0][1];
float Scan_Speed      = u_UserData0[0][2];
float Scan_Amount     = u_UserData0[0][3];
float Hot_Boost       = u_UserData0[1][0];
float Vignette_Amount = u_UserData0[1][1];
float Palette_Shift   = u_UserData0[1][2];
float Opacity         = u_UserData0[1][3];

//----------------------------------------------

P_RANDOM float therm_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 127.1, 311.7 ) ) ) * 43758.5453123 );
}

vec3 therm_palette( float t )
{
    t = clamp( t, 0.0, 1.0 );
    vec3 c0 = vec3( 0.00, 0.00, 0.04 );
    vec3 c1 = vec3( 0.22, 0.00, 0.45 );
    vec3 c2 = vec3( 0.00, 0.25, 0.80 );
    vec3 c3 = vec3( 0.00, 0.70, 0.35 );
    vec3 c4 = vec3( 0.95, 0.85, 0.05 );
    vec3 c5 = vec3( 0.95, 0.15, 0.00 );
    vec3 c6 = vec3( 1.00, 1.00, 0.90 );

    float s = t * 6.0;
    vec3 col = mix( c0, c1, clamp( s - 0.0, 0.0, 1.0 ) );
    col = mix( col, c2, clamp( s - 1.0, 0.0, 1.0 ) );
    col = mix( col, c3, clamp( s - 2.0, 0.0, 1.0 ) );
    col = mix( col, c4, clamp( s - 3.0, 0.0, 1.0 ) );
    col = mix( col, c5, clamp( s - 4.0, 0.0, 1.0 ) );
    col = mix( col, c6, clamp( s - 5.0, 0.0, 1.0 ) );
    return col;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float lum = dot( tex.rgb, vec3( 0.299, 0.587, 0.114 ) );
    float heat = clamp( ( lum - 0.5 ) * Sensitivity + 0.5 + Palette_Shift, 0.0, 1.0 );

    float grain = therm_hash( UV * 512.0 + fract( CoronaTotalTime ) * 91.7 ) - 0.5;
    heat = clamp( heat + grain * Grain_Amount, 0.0, 1.0 );

    vec3 thermal = therm_palette( heat );

    float scan = 0.5 + 0.5 * sin( UV.y * 220.0 - CoronaTotalTime * Scan_Speed );
    thermal *= 1.0 - Scan_Amount * 0.5 + Scan_Amount * scan;

    float hotspot = smoothstep( 0.82, 1.0, heat );
    thermal += vec3( 1.0, 0.9, 0.7 ) * hotspot * Hot_Boost;

    float d = length( UV - vec2( 0.5 ) );
    thermal *= 1.0 - Vignette_Amount * smoothstep( 0.35, 0.75, d );

    vec3 finalRGB = mix( tex.rgb, thermal, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
