
--[[
    Original implementation for this bank. Deliberately not built the way
    this bank's UV-swirl kernels are (kernelF_deform_vortexOverlay.lua,
    kernelF_trans_vortexShrink.lua) - those rotate a sampled texture's UVs
    by an angle that increases toward the center. This is a self-
    contained generator with actual differential rotation baked into a
    spiral streak pattern (`spinSpeed = k / radius`, the real physics of
    how whirlpools spin faster near the drain), a radial depth gradient
    from a lighter rim color to a near-black center, evenly spaced foam
    rings, and a dedicated dark "drain" hole - reads as a physical funnel
    rather than a distorted photo.

    Pure generator, mostly opaque within its radius (transparent outside)
    - a hazard/drain/portal-to-the-deep prop. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "whirlpoolVortex"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Spin_Speed','Radius','Arm_Count','Spiral_Tightness',
            'Foam_Ring_Count','Drain_Radius','Edge_Color_R','Edge_Color_G',
            'Edge_Color_B','Center_Color_R','Center_Color_G','Center_Color_B',
            'Aspect_Ratio','','','',
        },
        default = {
            .15,.42,5,1.2,
            5,.05,.25,.55,
            .65,.02,.08,.12,
            1,0,0,0,
        },
        min = {
            -1,.1,1,0,
            1,0,0,0,
            0,0,0,0,
            .2,0,0,0,
        },
        max = {
            1,.6,10,4,
            12,.15,1,1,
            1,1,1,1,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Spin_Speed        = u_UserData0[0][0];
float Radius            = u_UserData0[0][1];
float Arm_Count         = u_UserData0[0][2];
float Spiral_Tightness  = u_UserData0[0][3];
float Foam_Ring_Count   = u_UserData0[1][0];
float Drain_Radius      = u_UserData0[1][1];
vec3  Edge_Color        = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
vec3  Center_Color      = vec3( u_UserData0[2][1], u_UserData0[2][2], u_UserData0[2][3] );
float Aspect_Ratio      = u_UserData0[3][0];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV - vec2( 0.5 );
    uv.x *= Aspect_Ratio;

    float rad = length( uv );
    float ang = atan( uv.y, uv.x );

    float spinSpeed = Spin_Speed / max( rad, 0.05 );
    float spunAngle = ang + CoronaTotalTime * spinSpeed;

    float spiral = sin( spunAngle * Arm_Count + rad * Spiral_Tightness * 10.0 );
    float streaks = smoothstep( 0.2, 1.0, spiral ) * step( rad, Radius );

    float depth = clamp( rad / Radius, 0.0, 1.0 );
    vec3 baseColor = mix( Center_Color, Edge_Color, depth );

    float foamRingSpacing = Radius / Foam_Ring_Count;
    float foamDist = abs( mod( rad + foamRingSpacing * 0.5, foamRingSpacing ) - foamRingSpacing * 0.5 );
    float foam = ( 1.0 - smoothstep( 0.0, 0.01, foamDist ) ) * step( rad, Radius ) * step( 0.05, rad );

    float drain = 1.0 - smoothstep( 0.0, max( Drain_Radius, 0.001 ), rad );

    vec3 rgb = baseColor + vec3( 1.0 ) * streaks * 0.3 + vec3( 0.9, 0.95, 1.0 ) * foam * 0.6;
    rgb = mix( rgb, vec3( 0.0 ), drain );

    float alpha = step( rad, Radius ) * ( 1.0 - drain * 0.7 );
    alpha = clamp( alpha + foam * 0.3, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
