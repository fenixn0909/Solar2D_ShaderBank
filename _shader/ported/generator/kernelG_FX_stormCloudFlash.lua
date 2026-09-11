
--[[
    Original implementation for this bank. A drifting thunderhead
    mass built from a 4-octave fbm, lit from *within* by irregular
    flashes rather than by drawing any bolt geometry - each flash is a
    random per-time-slot event (hashed from a coarse time bucket) with
    its own exponential decay envelope, so flashes pop and fade
    unevenly like real cloud-to-cloud lightning glow, occasionally
    double-firing when two adjacent slots both roll active. The flash
    also briefly lifts the cloud's overall opacity and brightness
    (Rumble_Amount) so thin patches flare rather than staying flat.

    Checked against all existing kernels first: kernelG_FX_lightning2D,
    kernelG_FX_lightningNature, kernelG_FX_transperantLightning, and
    kernelG_FX_chainLightningArc all draw an explicit visible bolt
    path/line - this one deliberately draws *no* bolt at all, only a
    cloud silhouette that lights up internally, which is a distinct
    "storm is flashing somewhere behind the clouds" read rather than
    "here is a lightning bolt". Not the same technique or output as
    any of the four.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "stormCloudFlash"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Cloud_Density','Cloud_Speed','Cloud_Scale','Flash_Chance',
            'Flash_Duration','Flash_R','Flash_G','Flash_B',
            'Cloud_R','Cloud_G','Cloud_B','Base_Alpha',
            'Rumble_Amount','','','',
        },
        default = {
            .55,.03,3.5,.35,
            .5,.85,.88,1,
            .18,.2,.26,.75,
            .5,0,0,0,
        },
        min = {
            0,0,.5,0,
            .1,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,.2,10,1,
            2,1,1,1,
            1,1,1,1,
            1.5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cloud_Density  = u_UserData0[0][0];
float Cloud_Speed    = u_UserData0[0][1];
float Cloud_Scale    = u_UserData0[0][2];
float Flash_Chance   = u_UserData0[0][3];
float Flash_Duration = u_UserData0[1][0];
vec3  Flash_Color    = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
vec3  Cloud_Color    = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Base_Alpha     = u_UserData0[2][3];
float Rumble_Amount  = u_UserData0[3][0];

//----------------------------------------------

P_RANDOM float storm_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

P_RANDOM float storm_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( storm_hash( i ), storm_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( storm_hash( i + vec2( 0.0, 1.0 ) ), storm_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float storm_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 4; i++ )
    {
        total += storm_noise( p ) * amp;
        p *= 2.02;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 p = UV * Cloud_Scale + vec2( CoronaTotalTime * Cloud_Speed, 0.0 );
    float n = storm_fbm( p );
    float cloudMask = smoothstep( 1.0 - Cloud_Density, 1.35 - Cloud_Density, n );

    float slotLen = 0.7;
    float t = CoronaTotalTime;
    float slot = floor( t / slotLen );
    float slotHash = storm_hash( vec2( slot, 4.7 ) );
    float active = step( 1.0 - Flash_Chance, slotHash );
    float localT = fract( t / slotLen );
    float envelope = active * exp( -localT * ( 6.0 / max( Flash_Duration, 0.05 ) ) );

    vec3 baseCloud = Cloud_Color * ( 0.4 + 0.6 * n );
    vec3 lit = mix( baseCloud, Flash_Color, clamp( envelope * 0.9, 0.0, 1.0 ) );
    float rumble = 1.0 + Rumble_Amount * envelope;

    vec3 rgb = lit * rumble;
    float alpha = clamp( cloudMask * ( Base_Alpha + envelope * ( 1.0 - Base_Alpha ) ), 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
