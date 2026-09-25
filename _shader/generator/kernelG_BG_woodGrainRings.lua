
--[[
    Original implementation for this bank, in the classic "procedural
    texture 101" family taught throughout shader-programming courses
    (concentric distance-field banding perturbed by noise - the
    standard technique behind wood/tree-ring/agate shaders going back
    to Perlin's own procedural texture work). Rings radiate from
    Knot_Pos as sine bands of distance, a single noise layer perturbs
    the distance field for organic wobble instead of perfectly circular
    rings, and fine angular streaks are subtracted in for grain detail.

    Checked against all existing kernels first: nothing else in the
    bank does concentric distance-based ring banding - closest by
    noise technique is this bank's own kernelG_FX_arcaneSmoke (batch 4),
    which explicitly documents using *domain-warped* fbm (warping a
    noise field's own coordinate through two more noise evaluations,
    Inigo Quilez's technique) for a wispy translucent smoke look; this
    kernel deliberately does NOT domain-warp - it's a single perturbed
    distance field for solid opaque banding, a different technique
    aimed at a different, harder-edged material result.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "woodGrainRings"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Knot_X','Knot_Y','Ring_Frequency','Wobble',
            'Grain_Scale','Contrast','Streak_Amount','Dark_R',
            'Dark_G','Dark_B','Light_R','Light_G',
            'Light_B','Aspect_Ratio','Speed','Flow_Amount',
        },
        default = {
            .3,.4,18,.15,
            30,1.6,.12,.35,
            .2,.08,.75,.5,
            .25,1,.15,.5,
        },
        min = {
            0,0,4,0,
            5,.5,0,0,
            0,0,0,0,
            0,.2,-2,0,
        },
        max = {
            1,1,50,.4,
            80,4,.4,1,
            1,1,1,1,
            1,5,2,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

vec2  Knot_Pos       = vec2( u_UserData0[0][0], u_UserData0[0][1] );
float Ring_Frequency = u_UserData0[0][2];
float Wobble         = u_UserData0[0][3];
float Grain_Scale    = u_UserData0[1][0];
float Contrast       = u_UserData0[1][1];
float Streak_Amount  = u_UserData0[1][2];
vec3  Dark_Wood      = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
vec3  Light_Wood     = vec3( u_UserData0[2][2], u_UserData0[2][3], u_UserData0[3][0] );
float Aspect_Ratio   = u_UserData0[3][1];
float Speed          = u_UserData0[3][2];
float Flow_Amount    = u_UserData0[3][3];

//----------------------------------------------

P_RANDOM float wood_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 27.6, 61.1 ) ) ) * 43758.5453123 );
}

P_RANDOM float wood_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( wood_hash( i ), wood_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( wood_hash( i + vec2( 0.0, 1.0 ) ), wood_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    float t = CoronaTotalTime * Speed;
    // Slowly orbit the knot so the grain visibly breathes instead of sitting static.
    vec2 knot = Knot_Pos + vec2( cos( t * 0.7 ), sin( t * 0.9 ) ) * 0.03 * Flow_Amount;
    vec2 p = ( UV - knot ) * vec2( 1.0, Aspect_Ratio );
    float dist = length( p );

    float wobble = ( wood_noise( UV * Grain_Scale * 0.3 + vec2( t * 0.15, -t * 0.1 ) ) - 0.5 ) * Wobble;
    float ringPattern = 0.5 + 0.5 * sin( ( dist + wobble ) * Ring_Frequency * 6.28318 + t );
    ringPattern = pow( ringPattern, Contrast );

    float ang = atan( p.y, p.x );
    float streaks = wood_noise( vec2( dist * 30.0, ang * 4.0 ) ) * Streak_Amount;

    vec3 woodColor = mix( Dark_Wood, Light_Wood, ringPattern );
    woodColor = clamp( woodColor - streaks, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( woodColor, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
