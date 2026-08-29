
--[[
    https://godotshaders.com/shader/procedural-torch-candle-shader-fire-smoke-sparks/
    CaptainLaptop
    October 19, 2025
    (CC0 / MIT per the post AND the shader's own header comment)

    Fully procedural - no textures, matches the original exactly. The
    original has 25 uniforms; only the ~16 with the most visible impact
    on look/feel/performance are exposed here (packed into one mat4
    block, same curation approach as this bank's Balatro/Fire2D ports).
    Fixed at the original's defaults rather than exposed: fromColor,
    toColor, sparkColor, smokeColor (Hue_Shift + Saturation_Factor
    already cover "recolor the whole fire", which is the original's
    own suggested use for those two params - "blue fire, magical
    fire"), sparkSize/sparkSpeed/smokeSize/smokeDrift, glow.xy, and
    posOffset.

    The original's 3 particle loops use uniform-driven counts
    (`for (float i = 0.0; i < particleCount; i++)`), which isn't a
    constant loop bound - below, each loop runs a fixed max (matching
    the original's own documented slider ceiling: 512/50/50) with an
    early break once the exposed count is reached, so it stays valid
    across GLES2 targets.

    Performance note carried over from the original post: this is
    meant for small on-screen elements (torches, candles), not
    full-screen use - "one or two flames are negligible, hundreds may
    be costly", and that's before raising Particle_Count/Spark_Count/
    Smoke_Count above their defaults.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "torchFlame"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Speed','Flicker_Strength','Particle_Count','Fire_Shift',
            'Fire_Shift_Frequency','Size_X','Size_Y','Wind_Force',
            'Spark_Count','Smoke_Count','Alpha','Hue_Shift',
            'Saturation_Factor','Pixel_Size','Brightness','Aspect_Ratio',
        },
        default = {
            1, .15, 128, .15,
            5, .05, .75, 0,
            18, 20, .95, 0,
            1, .015, .001, 1,
        },
        min = {
            .1, 0, 16, 0,
            1, .01, .2, -.5,
            0, 0, 0, -1,
            0, .002, .0001, .2,
        },
        max = {
            5, .5, 512, .5,
            10, .2, 1.5, .5,
            50, 50, 1, 1,
            2, .05, .01, 3,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Speed                = u_UserData0[0][0];
float Flicker_Strength     = u_UserData0[0][1];
float Particle_Count       = u_UserData0[0][2];
float Fire_Shift           = u_UserData0[0][3];
float Fire_Shift_Frequency = u_UserData0[1][0];
float Size_X               = u_UserData0[1][1];
float Size_Y               = u_UserData0[1][2];
float Wind_Force           = u_UserData0[1][3];
float Spark_Count          = u_UserData0[2][0];
float Smoke_Count          = u_UserData0[2][1];
float Alpha                = u_UserData0[2][2];
float Hue_Shift            = u_UserData0[2][3];
float Saturation_Factor    = u_UserData0[3][0];
float Pixel_Size           = u_UserData0[3][1];
float Brightness           = u_UserData0[3][2];
float Aspect_Ratio         = u_UserData0[3][3];

// fixed at the original's defaults - see header
vec3 fromColor   = vec3( 0.9, 0.2, 0.1 );
vec3 toColor     = vec3( 0.4, 0.35, 0.2 );
vec3 sparkColor  = vec3( 1.0, 0.7, 0.0 );
vec3 smokeColor  = vec3( 0.05, 0.05, 0.05 );
vec2 glow        = vec2( 0.001, 0.04 );
vec2 posOffset   = vec2( 0.0, -0.5 );
float sparkSize  = 0.004;
float sparkSpeed = 0.15;
float smokeSize  = 0.015;
float smokeDrift = 0.2;

vec2 size = vec2( Size_X, Size_Y );
float TIME = CoronaTotalTime;

//----------------------------------------------

float Hash1( float t )
{
    return fract( cos( t * 124.97 ) * 248.842 ) - 0.5;
}

float saturate1( float x )
{
    return clamp( x, 0.0, 1.0 );
}

vec3 rgb_to_hsv( vec3 c )
{
    vec4 K = vec4( 0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0 );
    vec4 p = mix( vec4( c.bg, K.wz ), vec4( c.gb, K.xy ), step( c.b, c.g ) );
    vec4 q = mix( vec4( p.xyw, c.r ), vec4( c.r, p.yzx ), step( p.x, c.r ) );
    float d = q.x - min( q.w, q.y );
    float e = 1.0e-10;
    return vec3( abs( q.w - q.y ) / ( 6.0 * d + e ) + q.z, d / ( q.x + e ), q.x );
}

vec3 hsv_to_rgb( vec3 c )
{
    vec4 K = vec4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
    vec3 p = abs( fract( c.xxx + K.xyz ) * 6.0 - K.w );
    return c.z * mix( K.xxx, clamp( p - K.x, 0.0, 1.0 ), c.y );
}

//----------------------------------------------

vec3 Simulate( vec2 uv, float t )
{
    vec3 res = vec3( 0.0 );

    for ( int ii = 0; ii < 512; ii++ ) {
        if ( float( ii ) >= Particle_Count ) break;
        float i = float( ii );

        float ct = fract( t + ( i + 1.0 ) / Particle_Count );
        float seed = Hash1( ( i + 1.0 ) * ( t - ct ) );

        vec2 dir = vec2( 0.0, size.y );
        dir.x += Wind_Force;
        dir.x += ( cos( t * seed ) * sin( ct * Fire_Shift_Frequency ) ) * mix( 0.0, Fire_Shift, log( ct ) );

        float cb = saturate1( mix( Brightness, 0.0, ct ) );
        vec2 off = vec2( seed * size.x, 0.0 );

        res += mix( fromColor * abs( seed ), toColor, ct )
               * smoothstep( glow.x, glow.y, cb / length( ( uv - off - ( dir * ct ) ) ) );
    }

    return res;
}

vec3 SimulateSparks( vec2 uv, float t )
{
    vec3 sparkRes = vec3( 0.0 );
    t *= sparkSpeed;

    for ( int ii = 0; ii < 50; ii++ ) {
        if ( float( ii ) >= Spark_Count ) break;
        float i = float( ii );

        float particleId = ( i + 1.0 ) * 133.0;
        float ct = fract( t + particleId / 100.0 );
        float seed = Hash1( particleId );

        vec2 dir = vec2( seed * 0.4, size.y * 2.5 );
        dir.x += Wind_Force * 2.0;

        vec2 particle_center = vec2( seed * size.x * 0.3, 0.0 ) + ( dir * ct );
        float dist = length( uv - particle_center );

        float particle_influence = saturate1( 1.0 - dist / ( sparkSize * 5.0 ) );
        float glow_falloff = pow( particle_influence, 15.0 );
        float lifespan_fade = saturate1( 1.0 - ct * 2.0 );

        sparkRes += sparkColor * glow_falloff * lifespan_fade * 100.0;
    }
    return sparkRes;
}

vec3 SimulateSmoke( vec2 uv, float t )
{
    vec3 smokeRes = vec3( 0.0 );

    for ( int ii = 0; ii < 50; ii++ ) {
        if ( float( ii ) >= Smoke_Count ) break;
        float i = float( ii );

        float particleId = ( i + 1.0 ) * 111.0;
        float ct = fract( t * 0.5 + particleId / 100.0 );
        float seed = Hash1( particleId );

        vec2 dir = vec2( seed * smokeDrift, size.y * 1.5 );
        dir.x += Wind_Force * 0.8;

        float cb = saturate1( mix( Brightness * 10.0, 0.0, ct * 1.5 ) );
        vec2 off = vec2( seed * size.x * 0.5, size.y * 0.6 );

        smokeRes += smokeColor * smoothstep( smokeSize, smokeSize * 2.0,
            cb / length( ( uv - off - ( dir * ct ) ) ) );
    }
    return smokeRes;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 frag_coords = UV * 2.0 - 1.0;
    frag_coords.x *= Aspect_Ratio;
    frag_coords.y *= -1.0;
    frag_coords -= posOffset;

    vec2 pixelated_frag = floor( frag_coords / Pixel_Size ) * Pixel_Size;

    float base_time = TIME + 100.0;

    vec3 fire_color  = Simulate( pixelated_frag, base_time * Speed );
    vec3 spark_color = SimulateSparks( pixelated_frag, base_time );
    vec3 smoke_color = SimulateSmoke( pixelated_frag, base_time );

    vec3 result_color = fire_color + spark_color + smoke_color;

    vec3 hsv = rgb_to_hsv( result_color );
    hsv.x = fract( hsv.x + Hue_Shift );
    hsv.y *= Saturation_Factor;
    result_color = hsv_to_rgb( hsv );

    float flicker = ( Hash1( base_time * 5.0 ) + 0.5 ) * Flicker_Strength;
    float intensity_mod = 1.0 + flicker;
    vec3 final_color = result_color * intensity_mod;

    float intensity = max( max( result_color.r, result_color.g ), result_color.b );
    float final_alpha = smoothstep( 0.01, 0.5, intensity ) * Alpha;

    P_COLOR vec4 COLOR = vec4( final_color * Alpha, final_alpha );
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

