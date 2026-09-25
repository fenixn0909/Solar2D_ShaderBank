
--[[
    Original implementation for this bank. Modeled on the "cracked /
    damage overlay" sprite-FX category (e.g. the 2DFX suite's Cracked
    Overlay and similar Unity 2D damage packs: dark fissures spread as
    the target takes hits, often with a hot ember rim) - nothing was
    copied from any of them (all paid, closed-source); this
    reimplements the same feature list as a plain fragment kernel: a
    single-scale procedural Voronoi field (3x3 cell search, GLES2-safe
    constant loop bounds like this bank's frostbite port) supplies the
    fissure lines (F2-F1 ridge), Damage grows them outward from the
    cell seeds, cracks render near-black with an ember Glow band
    hugging each lip, and everything is masked by the sprite's own
    alpha so empty areas stay clean.

    Checked against all existing kernels first: frostbite has Voronoi
    ice cells but no damage-crack overlay; turnToDust/dissolve remove
    pixels rather than drawing fissures over them.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "crackOverlay"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Damage','Cells','Crack_Width','Glow_Width',
            'Glow_R','Glow_G','Glow_B','Glow_Boost',
            'Crack_Dark','Jitter','Aspect_Ratio','',
            '','','','',
        },
        default = {
            .6,7,.06,.12,
            1,.35,.08,1.6,
            .85,.9,1,0,
            0,0,0,0,
        },
        min = {
            0,2,.005,.0,
            0,0,0,0,
            0,0,.2,0,
            0,0,0,0,
        },
        max = {
            1,16,.25,.5,
            2,2,2,3,
            1,1,5,1,
            1,1,1,1,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Damage       = u_UserData0[0][0];
float Cells        = u_UserData0[0][1];
float Crack_Width  = u_UserData0[0][2];
float Glow_Width   = u_UserData0[0][3];
vec3  Glow_Color   = vec3( u_UserData0[1][0], u_UserData0[1][1], u_UserData0[1][2] );
float Glow_Boost   = u_UserData0[1][3];
float Crack_Dark   = u_UserData0[2][0];
float Jitter       = u_UserData0[2][1];
float Aspect_Ratio = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM vec2 crack_hash2( vec2 p )
{
    vec3 p3 = fract( vec3( p.xyx ) * vec3( 0.1031, 0.1030, 0.0973 ) );
    p3 += dot( p3, p3.yzx + 33.33 );
    return fract( ( p3.xx + p3.yz ) * p3.zy );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV );

    vec2 aspectVec = vec2( 1.0, Aspect_Ratio );
    vec2 gp = UV * Cells * aspectVec;
    vec2 ip = floor( gp );
    vec2 fp = fract( gp );

    float f1 = 8.0;
    float f2 = 8.0;
    for ( int j = -1; j <= 1; j++ ) {
        for ( int i = -1; i <= 1; i++ ) {
            vec2 g = vec2( float( i ), float( j ) );
            vec2 o = crack_hash2( ip + g );
            vec2 r = g + mix( vec2( 0.5 ), o, clamp( Jitter, 0.0, 1.0 ) ) - fp;
            float d = dot( r, r );
            if ( d < f1 ) { f2 = f1; f1 = d; }
            else if ( d < f2 ) { f2 = d; }
        }
    }
    f1 = sqrt( f1 );
    f2 = sqrt( f2 );
    float ridge = f2 - f1;

    float crackLine = 1.0 - smoothstep( Crack_Width * 0.5, Crack_Width, ridge );
    float glowBand = ( 1.0 - smoothstep( Crack_Width, Crack_Width + Glow_Width, ridge ) ) - crackLine;

    float spread = smoothstep( Damage + 0.12, Damage - 0.12, f1 );

    float crackMask = crackLine * spread * step( 0.001, tex.a );
    float glowMask = clamp( glowBand, 0.0, 1.0 ) * spread * step( 0.001, tex.a );

    vec3 cracked = mix( tex.rgb, vec3( 0.0 ), crackMask * Crack_Dark );
    cracked += Glow_Color * ( glowMask * Glow_Boost );

    P_COLOR vec4 COLOR = vec4( cracked, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
