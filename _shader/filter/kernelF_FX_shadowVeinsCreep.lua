
--[[
    Original implementation for this bank. Reuses the "distance to a
    noise-displaced line" bolt technique from this batch's own
    kernelG_FX_chainLightningArc.lua, but fired outward from a single
    Origin point in several independent hashed directions rather than
    between two fixed endpoints, tapering in width and gated by a Spread
    progress value (0-1, drive it from your own corruption/poison/curse
    timer) rather than time directly - deliberately a different technique
    from this bank's Voronoi-cell-based creep effects
    (kernelF_FX_frostbite.lua, kernelF_FX_crackOverlay.lua,
    kernelG_FX_moltenCracks.lua) so this batch isn't leaning on one single
    trick for every "spreading" effect.

    Single-texture filter, tints existing art with dark pulsing veins
    rather than replacing it - a curse mark, poison spread, or void
    corruption creeping across a character or object.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "shadowVeinsCreep"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Origin_X','Origin_Y','Spread','Vein_Count',
            'Jaggedness','Vein_Width','Pulse_Speed','Color_R',
            'Color_G','Color_B','Aspect_Ratio','',
            '','','','',
        },
        default = {
            .5,.5,.5,6,
            .15,.008,2,.25,
            .05,.35,1,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,.002,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,1,1,8,
            .4,.03,6,1,
            1,1,5,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Origin_X     = u_UserData0[0][0];
float Origin_Y     = u_UserData0[0][1];
float Spread       = u_UserData0[0][2];
float Vein_Count   = u_UserData0[0][3];
float Jaggedness   = u_UserData0[1][0];
float Vein_Width   = u_UserData0[1][1];
float Pulse_Speed  = u_UserData0[1][2];
vec3  Color        = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float Aspect_Ratio = u_UserData0[2][2];

const int VEIN_MAX = 8;

P_RANDOM float hash1( float seedVal )
{
    return fract( sin( seedVal ) * 43758.5453123 );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 src = texture2D( CoronaSampler0, UV );

    vec2 uv = UV;
    uv.x *= Aspect_Ratio;
    vec2 originS = vec2( Origin_X * Aspect_Ratio, Origin_Y );

    float total = 0.0;

    for ( int veinIndex = 0; veinIndex < VEIN_MAX; veinIndex++ ) {
        float active = step( float( veinIndex ) + 0.5, Vein_Count );
        float fi = float( veinIndex );

        float baseAngle = hash1( fi * 3.7 + 1.0 ) * 6.28318;
        float veinLen = Spread * ( 0.5 + 0.5 * hash1( fi * 5.1 ) );

        vec2 dir = vec2( cos( baseAngle ), sin( baseAngle ) );
        vec2 nrm = vec2( -dir.y, dir.x );
        vec2 toPixel = uv - originS;

        float alongDir = dot( toPixel, dir );
        float perpDir = dot( toPixel, nrm );

        float t = clamp( alongDir / max( veinLen, 0.001 ), 0.0, 1.0 );
        float cell = floor( t * 8.0 );
        float n = ( hash1( cell + fi * 13.0 ) - 0.5 ) * Jaggedness * veinLen * sin( t * 3.14159265 );

        float dist = abs( perpDir - n );
        float width = Vein_Width * ( 1.0 - t * 0.6 );
        float veinLine = ( 1.0 - smoothstep( 0.0, max( width, 0.001 ), dist ) ) * step( 0.0, alongDir ) * step( alongDir, veinLen );

        total = max( total, active * veinLine );
    }

    float pulse = 1.0 + sin( CoronaTotalTime * Pulse_Speed ) * 0.3;
    vec3 veinColor = Color * pulse;

    vec3 rgb = mix( src.rgb, veinColor, total * src.a );

    P_COLOR vec4 COLOR = vec4( rgb, src.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
