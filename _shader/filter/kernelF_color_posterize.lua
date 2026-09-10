--[[
  Posterize (reduce colors) with master + per-channel levels,
  ordered Bayer dither, blend and pixelize.

  Method: simple floor per channel
    N_eff = clamp(floor(Levels * Mul + 0.5), 2, 32)
    post = floor(c * (N-1) + 0.5 + (bayer-0.5) * Dither) / (N-1)

  Using (N-1) gives exactly N tones per channel (Levels=2 -> black/white),
  vs floor(c*N)/N which yields N+1 tones.

  PixW/PixH: int 1-32, 1 = off. 4 = 4x4 blocks = 1/4 res, pixel-perfect
  when the image is shrunk to 1/4 width/height. Center sampling, blocky
  Bayer dither follows the pixelated blocks.

  Creator: phoenixongogo, 2026 Sep.       License: MIT
--]]

local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "posterize"

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Levels','Levels_R','Levels_G','Levels_B',
            'Dither','Blend','PixW','PixH',
            '','','','',
            '','','','',
        },
        default = { 4,1,1,1,  0.25,1,1,1,  0,0,0,0,  0,0,0,0, },
        min =     { 2,0.25,0.25,0.25,  0,0,1,1,  0,0,0,0,  0,0,0,0, },
        max =     { 16,2,2,2,  1,1,32,32,  1,1,1,1,  1,1,1,1, },
    },
}

kernel.fragment =
[[
uniform P_COLOR mat4 u_UserData0;

float Levels   = u_UserData0[0][0];
float Lv_R_mul = u_UserData0[0][1];
float Lv_G_mul = u_UserData0[0][2];
float Lv_B_mul = u_UserData0[0][3];
float Dither   = u_UserData0[1][0];
float Blend    = u_UserData0[1][1];
float PixW     = u_UserData0[1][2];
float PixH     = u_UserData0[1][3];

P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;

const mat4 BAYER4 = mat4(
    vec4(0.0, 12.0, 3.0, 15.0),
    vec4(8.0, 4.0, 11.0, 7.0),
    vec4(2.0, 14.0, 1.0, 13.0),
    vec4(10.0, 6.0, 9.0, 5.0)
);

float bayer4( vec2 pixel )
{
    ivec2 p = ivec2( mod( pixel, 4.0 ) );
    return BAYER4[p.x][p.y] / 16.0;
}

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_UV vec2 UV = texCoord;
    P_UV vec2 texel = CoronaTexelSize.zw;

    float pw = clamp( floor( PixW + 0.5 ), 1.0, 32.0 );
    float ph = clamp( floor( PixH + 0.5 ), 1.0, 32.0 );

    // Pixelize: snap to block center per axis, 1 = off (keep original UV).
    P_UV vec2 pixUV = UV;
    if ( pw > 1.5 )
    {
        float bx = pw * texel.x;
        pixUV.x = ( floor( UV.x / bx ) + 0.5 ) * bx;
    }
    if ( ph > 1.5 )
    {
        float by = ph * texel.y;
        pixUV.y = ( floor( UV.y / by ) + 0.5 ) * by;
    }
    vec4 orig = texture2D( CoronaSampler0, pixUV );

    float baseLv = clamp( Levels, 2.0, 16.0 );
    float nR = clamp( floor( baseLv * Lv_R_mul + 0.5 ), 2.0, 32.0 );
    float nG = clamp( floor( baseLv * Lv_G_mul + 0.5 ), 2.0, 32.0 );
    float nB = clamp( floor( baseLv * Lv_B_mul + 0.5 ), 2.0, 32.0 );
    vec3 steps = vec3( nR - 1.0, nG - 1.0, nB - 1.0 );

    // Blocky Bayer: one dither value per pixel Block, so it stays
    // pixel-perfect when shrunk. pw=ph=1 falls back to per-pixel.
    vec2 pixel = UV * iResolution;
    vec2 blockIdx = floor( pixel / vec2( pw, ph ) );
    float b = bayer4( blockIdx ) - 0.5; // -0.5 .. ~0.44
    vec3 dith = vec3( b * Dither );

    vec3 post;
    post.r = floor( orig.r * steps.r + 0.5 + dith.r ) / steps.r;
    post.g = floor( orig.g * steps.g + 0.5 + dith.g ) / steps.g;
    post.b = floor( orig.b * steps.b + 0.5 + dith.b ) / steps.b;

    vec3 mixed = mix( orig.rgb, post, clamp( Blend, 0.0, 1.0 ) );

    P_COLOR vec4 COLOR = vec4( mixed, orig.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel
