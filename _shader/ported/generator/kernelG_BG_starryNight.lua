--[[
    https://godotshaders.com/shader/starry-night/
    latchina36@stirlingschools.net
    June 17, 2026

    Shader type: canvas_item (generator). CC0.

    Main stars (grid-snapped, multi-octave by starIterations) +
    background scintillation stars, both tinted via a 1D gradient.
    Original uses two sampler2D gradients (gradientA for main stars,
    gradientB for bg stars) sampled via texture(gradient, vec2(t)).
    Solar2D generators have no custom sampler slots, and a composite
    would only give two (CoronaSampler0/1) while this shader would need
    TEXTURE + two gradients. To stay self-contained, gradients are baked
    here as two-stop uniform lerp colors (GradA_Start/End, GradB_Start/
    End) sampled via mix(), which visually matches an arbitrary gradient
    when the gradient is a simple ramp - and is trivial to edit.

    Hybrid note (answers user's choice): if you have authored gradient
    strip textures and prefer them, change this kernel's category to
    "composite", set paint2 to your gradientA strip, add a second
    lookup via CoronaSampler1, and replace the two mix() calls below
    with:
        vec4 colormapA = texture2D(CoronaSampler1, vec2(remapped));
        vec4 colormapB = texture2D(CoronaSampler1, vec2(r));
    Or pack both gradients into one atlas and sample by y. The logic
    around remap(prob, starValue) and r is kept verbatim so the swap
    is one line.

    Other adaptations:
    - FRAGCOORD -> fragCoord = UV * iResolution (1/CoronaTexelSize.zw),
      SCREEN_UV -> UV, TIME -> CoronaTotalTime, same as this bank's
      starField/stars generators.
    - starIterations drives a compile-time-constant loop (MAX_ITER = 10)
      with early break (GLES2-safe; original uses uniform as bound).
    - Seed is exposed (original uniform seed) so background star pattern
      can be de-correlated from main stars if you run two instances.
--]]

local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "BG"
kernel.name = "starryNight"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Horizontal_Movement','Vertical_Movement','Frequency_Star','Size_Star',
            'Brightness_Star','Shine_Frequency_Star','Transparency_Star','Star_Iterations',
            'Frequency_Bg_Star','Shine_Frequency_Bg_Star','Transparency_Bg_Star','Transparency_Bg',
            'Seed','', '', '',
        },
        default = {
            .1, .1, .1, 100,
            3, 8, 0, 3,
            .996, 1, 0, 0,
            0, 0,0,0,
        },
        min = {
            -2, -2, 0, 10,
            1, 1, 0, 1,
            .95, 0, 0, 0,
            0, 0,0,0,
        },
        max = {
            2, 2, 1, 200,
            5, 20, 1, 10,
            1, 5, 1, 1,
            100, 1,1,1,
        },
    },
    {
        index = 1,
        type = "mat4",
        name = "uniColor",
        paramName = {
            'Bg_R','Bg_G','Bg_B','',
            'GradA_Start_R','GradA_Start_G','GradA_Start_B','GradA_Start_A',
            'GradA_End_R','GradA_End_G','GradA_End_B','GradA_End_A',
            'GradB_Start_R','GradB_Start_G','GradB_Start_B','GradB_Start_A',
        },
        default = {
            .05, .04, .20, 0,
            1, 1, 1, 1,
            1, .90, .60, 1,
            .60, .75, 1, 1,
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
        index = 2,
        type = "mat4",
        name = "uniColor2",
        paramName = {
            'GradB_End_R','GradB_End_G','GradB_End_B','GradB_End_A',
            '','','','',
            '','','','',
            '','','','',
        },
        default = {
            1, 1, 1, 1,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
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
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
uniform P_COLOR mat4 u_UserData1;
uniform P_COLOR mat4 u_UserData2;
//----------------------------------------------

float Horizontal_Movement      = u_UserData0[0][0];
float Vertical_Movement        = u_UserData0[0][1];
float Frequency_Star           = u_UserData0[0][2];
float Size_Star                = u_UserData0[0][3];
float Brightness_Star          = u_UserData0[1][0];
float Shine_Frequency_Star     = u_UserData0[1][1];
float Transparency_Star        = u_UserData0[1][2];
float Star_Iterations          = u_UserData0[1][3];
float Frequency_Bg_Star        = u_UserData0[2][0];
float Shine_Frequency_Bg_Star  = u_UserData0[2][1];
float Transparency_Bg_Star     = u_UserData0[2][2];
float Transparency_Bg          = u_UserData0[2][3];
float Seed                     = u_UserData0[3][0];

vec3 Bg_Color          = vec3( u_UserData1[0][0], u_UserData1[0][1], u_UserData1[0][2] );
vec4 GradA_Start       = vec4( u_UserData1[1][0], u_UserData1[1][1], u_UserData1[1][2], u_UserData1[1][3] );
vec4 GradA_End         = vec4( u_UserData1[2][0], u_UserData1[2][1], u_UserData1[2][2], u_UserData1[2][3] );
vec4 GradB_Start       = vec4( u_UserData1[3][0], u_UserData1[3][1], u_UserData1[3][2], u_UserData1[3][3] );
vec4 GradB_End         = vec4( u_UserData2[0][0], u_UserData2[0][1], u_UserData2[0][2], u_UserData2[0][3] );

float TIME = CoronaTotalTime;
P_UV vec2 iResolution = 1.0 / CoronaTexelSize.zw;

//----------------------------------------------

float rand( vec2 st )
{
    return fract( sin( dot( st.xy, vec2( Seed + 12.9898, 78.233 ) ) ) * 43758.5453123 );
}

float remap( float prob, float starValue )
{
    return ( starValue - prob ) / ( 1.0 - prob );
}

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    P_UV vec2 fragCoord = UV * iResolution;
    P_UV vec2 screenUV = UV;

    float prob = 1.0 - Frequency_Star;
    float travelx = TIME * Horizontal_Movement;
    float travely = TIME * Vertical_Movement;

    P_COLOR vec4 COLOR = vec4( Bg_Color, 1.0 - Transparency_Bg );

    const int MAX_ITER = 10;
    int iter_i = int( Star_Iterations );

    for ( int i = 1; i <= MAX_ITER; i++ ) {
        if ( i > iter_i ) break;
        float fi = float( i );
        float size = Size_Star / fi;
        if ( size < 1.0 ) continue;
        vec2 pos = vec2( floor( ( 1.0 / size * fragCoord.x ) + travelx ), floor( ( 1.0 / size * fragCoord.y ) + travely ) );
        float starValue = rand( pos );

        if ( starValue > prob )
        {
            vec2 center = size * pos + vec2( size, size ) * 0.5;
            float t = 0.9 + 0.2 * sin( TIME * Shine_Frequency_Star + ( starValue - prob ) / ( 1.0 - prob ) * 45.0 );
            vec2 modifiedCoords = vec2( fragCoord.x + travelx * size, fragCoord.y + travely * size );
            float c = 1.0 - distance( modifiedCoords, center ) / ( 0.5 * size );
            // original divides by clamped distances to create cross glare
            float denomY = clamp( distance( modifiedCoords.y, center.y ), 0.5, size * 0.5 - 1.0 );
            float denomX = clamp( distance( modifiedCoords.x, center.x ), 0.5, size * 0.5 - 1.0 );
            c = t * t * Brightness_Star / fi / denomY / denomX;
            // clamp to avoid extreme spikes at very small size
            c = clamp( c, 0.0, 4.0 );

            float remapped = remap( prob, starValue );
            // hybrid: uniform lerp stands in for texture(gradientA, vec2(remapped))
            // uncomment next line and comment following mix() to use a texture gradient:
            // vec4 colormapA = texture2D( CoronaSampler0, vec2( remapped, 0.5 ) );
            vec4 colormapA = mix( GradA_Start, GradA_End, clamp( remapped, 0.0, 1.0 ) );
            COLOR += colormapA * c * ( 1.0 - Transparency_Star );
        }
    }

    if ( rand( screenUV.xy / 20.0 ) > Frequency_Bg_Star )
    {
        float r = rand( screenUV.xy );
        float bg = r * ( 0.85 * sin( TIME * Shine_Frequency_Bg_Star * ( r * 5.0 ) + 720.0 * r ) + 0.95 );
        // vec4 colormapB = texture2D( CoronaSampler0, vec2( r, 0.5 ) );
        vec4 colormapB = mix( GradB_Start, GradB_End, clamp( r, 0.0, 1.0 ) );
        COLOR += bg * colormapB * ( 1.0 - Transparency_Bg_Star );
    }

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[
--]]
