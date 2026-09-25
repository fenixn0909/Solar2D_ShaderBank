
--[[
    Original implementation for this bank. The "distance to a noise-
    displaced line" technique for procedural lightning bolts is a
    standard, widely-taught approach (turns up under names like "electric
    arc shader" and "Tesla coil shader" across Unity Shader Graph
    tutorials, e.g. Fox Jump's "Lightning ShaderGraph" and the several
    "Electric arc VFX" Shader Graph packages on itch.io) rather than one
    specific person's code, so this is a fresh derivation: perpendicular
    distance from each pixel to the straight line between two points,
    compared against a per-segment lateral noise offset that's re-seeded
    in discrete steps (Flicker_Speed) rather than smoothly animated, which
    is what gives real electricity its jittery, non-sinusoidal snap rather
    than a smoothly wiggling "magic whip" look.

    This is the "chain lightning" / Tesla-arc use case specifically -
    unlike this bank's existing kernelG_FX_lightningNature.lua and
    kernelG_FX_lightning2D.lua (both single bolts anchored to the middle
    of the sprite, sky-strike style), Start_X/Y and End_X/Y here are two
    independent UV-space points so it can jump between two arbitrary game
    objects (enemy-to-enemy chain lightning, a Tesla trap between two
    posts, a taser beam, etc). Pure generator, transparent background.
    Aspect_Ratio convention matches the rest of this bank (see
    kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "chainLightningArc"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Start_X','Start_Y','End_X','End_Y',
            'Jaggedness','Thickness','Glow','Color_R',
            'Color_G','Color_B','Core_White','Flicker_Speed',
            'Aspect_Ratio','','','',
        },
        default = {
            .15,.5,.85,.45,
            .09,.4,.5,.55,
            .75,1,.85,18,
            1,0,0,0,
        },
        min = {
            0,0,0,0,
            0,.02,.05,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            1,1,1,1,
            .3,2,2,1,
            1,1,1,40,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Start_X       = u_UserData0[0][0];
float Start_Y       = u_UserData0[0][1];
float End_X         = u_UserData0[0][2];
float End_Y         = u_UserData0[0][3];
float Jaggedness    = u_UserData0[1][0];
float Thickness     = u_UserData0[1][1];
float Glow          = u_UserData0[1][2];
vec3  Color         = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Core_White    = u_UserData0[2][2];
float Flicker_Speed = u_UserData0[2][3];
float Aspect_Ratio  = u_UserData0[3][0];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;

    vec2 A = vec2( Start_X * Aspect_Ratio, Start_Y );
    vec2 B = vec2( End_X * Aspect_Ratio, End_Y );

    vec2 AB = B - A;
    float lenAB = length( AB );
    vec2 dir = AB / max( lenAB, 0.0001 );
    vec2 nrm = vec2( -dir.y, dir.x );

    vec2 toP = uv - A;
    float t = clamp( dot( toP, dir ) / max( lenAB, 0.0001 ), 0.0, 1.0 );
    float perp = dot( toP, nrm );

    float seedStep = floor( CoronaTotalTime * Flicker_Speed );
    float cell = floor( t * 14.0 );

    float n1 = hash1( cell + seedStep * 3.7 ) - 0.5;
    float n2 = hash1( cell * 3.1 + 7.0 + seedStep * 3.7 ) - 0.5;
    float taper = sin( t * 3.14159265 );
    float offset = ( n1 * 0.7 + n2 * 0.3 ) * Jaggedness * lenAB * taper;

    float dist = abs( perp - offset );
    float core = exp( -dist * dist * ( 400.0 / max( Thickness, 0.02 ) ) );
    float halo = exp( -dist * dist * ( 30.0 / max( Glow, 0.05 ) ) );

    vec3 hotColor = mix( Color, vec3( 1.0 ), Core_White );
    vec3 rgb = Color * halo * 0.9 + hotColor * core * 1.3;
    float alpha = clamp( halo * 0.7 + core, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
