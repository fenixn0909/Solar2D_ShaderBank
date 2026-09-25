
--[[
    Original implementation for this bank. Reuses the "distance to a
    noise-displaced line" construction from this batch's own
    kernelG_FX_chainLightningArc.lua (a generic, well-known technique -
    see that file's header) but pointed at a completely different result:
    instead of a glowing bolt, the jagged line defines the edge of a
    narrow torn slit, with a tiny procedural starfield glinting inside it
    and a soft coloured glow along both edges - a "hole torn in reality"
    rather than an electrical arc.

    Deliberately not another reskin of this bank's existing swirl-based
    effects (kernelF_deform_vortexOverlay.lua, kernelF_trans_vortexShrink.lua,
    kernelF_FX_aetherialFlow.lua all rotate/distort the UVs of what's
    already there) - this has a hard silhouette (a torn slit you can see
    *through* into a small void) rather than a full-frame distortion, so
    it reads as a completely different kind of object on screen.

    Pure generator, transparent outside the tear. Aspect_Ratio convention
    matches the rest of this bank (see kernelF_FX_shockwave.lua's header).
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "FX"
kernel.name = "voidRiftTear"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Tear_X','Tear_Height','Jaggedness','Width',
            'Edge_Glow','Seed','Color_R','Color_G',
            'Color_B','Void_Brightness','Star_Density','Drift_Speed',
            'Aspect_Ratio','','','',
        },
        default = {
            .5,.55,.035,.012,
            .5,3,.55,.35,
            .95,1,.5,.5,
            1,0,0,0,
        },
        min = {
            0,.05,0,.002,
            .05,0,0,0,
            0,0,0,-2,
            .2,0,0,0,
        },
        max = {
            1,1,.15,.08,
            2,50,1,1,
            1,2,1,2,
            5,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Tear_X         = u_UserData0[0][0];
float Tear_Height    = u_UserData0[0][1];
float Jaggedness     = u_UserData0[0][2];
float Width          = u_UserData0[0][3];
float Edge_Glow      = u_UserData0[1][0];
float Seed           = u_UserData0[1][1];
vec3  Color          = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Void_Brightness= u_UserData0[2][1];
float Star_Density   = u_UserData0[2][2];
float Drift_Speed    = u_UserData0[2][3];
float Aspect_Ratio   = u_UserData0[3][0];

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 uv = UV;
    uv.x *= Aspect_Ratio;
    float tearXc = Tear_X * Aspect_Ratio;

    float halfH = Tear_Height * 0.5;
    float vMask = 1.0 - smoothstep( halfH, halfH + 0.05, abs( UV.y - 0.5 ) );

    float t = UV.y;
    float cell = floor( t * 10.0 );
    float cellFrac = fract( t * 10.0 );

    float n1 = hash1( cell + Seed * 13.0 ) - 0.5;
    float n2 = hash1( cell * 2.7 + 4.0 + Seed * 13.0 ) - 0.5;
    float jagA = ( n1 * 0.7 + n2 * 0.3 ) * Jaggedness;

    float n1b = hash1( cell + 1.0 + Seed * 13.0 ) - 0.5;
    float n2b = hash1( ( cell + 1.0 ) * 2.7 + 4.0 + Seed * 13.0 ) - 0.5;
    float jagB = ( n1b * 0.7 + n2b * 0.3 ) * Jaggedness;

    float jag = mix( jagA, jagB, smoothstep( 0.0, 1.0, cellFrac ) );
    float centerX = tearXc + jag + sin( CoronaTotalTime * 0.4 + t * 6.0 ) * Jaggedness * 0.15;

    float dx = uv.x - centerX;
    float dist = abs( dx );

    float slit = ( 1.0 - smoothstep( Width * 0.5, Width * 0.5 + 0.01, dist ) ) * vMask;
    float glowBand = exp( -dist * dist * ( 10.0 / max( Edge_Glow, 0.05 ) ) ) * vMask;

    vec2 starUV = vec2( dx * 40.0, t * 40.0 - CoronaTotalTime * Drift_Speed );
    vec2 starCell = floor( starUV );
    float starHash = hash1( dot( starCell, vec2( 12.9898, 78.233 ) ) + Seed * 7.0 );
    float star = step( 1.0 - Star_Density * 0.05, starHash )
               * ( 0.6 + 0.4 * sin( CoronaTotalTime * 3.0 + starHash * 30.0 ) );
    star *= slit;

    vec3 rgb = Color * glowBand * 0.9 + vec3( 1.0 ) * star * Void_Brightness + vec3( 0.02, 0.01, 0.05 ) * slit;
    float alpha = clamp( glowBand * 0.7 + slit + star, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
