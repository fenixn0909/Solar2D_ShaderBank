
--[[
    Original implementation for this bank. Dreamy drifting bokeh -
    soft, warm/cool-tinted circular light discs with a gaussian
    falloff (not hard-edged point sprites), placed via a jittered-grid
    hash and sampled across a 3x3 neighborhood so discs can drift
    smoothly across cell borders without popping (same tap-budget
    class as this bank's existing 3x3 Voronoi searches). Two layers at
    different scale/speed give a cheap depth parallax. Meant as a
    standalone dreamy backdrop for menus, loading screens or visual-
    novel scenes - optional flat BG tint underneath via BG_Alpha, or
    leave it fully transparent to drift over existing art.

    Checked against all existing kernels first: kernelG_BG_starField/
    starryNight/starryTunnel and kernelG_FX_fireflyDrift all place
    small hard or point-like glowing dots; kernelF_blur_tiltShift blurs
    an *existing* input image rather than generating soft discs from
    nothing. None combine gaussian-falloff circles, per-disc color
    variety and multi-layer drift the way this does.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "bokehDrift"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Cell_Size','Drift_Speed','Size_Min','Size_Max',
            'Far_Scale','Far_Brightness','Twinkle_Speed','BG_R',
            'BG_G','BG_B','BG_Alpha','',
            '','','','',
        },
        default = {
            .22,.03,.05,.16,
            2.2,.45,.6,.04,
            .05,.09,0,0,
            0,0,0,0,
        },
        min = {
            .05,-.2,.01,.02,
            1,0,0,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            .6,.2,.2,.4,
            4,1,3,1,
            1,1,1,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Cell_Size      = u_UserData0[0][0];
float Drift_Speed    = u_UserData0[0][1];
float Size_Min       = u_UserData0[0][2];
float Size_Max       = u_UserData0[0][3];
float Far_Scale      = u_UserData0[1][0];
float Far_Brightness = u_UserData0[1][1];
float Twinkle_Speed  = u_UserData0[1][2];
vec3  BG_Color       = vec3( u_UserData0[1][3], u_UserData0[2][0], u_UserData0[2][1] );
float BG_Alpha       = u_UserData0[2][2];

//----------------------------------------------

P_RANDOM float bokeh_hash( vec2 p )
{
    return fract( sin( dot( p, vec2( 269.5, 183.3 ) ) ) * 43758.5453123 );
}

vec4 bokeh_layer( vec2 uv, float cellSize, float speed, float seed, float brightness )
{
    vec2 scaledUV = uv / cellSize;
    scaledUV.y -= CoronaTotalTime * speed / cellSize;
    vec2 baseCell = floor( scaledUV );

    vec4 best = vec4( 0.0 );

    for ( int oy = -1; oy <= 1; oy++ )
    {
        for ( int ox = -1; ox <= 1; ox++ )
        {
            vec2 cell = baseCell + vec2( float( ox ), float( oy ) );
            float h1 = bokeh_hash( cell + seed );
            float h2 = bokeh_hash( cell + seed + vec2( 13.0, 7.0 ) );
            float h3 = bokeh_hash( cell + seed + vec2( 47.0, 29.0 ) );
            float h4 = bokeh_hash( cell + seed + vec2( 91.0, 61.0 ) );

            vec2 cellCenter = cell + vec2( 0.15 + 0.7 * h1, 0.15 + 0.7 * h2 );
            float size = mix( Size_Min, Size_Max, h3 ) / cellSize;
            float d = length( scaledUV - cellCenter );
            float disc = exp( -( d * d ) / max( size * size, 0.0001 ) * 3.0 );

            vec3 warm = vec3( 1.0, 0.82, 0.55 );
            vec3 cool = vec3( 0.55, 0.75, 1.0 );
            vec3 tint = mix( cool, warm, h4 );

            float twinkle = 0.7 + 0.3 * sin( CoronaTotalTime * Twinkle_Speed + h1 * 20.0 );
            float a = disc * twinkle * brightness;

            if ( a > best.a )
            {
                best = vec4( tint * a, a );
            }
        }
    }

    return best;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec4 near = bokeh_layer( UV, Cell_Size, Drift_Speed, 5.0, 1.0 );
    vec4 far = bokeh_layer( UV, Cell_Size * Far_Scale, Drift_Speed * 0.5, 71.0, Far_Brightness );

    vec3 rgb = BG_Color * BG_Alpha + far.rgb + near.rgb;
    float alpha = clamp( BG_Alpha + far.a + near.a, 0.0, 1.0 );

    P_COLOR vec4 COLOR = vec4( rgb, alpha );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
