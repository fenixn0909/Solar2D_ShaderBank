
--[[
    Original implementation for this bank. Ordinary layered-noise
    clouds read flat because every part of the density field gets lit
    the same; this adds the classic cheap "volumetric" trick from
    raymarched cloud demos - resample the density field a second time
    offset toward a light direction, and darken the current point
    wherever that second sample is denser (it's standing in its own
    shadow). One fbm evaluation for shape, one offset re-evaluation for
    fake self-shadowing, no actual raymarch needed.

    Checked against all existing kernels first: this bank's existing
    cloud generators (kernelG_cloud_simple/topdownCloud2D/motionPF/
    vertex) are flat single-density-sample shapes with a uniform tint
    and no shadow re-sample; kernelG_FX_stormCloudFlash (batch 7) is
    keyed entirely around a triggered internal *flash* event and has
    no self-shadow term of its own. This is the only cloud kernel here
    with light-direction-based fake self-shadowing.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "volumetricCloudscape"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Scale','Speed','Coverage','Light_Sample_Dist',
            'Shadow_Strength','Shadow_R','Shadow_G','Shadow_B',
            'Lit_R','Lit_G','Lit_B','Opacity',
            'Move_Angle','','','',
        },
        default = {
            2.5,.02,.45,.06,
            .7,.45,.5,.6,
            1,.98,.95,1,
            0,0,0,0,
        },
        min = {
            .5,-.1,0,.01,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            6,10,.9,.2,
            1,1,1,1,
            1,1,1,1,
            6.28318,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Scale            = u_UserData0[0][0];
float Speed             = u_UserData0[0][1];
float Coverage          = u_UserData0[0][2];
float Light_Sample_Dist = u_UserData0[0][3];
float Shadow_Strength   = u_UserData0[1][0];
vec3  Shadow_Color      = vec3( u_UserData0[1][1], u_UserData0[1][2], u_UserData0[1][3] );
vec3  Lit_Color         = vec3( u_UserData0[2][0], u_UserData0[2][1], u_UserData0[2][2] );
float Opacity           = u_UserData0[2][3];
float Move_Angle        = u_UserData0[3][0];

//----------------------------------------------

P_RANDOM float vc_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 15.3, 71.8 ) ) ) * 43758.5453123 );
}

P_RANDOM float vc_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    vec2 u = f * f * ( 3.0 - 2.0 * f );
    return mix( mix( vc_hash( i ), vc_hash( i + vec2( 1.0, 0.0 ) ), u.x ),
                mix( vc_hash( i + vec2( 0.0, 1.0 ) ), vc_hash( i + vec2( 1.0, 1.0 ) ), u.x ), u.y );
}

float vc_fbm( vec2 p )
{
    float total = 0.0;
    float amp = 0.5;
    for ( int i = 0; i < 5; i++ )
    {
        total += vc_noise( p ) * amp;
        p *= 2.03;
        amp *= 0.5;
    }
    return total;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 moveDir = vec2( cos( Move_Angle ), sin( Move_Angle ) );
    vec2 drift = moveDir * ( CoronaTotalTime * Speed );
    vec2 p = UV * Scale + drift;

    float density = smoothstep( Coverage, Coverage + 0.35, vc_fbm( p ) );

    vec2 lightSamplePos = p + vec2( 0.0, -Light_Sample_Dist );
    float densityAbove = smoothstep( Coverage, Coverage + 0.35, vc_fbm( lightSamplePos ) );

    float shadow = 1.0 - densityAbove * Shadow_Strength;
    vec3 cloudColor = mix( Shadow_Color, Lit_Color, clamp( shadow, 0.0, 1.0 ) );

    float alpha = density * Opacity;

    P_COLOR vec4 COLOR = vec4( cloudColor, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
