--[[
    https://godotshaders.com/shader/2d-retro-dithered-lighting-fog-of-war/
    nachomakesgames
    June 23, 2026

    MIT (per post, demo at https://github.com/schweller/godot4-retro-lighting-demo).
    Includes LightingManager / LightComponent / LightObstructor GDScript
    that feeds screen-space arrays each frame - not needed here, the
    shader sampling math is the port.

    How it works (from post): samples rendered scene (hint_screen_texture)
    and re-renders per light falloff + occlusion, then ordered-dithers
    the light value (bayer8) and mixes darkness_color with scene, plus
    a glow tint.

    Adapted for Solar2D filter (CoronaSampler0 stands in for
    hint_screen_texture - feed a snapshot/render-to-texture of the scene,
    not an arbitrary sprite). Original supports 48 lights + 24 obstructors
    via GDScript-fed uniform arrays; GLES2 uniform limits and this bank's
    slider UI cannot host that. Capped here to 4 lights + 2 obstructors
    (user asked) packed into 4 mat4 blocks (64 slots) with full look
    controls kept. If you need more lights, duplicate the mat blocks and
    extend the loops - same bayer/visibility math applies.

    Physics: FRAGCOORD -> UV*iResolution (1/CoronaTexelSize.zw),
    SCREEN_UV -> UV, same as starField. Light positions / radii are in
    normalized UV space (0..1) or in pixels via iResolution scaling - here
    exposed as UV fractions (0..1 = full screen). Convert with:
        pos_uv = world_px * CoronaTexelSize.zw * iResolution
    but this port expects UV already, so slider defaults are centered
    (0.5,0.5) with radius 0.15 (~15% screen).

    Preserved: bayer2/4/8, seg_dist, visibility(), falloff
    (1-smoothstep(r*softness,r,d)), pow(light_curve), dither quantization,
    mix(darkness,scene,banded)+glow.
    Dropped: none - full feature with capped counts, same MIT terms.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "retroFog"

kernel.isTimeDependent = false

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniLook",
        paramName = {
            'Ambient','Darkness_R','Darkness_G','Darkness_B',
            'Dither_Levels','Softness','Light_Curve','Dither_Pixel_Size',
            'Light_Glow','Occlusion_Enabled','Light_Count','Obstructor_Count',
            '','','','',
        },
        default = {
            .05, .02, .02, .06,
            6, .30, 1.6, 2,
            .15, 1, 2, 1,
            0,0,0,0,
        },
        min = {
            0, 0,0,0,
            1, 0, .3, 1,
            0, 0, 0, 0,
            0,0,0,0,
        },
        max = {
            1, 1,1,1,
            16, 1, 3, 6,
            1, 1, 4, 2,
            1,1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniLightPos",
        paramName = {
            'L1_X','L1_Y','L1_Radius','L1_Intensity',
            'L2_X','L2_Y','L2_Radius','L2_Intensity',
            'L3_X','L3_Y','L3_Radius','L3_Intensity',
            'L4_X','L4_Y','L4_Radius','L4_Intensity',
        },
        default = {
            .50, .50, .18, 1,
            .25, .35, .12, .85,
            .75, .35, .12, .85,
            .50, .75, .14, .90,
        },
        min = {
            0,0, .01, 0,
            0,0, .01, 0,
            0,0, .01, 0,
            0,0, .01, 0,
        },
        max = {
            1,1, .50, 2,
            1,1, .50, 2,
            1,1, .50, 2,
            1,1, .50, 2,
        },
    },
    {
        index = 2,
        type = "mat4",
        name = "uniLightColor",
        paramName = {
            'L1_R','L1_G','L1_B','',
            'L2_R','L2_G','L2_B','',
            'L3_R','L3_G','L3_B','',
            'L4_R','L4_G','L4_B','',
        },
        default = {
            1, 1, 1, 0,
            1, .95, .85, 0,
            .85, .95, 1, 0,
            1, 1, 1, 0,
        },
        min = {
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
            1,1,1,1,
        },
    },
    {
        index = 3,
        type = "mat4",
        name = "uniObstruct",
        paramName = {
            'O1_X','O1_Y','O1_Radius','',
            'O2_X','O2_Y','O2_Radius','',
            '','','','',
            '','','','',
        },
        default = {
            .50, .30, .06, 0,
            .50, .65, .07, 0,
            0,0,0,0,
            0,0,0,0,
        },
        min = {
            0,0, .01, 0,
            0,0, .01, 0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,1, .30, 1,
            1,1, .30, 1,
            1,1,1,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
uniform P_COLOR mat4 u_UserData2;
uniform P_COLOR mat4 u_UserData3;
//----------------------------------------------

float Ambient             = u_UserData0[0][0];
vec3  Darkness_Color      = vec3( u_UserData0[0][1], u_UserData0[0][2], u_UserData0[0][3] );
float Dither_Levels       = u_UserData0[1][0];
float Softness            = u_UserData0[1][1];
float Light_Curve         = u_UserData0[1][2];
float Dither_Pixel_Size   = u_UserData0[1][3];
float Light_Glow          = u_UserData0[2][0];
float Occlusion_Enabled   = u_UserData0[2][1];
float Light_Count         = u_UserData0[2][2];
float Obstructor_Count    = u_UserData0[2][3];

vec2  L1_Pos  = vec2( u_UserData1[0][0], u_UserData1[0][1] );
float L1_Radius = u_UserData1[0][2];
float L1_Intensity = u_UserData1[0][3];
vec2  L2_Pos  = vec2( u_UserData1[1][0], u_UserData1[1][1] );
float L2_Radius = u_UserData1[1][2];
float L2_Intensity = u_UserData1[1][3];
vec2  L3_Pos  = vec2( u_UserData1[2][0], u_UserData1[2][1] );
float L3_Radius = u_UserData1[2][2];
float L3_Intensity = u_UserData1[2][3];
vec2  L4_Pos  = vec2( u_UserData1[3][0], u_UserData1[3][1] );
float L4_Radius = u_UserData1[3][2];
float L4_Intensity = u_UserData1[3][3];

vec3  L1_Color = vec3( u_UserData2[0][0], u_UserData2[0][1], u_UserData2[0][2] );
vec3  L2_Color = vec3( u_UserData2[1][0], u_UserData2[1][1], u_UserData2[1][2] );
vec3  L3_Color = vec3( u_UserData2[2][0], u_UserData2[2][1], u_UserData2[2][2] );
vec3  L4_Color = vec3( u_UserData2[3][0], u_UserData2[3][1], u_UserData2[3][2] );

vec2  O1_Pos = vec2( u_UserData3[0][0], u_UserData3[0][1] );
float O1_Radius = u_UserData3[0][2];
vec2  O2_Pos = vec2( u_UserData3[1][0], u_UserData3[1][1] );
float O2_Radius = u_UserData3[1][2];

const int MAX_LIGHTS = 4;
const int MAX_OBSTRUCTORS = 2;

P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;

//----------------------------------------------

float bayer2( vec2 a )
{
    a = floor( a );
    return fract( a.x * 0.5 + a.y * a.y * 0.75 );
}
float bayer4( vec2 a )
{
    return bayer2( 0.5 * a ) * 0.25 + bayer2( a );
}
float bayer8( vec2 a )
{
    return bayer4( 0.5 * a ) * 0.25 + bayer4( a );
}

float seg_dist( vec2 p, vec2 a, vec2 b )
{
    vec2 ab = b - a;
    float t = clamp( dot( p - a, ab ) / max( dot( ab, ab ), 0.0001 ), 0.0, 1.0 );
    return distance( p, a + ab * t );
}

float visibility( vec2 frag, vec2 lpos )
{
    if ( Occlusion_Enabled < 0.5 ) return 1.0;
    int oCount = int( Obstructor_Count );
    // O1
    if ( oCount >= 1 ) {
        if ( !( distance( frag, O1_Pos ) < O1_Radius ) ) {
            if ( seg_dist( O1_Pos, frag, lpos ) < O1_Radius ) return 0.0;
        }
    }
    // O2
    if ( oCount >= 2 ) {
        if ( !( distance( frag, O2_Pos ) < O2_Radius ) ) {
            if ( seg_dist( O2_Pos, frag, lpos ) < O2_Radius ) return 0.0;
        }
    }
    return 1.0;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // frag in normalized UV space (0..1) - original uses FRAGCOORD.xy in pixels
    // Convert light positions/radii from UV to pixel space for correct falloff scaling
    // but keep math scale-invariant by using UV distances directly.
    vec2 frag = UV;
    // For radius, treat slider's 0..0.5 as fraction of screen diagonal; use directly in UV space
    vec3 scene = texture2D( CoronaSampler0, UV ).rgb;

    float lit = Ambient;
    vec3 glow = vec3( 0.0 );

    int lCount = int( Light_Count );

    // Light 1
    if ( lCount >= 1 ) {
        float r = max( L1_Radius, 0.001 );
        float d = distance( frag, L1_Pos );
        float falloff = 1.0 - smoothstep( r * Softness, r, d );
        if ( falloff > 0.0 ) {
            falloff *= visibility( frag, L1_Pos );
            float contrib = falloff * L1_Intensity;
            lit += contrib;
            glow += L1_Color * contrib;
        }
    }
    // Light 2
    if ( lCount >= 2 ) {
        float r = max( L2_Radius, 0.001 );
        float d = distance( frag, L2_Pos );
        float falloff = 1.0 - smoothstep( r * Softness, r, d );
        if ( falloff > 0.0 ) {
            falloff *= visibility( frag, L2_Pos );
            float contrib = falloff * L2_Intensity;
            lit += contrib;
            glow += L2_Color * contrib;
        }
    }
    // Light 3
    if ( lCount >= 3 ) {
        float r = max( L3_Radius, 0.001 );
        float d = distance( frag, L3_Pos );
        float falloff = 1.0 - smoothstep( r * Softness, r, d );
        if ( falloff > 0.0 ) {
            falloff *= visibility( frag, L3_Pos );
            float contrib = falloff * L3_Intensity;
            lit += contrib;
            glow += L3_Color * contrib;
        }
    }
    // Light 4
    if ( lCount >= 4 ) {
        float r = max( L4_Radius, 0.001 );
        float d = distance( frag, L4_Pos );
        float falloff = 1.0 - smoothstep( r * Softness, r, d );
        if ( falloff > 0.0 ) {
            falloff *= visibility( frag, L4_Pos );
            float contrib = falloff * L4_Intensity;
            lit += contrib;
            glow += L4_Color * contrib;
        }
    }

    lit = clamp( lit, 0.0, 1.0 );
    lit = pow( lit, Light_Curve );

    vec2 dcoord = floor( UV * iResolution / max( Dither_Pixel_Size, 1.0 ) );
    float bayer = bayer8( dcoord );
    float banded = clamp( floor( lit * Dither_Levels + bayer ) / max( Dither_Levels, 1.0 ), 0.0, 1.0 );

    vec3 outc = mix( Darkness_Color, scene, banded );
    outc += glow * banded * Light_Glow;

    P_COLOR vec4 COLOR = vec4( outc, 1.0 );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
--]]
