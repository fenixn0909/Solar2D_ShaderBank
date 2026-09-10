
--[[
    Original implementation for this bank. Seven concentric bands at the
    standard ROYGBIV radii, colored with the standard `abs(mod(h*6+offset,
    6)-3)-1` hue-to-RGB identity (a generic trigonometry-free HSV-to-RGB
    formula seen throughout shader code, not any one author's IP), each
    just a `smoothstep` ring test at its own radius - a fixed compile-time
    loop of 7 (GLES-safe, same reasoning as this bank's other loop-based
    kernels). The arc naturally reads as sitting on a horizon because
    everything below the arc's center point fades out via the same
    distance-above-center value used for the leg fade at both ends,
    rather than needing separate angle-based masking logic.

    Pure generator, transparent background - place above a horizon line
    after a rain-themed transition/weather effect. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "rainbowArc"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Radius','Thickness','Arc_Center_Y','Leg_Fade',
            'Brightness','Mist_Amount','Aspect_Ratio','',
            '','','','',
            '','','','',
        },
        default = {
            .32,.09,.75,.15,
            1,.25,1,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            .1,.02,0,.02,
            0,0,.2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            .6,.2,1.2,.6,
            2,1,5,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Radius        = u_UserData0[0][0];
float Thickness     = u_UserData0[0][1];
float Arc_Center_Y  = u_UserData0[0][2];
float Leg_Fade      = u_UserData0[0][3];
float Brightness    = u_UserData0[1][0];
float Mist_Amount   = u_UserData0[1][1];
float Aspect_Ratio  = u_UserData0[1][2];

const int BAND_COUNT = 7;

vec3 hue2rgb( float h )
{
    vec3 rgb = clamp( abs( mod( h * 6.0 + vec3( 0.0, 4.0, 2.0 ), 6.0 ) - 3.0 ) - 1.0, 0.0, 1.0 );
    return rgb;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5, Arc_Center_Y );
    uv.x *= Aspect_Ratio;

    float rad = length( uv );
    float bandWidth = Thickness / float( BAND_COUNT );

    vec3 rgb = vec3( 0.0 );
    float alpha = 0.0;

    for ( int bandIndex = 0; bandIndex < BAND_COUNT; bandIndex++ ) {
        float bandRadius = Radius + float( bandIndex ) * bandWidth;
        float bandMask = 1.0 - smoothstep( bandWidth * 0.4, bandWidth * 0.5, abs( rad - bandRadius ) );
        vec3 bandColor = hue2rgb( float( bandIndex ) / float( BAND_COUNT - 1 ) * 0.85 );

        rgb += bandColor * bandMask;
        alpha = max( alpha, bandMask );
    }

    float mist = ( 1.0 - smoothstep( 0.0, Thickness * 0.6, abs( rad - Radius ) ) ) * Mist_Amount;
    rgb += vec3( 1.0 ) * mist;
    alpha = clamp( alpha + mist, 0.0, 1.0 );

    float legFade = smoothstep( 0.0, Radius * Leg_Fade, -uv.y );
    alpha *= legFade;

    rgb *= Brightness;

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
