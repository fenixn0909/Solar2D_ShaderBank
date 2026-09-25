
--[[
    Original implementation for this bank. Modeled on the "freeze /
    frozen solid" character-transform category from commercial
    character shader bundles - nothing was copied from any of them
    (all paid, closed-source). Unlike a screen-space frost filter, this
    works directly in the sprite's own UV space so it can be dropped
    straight onto a character display object: a jittered freeze-line
    climbs from the bottom (UV.y, this bank's normal 0-top/1-bottom
    convention) as Progress rises, a small 3x3 Voronoi cell search
    (same GLES2-safe constant-bound pattern as this bank's crackOverlay
    and its frostbite port) gives the ice its crystalline cell texture
    within the frozen region, and the character's own colors dim
    underneath the pale, faintly-sparkling ice tint.

    Checked against all existing kernels first: kernelF_FX_frostbite's
    own header says outright it expects "a snapshot/render-to-texture
    of what should frost over" - it's built for a screen-space capture,
    not a single sprite's own UV space, and its superellipse vignette
    grows from the *frame edges* inward rather than bottom-to-top on a
    character; kernelG_FX_icicleDrip/iceShardBurst are standalone
    generators (hanging icicles, a radial burst), not a full-body
    encasement driven by a sprite's own silhouette. None overlap.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "iceEncasementFreeze"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Progress','Cell_Scale','Edge_Jag','Ice_R',
            'Ice_G','Ice_B','Highlight_R','Highlight_G',
            'Highlight_B','Sparkle_Speed','Dim_Amount','Opacity',
            '','','','',
        },
        default = {
            0,16,.12,.65,
            .85,1,.9,.97,
            1,3,.45,1,
            0,0,0,0,
        },
        min = {
            0,4,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            1,32,.3,1,
            1,1,1,1,
            1,8,.8,1,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Progress       = u_UserData0[0][0];
float Cell_Scale     = u_UserData0[0][1];
float Edge_Jag       = u_UserData0[0][2];
vec3  Ice_Color      = vec3( u_UserData0[0][3], u_UserData0[1][0], u_UserData0[1][1] );
vec3  Highlight      = vec3( u_UserData0[1][2], u_UserData0[1][3], u_UserData0[2][0] );
float Sparkle_Speed  = u_UserData0[2][1];
float Dim_Amount     = u_UserData0[2][2];
float Opacity        = u_UserData0[2][3];

//----------------------------------------------

P_RANDOM float ice_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 71.3, 19.7 ) ) ) * 43758.5453123 );
}

float ice_cell( vec2 p )
{
    vec2 base = floor( p );
    float f1 = 8.0;
    float f2 = 8.0;

    for ( int oy = -1; oy <= 1; oy++ )
    {
        for ( int ox = -1; ox <= 1; ox++ )
        {
            vec2 cell = base + vec2( float( ox ), float( oy ) );
            vec2 pt = cell + vec2( ice_hash( cell ), ice_hash( cell + 17.0 ) );
            float d = length( p - pt );
            if ( d < f1 ) { f2 = f1; f1 = d; }
            else if ( d < f2 ) { f2 = d; }
        }
    }
    return f2 - f1;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    float edgeNoise = ( ice_hash( floor( UV * Cell_Scale * 3.0 ) ) - 0.5 ) * Edge_Jag;
    float freezeLine = 1.0 - Progress + edgeNoise;
    float coverage = 1.0 - smoothstep( freezeLine - 0.05, freezeLine + 0.05, UV.y );

    float cellPattern = ice_cell( UV * Cell_Scale );
    float crystalLine = smoothstep( 0.06, 0.0, cellPattern );
    float sparkle = 0.5 + 0.5 * sin( CoronaTotalTime * Sparkle_Speed + cellPattern * 40.0 );

    vec3 dimmed = tex.rgb * ( 1.0 - Dim_Amount * coverage );
    vec3 iceLayer = mix( Ice_Color, Highlight, crystalLine * sparkle );
    vec3 finalRGB = mix( dimmed, iceLayer, coverage * 0.6 );

    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
