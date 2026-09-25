
--[[
    Original implementation for this bank. Makes existing art read as
    seen through water: a two-frequency sine wobble refracts the
    sampled UV before anything else happens (so the distortion applies
    to the real image, not an overlay), a blue-green tint mix follows,
    then a scrolling interference-pattern caustic net (crossed sine
    fields, the standard cheap caustic approximation) is added on top
    to catch highlights the way real underwater light does.

    Checked against all existing kernels first: kernelG_water_
    caustics2D is a *generator* - it draws caustic light on its own
    with no input texture at all, meant as a standalone water-surface
    background. This is the opposite case: a filter that recolors and
    refracts *existing* sprite/tile art (a character, a room) so it
    reads as if submerged, with the caustic net layered on top of that
    real content rather than replacing it. Different sampler
    dependency and different use case entirely.
--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "underwaterCaustics"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",  -- vec4 x 4
        name = "uniSetting",
        paramName = {
            'Wobble_Amount','Wobble_Speed','Tint_R','Tint_G',
            'Tint_B','Tint_Amount','Caustic_Scale','Caustic_Speed',
            'Caustic_Intensity','Opacity','','',
            '','','','',
        },
        default = {
            .008,1.4,.3,.75,
            .85,.5,10,.6,
            .35,1,0,0,
            0,0,0,0,
        },
        min = {
            0,0,0,0,
            0,0,2,0,
            0,0,0,0,
            0,0,0,0,
        },
        max = {
            .025,4,1,1,
            1,1,25,2,
            1,1,0,0,
            0,0,0,0,
        },
    },
}

kernel.fragment =
[[

uniform P_COLOR mat4 u_UserData0;
//----------------------------------------------

float Wobble_Amount     = u_UserData0[0][0];
float Wobble_Speed      = u_UserData0[0][1];
vec3  Water_Tint        = vec3( u_UserData0[0][2], u_UserData0[0][3], u_UserData0[1][0] );
float Tint_Amount       = u_UserData0[1][1];
float Caustic_Scale     = u_UserData0[1][2];
float Caustic_Speed     = u_UserData0[1][3];
float Caustic_Intensity = u_UserData0[2][0];
float Opacity           = u_UserData0[2][1];

//----------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    vec2 wobble = vec2(
        sin( UV.y * 12.0 + CoronaTotalTime * Wobble_Speed ),
        cos( UV.x * 10.0 + CoronaTotalTime * Wobble_Speed * 0.8 ) ) * Wobble_Amount;

    P_COLOR vec4 tex = texture2D( CoronaSampler0, UV + wobble );
    vec3 tinted = mix( tex.rgb, tex.rgb * Water_Tint, Tint_Amount );

    vec2 cUV = UV * Caustic_Scale + vec2( CoronaTotalTime * Caustic_Speed, CoronaTotalTime * Caustic_Speed * 0.6 );
    float c1 = sin( cUV.x * 6.28318 ) + sin( cUV.y * 6.28318 );
    float c2 = sin( ( cUV.x + cUV.y ) * 4.0 - CoronaTotalTime * Caustic_Speed * 1.3 );
    float caustic = pow( clamp( ( c1 + c2 ) * 0.25 + 0.5, 0.0, 1.0 ), 3.0 );

    vec3 finalRGB = clamp( tinted + vec3( 0.6, 0.9, 1.0 ) * caustic * Caustic_Intensity, 0.0, 1.0 );
    finalRGB = mix( tex.rgb, finalRGB, Opacity );

    P_COLOR vec4 COLOR = vec4( finalRGB, tex.a );
    COLOR.rgb *= COLOR.a;
    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]
