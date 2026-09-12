
--[[
    Original implementation for this bank. Swaps a sprite's foliage
    palette for a season without flattening the whole image: pixels
    are only recolored in proportion to how close their hue sits to
    "green" (a Green_Hue_Center / Green_Hue_Range gate), so sky, skin,
    stone and other non-foliage colors pass through close to
    unchanged while leaves/grass shift toward the target season's
    characteristic hue (fresh spring green, deep summer green, autumn
    orange-red, or desaturated winter blue-white) via a 4-stop cascaded
    ramp over a continuous Season value, so you can tween across the
    year rather than only snapping between four fixed looks.

    Checked against all existing kernels first: kernelF_color_HSV and
    kernelF_color_hueShift/hueSwap rotate hue globally with no gating
    by original hue, so they'd shift sky and skin along with foliage;
    kernelF_color_cycling loops through colors over time rather than
    targeting specific seasonal palette stops; this bank's own
    kernelG_BG_dayNightCycle (batch 6) cycles a *sky backdrop*, not a
    foliage-selective recolor of arbitrary existing art. No overlap.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "seasonalShift"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Season','Green_Hue_Center','Green_Hue_Range','Saturation_Boost',
            'Winter_Frost','Opacity','','',
            '','','','',
            '','','','',
        },
        default = {
            0,.33,.22,1.1,
            .3,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0,.05,.5,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            4,1,.4,2,
            1,1,0,0,
            0,0,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Season            = u_UserData0[0][0];
float Green_Hue_Center  = u_UserData0[0][1];
float Green_Hue_Range   = u_UserData0[0][2];
float Saturation_Boost  = u_UserData0[0][3];
float Winter_Frost      = u_UserData0[1][0];
float Opacity           = u_UserData0[1][1];

//----------------------------------------------

vec3 season_rgb2hsv( vec3 c )
{
    vec4 K = vec4( 0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0 );
    vec4 p = mix( vec4( c.bg, K.wz ), vec4( c.gb, K.xy ), step( c.b, c.g ) );
    vec4 q = mix( vec4( p.xyw, c.r ), vec4( c.r, p.yzx ), step( p.x, c.r ) );
    float d = q.x - min( q.w, q.y );
    float e = 1.0e-10;
    return vec3( abs( q.z + ( q.w - q.y ) / ( 6.0 * d + e ) ), d / ( q.x + e ), q.x );
}

vec3 season_hsv2rgb( vec3 c )
{
    vec3 rgb = clamp( abs( mod( c.x * 6.0 + vec3( 0.0, 4.0, 2.0 ), 6.0 ) - 3.0 ) - 1.0, 0.0, 1.0 );
    return c.z * mix( vec3( 1.0 ), rgb, c.y );
}

float season_targetHue( float s )
{
    float springHue = 0.30;
    float summerHue = 0.36;
    float autumnHue = 0.08;
    float winterHue = 0.58;

    float h = mix( springHue, summerHue, clamp( s - 0.0, 0.0, 1.0 ) );
    h = mix( h, autumnHue, clamp( s - 1.0, 0.0, 1.0 ) );
    h = mix( h, winterHue, clamp( s - 2.0, 0.0, 1.0 ) );
    h = mix( h, springHue, clamp( s - 3.0, 0.0, 1.0 ) );
    return h;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );
    vec3 hsv = season_rgb2hsv( tex.rgb );

    float hueDist = abs( hsv.x - Green_Hue_Center );
    hueDist = min( hueDist, 1.0 - hueDist );
    float gate = smoothstep( Green_Hue_Range, Green_Hue_Range * 0.3, hueDist ) * smoothstep( 0.06, 0.25, hsv.y );

    float targetHue = season_targetHue( Season );
    float winterAmt = clamp( 1.0 - abs( Season - 2.0 ), 0.0, 1.0 );

    vec3 newHsv = hsv;
    newHsv.x = mix( hsv.x, targetHue, gate );
    newHsv.y = clamp( mix( hsv.y, hsv.y * Saturation_Boost * ( 1.0 - winterAmt * Winter_Frost ), gate ), 0.0, 1.0 );
    newHsv.z = mix( hsv.z, clamp( hsv.z + winterAmt * Winter_Frost * gate * 0.3, 0.0, 1.0 ), gate );

    vec3 finalRGB = mix( tex.rgb, season_hsv2rgb( newHsv ), Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
