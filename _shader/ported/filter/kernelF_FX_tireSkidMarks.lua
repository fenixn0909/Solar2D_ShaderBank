
--[[
    Original implementation for this bank. Two dark scuffed streak
    bands overlaid onto a ground/road sprite, following a slightly
    wobbling path at Wheel_Offset either side of center, fading in
    from Start_Fade and out after Length - a racing-game drift/skid
    scar rather than a random scatter.

    Checked against all existing kernels first: kernelF_FX_tilerSplatter/
    tilerSplatterV2 scatter randomly-rotated *tile* decals across the
    whole surface (no wheel-path shape, no two-band pairing);
    kernelF_FX_crackOverlay grows branching damage fissures from a
    point via Voronoi search, not two parallel darkened bands. Neither
    produces a paired wheel-track mark.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "tireSkidMarks"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Wheel_Offset','Band_Width','Wobble_Amount','Length',
            'Start_Fade','Darkness','Seed','Opacity',
            'Count','','','',
            '','','','',
        },
        default = {
            .04,.012,.02,.7,
            .05,.6,0,1,
            2,0,0,0,
            0,0,0,0,
        },
        min = {
            .01,.003,0,.1,
            0,0,0,0,
            1,0,0,0,
            0,0,0,0,
        },
        max = {
            .15,.03,.5,1,
            .3,1,50,1,
            8,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Wheel_Offset  = u_UserData0[0][0];
float Band_Width    = u_UserData0[0][1];
float Wobble_Amount = u_UserData0[0][2];
float Length_       = u_UserData0[0][3];
float Start_Fade    = u_UserData0[1][0];
float Darkness      = u_UserData0[1][1];
float Seed          = u_UserData0[1][2];
float Opacity       = u_UserData0[1][3];
float Skid_Count    = u_UserData0[2][0];

//----------------------------------------------

P_RANDOM float skid_hash( float n )
{
    return fract( sin( n * 43.1 ) * 19781.3 );
}

float skid_band( vec2 uv, float offsetX, float seed )
{
    float wobble = ( sin( uv.y * 18.0 + seed * 6.0 ) * 0.5 + sin( uv.y * 41.0 + seed * 11.0 ) * 0.5 ) * Wobble_Amount;
    float centerX = 0.5 + offsetX + wobble;
    float d = abs( uv.x - centerX );
    float band = smoothstep( Band_Width, Band_Width * 0.3, d );

    float alongFade = smoothstep( 1.0, 1.0 - Start_Fade, uv.y ) * smoothstep( 1.0 - Length_ - Start_Fade, 1.0 - Length_, uv.y );

    float grain = 0.85 + 0.15 * skid_hash( floor( uv.y * 200.0 ) + seed );

    return band * alongFade * grain;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    // Count bands spread outward in pairs; Count 2 reproduces the
    // original left/right pair exactly (same offsets and seeds).
    float mark = 0.0;
    for ( int k = 0; k < 8; k++ )
    {
        float fk = float( k );
        float active = step( fk + 0.5, Skid_Count );
        float side = mod( fk, 2.0 ) < 0.5 ? -1.0 : 1.0;
        float spread = 1.0 + floor( fk * 0.5 ) * 0.9;
        mark += skid_band( UV, side * Wheel_Offset * spread, Seed + fk * 91.0 ) * active;
    }
    mark = clamp( mark, 0.0, 1.0 ) * Opacity;

    vec3 finalRGB = mix( tex.rgb, tex.rgb * ( 1.0 - Darkness ), mark );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
