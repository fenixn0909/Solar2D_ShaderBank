
--[[
    https://godotshaders.com/shader/crt-with-luminance-preservation-no-scanlines/
    Harrison Allen
    October 24, 2025
    (Public domain per the shader's own header, plus the site's CC0)

    CoronaSampler0 stands in for the original's low-res viewport
    texture - feed it a snapshot/render-texture at a resolution lower
    than your display, same as the original recommends (a CRT effect
    looks better sourced from a smaller image).

    This one needed real restructuring, not just a param cleanup: the
    original uses texelFetch() (integer pixel-coordinate texture
    access) and a switch statement with const-array-per-case - both
    are GLSL ES 3.00+ features with no equivalent in GLSL ES 1.00,
    which is what Solar2D targets. Rather than a shaky workaround:
    - The dual-scanline 6-tap horizontal/vertical blend in the
      original's sample() (built entirely on texelFetch) is replaced
      with a direct texture2D sample. You lose the soft scanline
      blending between texel rows; the phosphor mask below is the
      actual "luminance preservation" idea this shader is named for,
      and that's kept intact.
    - The 5-pattern switch/const-array mask generator is replaced with
      2 patterns (dots, grille) computed with mod() arithmetic instead
      of table lookups - same visual idea, no arrays-in-branches.
    Curve/warp, the sRGB<->linear conversion, color_offset, and the
    actual apply_mask() brightness-preservation math are all ported
    as-is - none of that needed texelFetch or switch.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "crtLuminance"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Mask_Type','Curve','Color_Offset','Mask_Brightness',
            'Aspect','','','',
            '','','','',
            '','','','',
        },
        default = { 0,0,0,1,  .75,0,0,0,  0,0,0,0,  0,0,0,0, },
        min =     { 0,0,-.5,0,  .5,0,0,0,  0,0,0,0, 0,0,0,0, },
        max =     { 1,.5,.5,1,  1,1,1,1,   1,1,1,1, 1,1,1,1, },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;

float Mask_Type       = u_UserData0[0][0];
float Curve            = u_UserData0[0][1];
float Color_Offset     = u_UserData0[0][2];
float Mask_Brightness  = u_UserData0[0][3];
float Aspect            = u_UserData0[1][0];

//----------------------------------------------

vec2 warp( vec2 uv, float aspectV, float curveV )
{
    uv -= 0.5;
    uv.x /= aspectV;
    float warping = dot( uv, uv ) * curveV;
    warping -= curveV * 0.25;
    uv /= 1.0 - warping;
    uv.x *= aspectV;
    uv += 0.5;
    return uv;
}

vec3 linear_to_srgb( vec3 col )
{
    return mix(
        ( pow( col, vec3( 1.0 / 2.4 ) ) * 1.055 ) - 0.055,
        col * 12.92,
        vec3( lessThan( col, vec3( 0.0031318 ) ) )
    );
}

vec3 srgb_to_linear( vec3 col )
{
    return mix(
        pow( ( col + 0.055 ) / 1.055, vec3( 2.4 ) ),
        col / 12.92,
        vec3( lessThan( col, vec3( 0.04045 ) ) )
    );
}

// simplified phosphor mask: 0 = dots, else = grille (formula-based, no
// lookup arrays), mask.a is the pattern's average brightness
vec4 generate_mask( vec2 fragcoord )
{
    if ( Mask_Type < 0.5 ) {
        ivec2 icoords = ivec2( fragcoord );
        int idx = ( icoords.y * 2 + icoords.x ) - ( ( ( icoords.y * 2 + icoords.x ) / 3 ) * 3 );
        vec3 col = idx == 0 ? vec3( 1.0, 0.0, 0.0 ) : ( idx == 1 ? vec3( 0.0, 1.0, 0.0 ) : vec3( 0.0, 0.0, 1.0 ) );
        return vec4( col, 0.33 );
    } else {
        int ix = int( fragcoord.x );
        int m = ix - ( ( ix / 2 ) * 2 );
        vec3 col = m == 0 ? vec3( 0.0, 1.0, 0.0 ) : vec3( 1.0, 0.0, 1.0 );
        return vec4( col, 0.5 );
    }
}

vec3 apply_mask( vec3 linear_color, vec2 fragcoord )
{
    vec4 mask = generate_mask( fragcoord );

    linear_color *= mix( mask.w, 1.0, Mask_Brightness );

    vec3 target_color = linear_color / mask.w;
    vec3 primary_col = clamp( target_color, 0.0, 1.0 );

    vec3 secondary = target_color - primary_col;
    secondary /= 1.0 / mask.w - 1.0;

    primary_col *= mask.rgb;
    primary_col += secondary * ( 1.0 - mask.rgb );

    return primary_col;
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 fragcoord = UV * CoronaTexelSize.zw;

    vec2 warped_coords = warp( UV, Aspect, Curve );

    vec3 col = texture2D( CoronaSampler0, warped_coords ).rgb;
    col = srgb_to_linear( col );

    // approximate the original's per-channel electron-beam offset with
    // a simple horizontal chromatic shift
    float rShift = texture2D( CoronaSampler0, warped_coords + vec2( -Color_Offset, 0.0 ) * CoronaTexelSize.xy ).r;
    float bShift = texture2D( CoronaSampler0, warped_coords + vec2( Color_Offset, 0.0 ) * CoronaTexelSize.xy ).b;
    col.r = mix( col.r, srgb_to_linear( vec3( rShift ) ).r, step( 0.001, abs( Color_Offset ) ) );
    col.b = mix( col.b, srgb_to_linear( vec3( bShift ) ).b, step( 0.001, abs( Color_Offset ) ) );

    col = apply_mask( col, fragcoord );
    col = linear_to_srgb( col );

    P_COLOR vec4 COLOR = vec4( col, texture2D( CoronaSampler0, warped_coords ).a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]

