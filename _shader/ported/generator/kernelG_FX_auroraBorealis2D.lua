
--[[
    Original implementation for this bank. Real-time 2D aurora borealis
    shaders (Kelvin van Hoorn's raymarched Unity piece, Miskatonic
    Studio's Godot version, several "Northern Lights" Unity Asset Store
    VFX packs) are normally built as a raymarch through a 3D atmosphere
    shell - overkill and the wrong tool for a flat sprite effect, so this
    reimplements the *look* rather than the raymarch: several vertically-
    drifting curtain bands built from domain-warped noise (each band its
    own frequency/speed/phase so they don't lock together), screen-space
    Y-faded, additively colored across a two-stop gradient the way real
    aurora shifts from green to violet with altitude.

    Pure generator, transparent background - drop it as an overlay object
    above a night-sky background/backdrop. Aspect_Ratio convention matches
    the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "auroraBorealis2D"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed','Scale','Band_Count','Sharpness',
            'Color_A_R','Color_A_G','Color_A_B','Color_B_R',
            'Color_B_G','Color_B_B','Brightness','Height',
            'Aspect_Ratio','Warp','','',
        },
        default = {
            .25,2.2,4,2.2,
            .15,.95,.55,.55,
            .25,.95,1.3,.55,
            1,.6,0,0,
        },
        min = {
            -2,.5,1,.5,
            0,0,0,0,
            0,0,0,.1,
            .2,0,0,0,
        },
        max = {
            2,8,6,6,
            1,1,1,1,
            1,1,3,1,
            5,2,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Speed        = u_UserData0[0][0];
float Scale        = u_UserData0[0][1];
float Band_Count_f  = u_UserData0[0][2];
float Sharpness    = u_UserData0[0][3];
vec3  Color_A      = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
vec3  Color_B      = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Brightness   = u_UserData0[2][2];
float Height       = u_UserData0[2][3];
float Aspect_Ratio = u_UserData0[3][0];
float Warp         = u_UserData0[3][1];

const int BAND_MAX = 6;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    float t = CoronaTotalTime * Speed;
    float total = 0.0;

    for ( int bandIndex = 0; bandIndex < BAND_MAX; bandIndex++ ) {
        float active = step( float( bandIndex ) + 0.5, Band_Count_f );
        float fi = float( bandIndex );

        float freq = Scale * ( 1.0 + fi * 0.37 );
        float phase = hash1( fi * 9.1 + 2.0 ) * 40.0;
        float drift = t * ( 0.6 + hash1( fi * 5.3 ) * 0.8 );

        float warp = sin( uv.y * 3.0 + drift * 1.3 + fi ) * Warp;
        float wave = sin( ( uv.x + warp ) * freq + drift + phase );
        wave += 0.5 * sin( ( uv.x + warp ) * freq * 2.1 - drift * 1.7 + phase );

        float bandCenter = 0.25 + fi * ( 0.5 / float( BAND_MAX ) ) + 0.12 * wave;
        float bandDist = abs( ( 1.0 - uv.y ) - bandCenter * Height - ( 1.0 - Height ) * 0.1 );
        float curtain = exp( -bandDist * bandDist * ( 40.0 / max( Sharpness, 0.1 ) ) );

        total += active * curtain / float( BAND_MAX );
    }

    total = clamp( total * Brightness * float( BAND_MAX ), 0.0, 2.0 );

    vec3 col = mix( Color_A, Color_B, clamp( total * 0.6, 0.0, 1.0 ) ) * total;
    float alpha = clamp( total, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( col, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
