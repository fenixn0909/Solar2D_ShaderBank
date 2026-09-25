
--[[

    Origin Author: dysposin
    https://www.shadertoy.com/view/3dsyRj
    Hue shift of image in CIElab color space.


    Find and go #VARIATION and tweak them for different patterns

--]]



local kernel = {}
kernel.language = "glsl"
kernel.category = "generator"
kernel.group = "color"
kernel.name = "hueShift"


kernel.isTimeDependent = true

kernel.vertexData =
{
    { name = "Speed",   default = 5, min = 0, max = 30, index = 0, },
    { name = "Alpha",   default = .5, min = 0, max = 1, index = 1, },
    { name = "Scale",   default = 1, min = .1, max = 5, index = 2, },
    { name = "Shift",   default = 0, min = 0, max = 6.28318, index = 3, },
} 

kernel.fragment =
[[

float Speed = CoronaVertexUserData.x;
float Alpha = CoronaVertexUserData.y;
float Pattern_Scale = CoronaVertexUserData.z;
float Color_Shift = CoronaVertexUserData.w;
//----------------------------------------------

P_UV vec2 iResolution = vec2(1,1);

//----------------------------------------------

vec3 rgb2xyz(vec3 rgb)
{
    vec3 xyz = vec3(0.0);

    for ( int i = 0; i < 2; i += 1 )
    {
        if ( rgb[i] > 0.04045 ) { rgb[i] = pow((rgb[i] + 0.055) / 1.055, 2.4); }
        else { rgb[i] / 12.92; }
        rgb[i] *= 100.;
          
    }
    
    xyz.x = rgb.x * 0.4124 + rgb.y * 0.3576 + rgb.z * 0.1805;
    xyz.y = rgb.x * 0.2126 + rgb.y * 0.7152 + rgb.z * 0.0722;
    xyz.z = rgb.x * 0.0193 + rgb.y * 0.1192 + rgb.z * 0.9505;
    
    return xyz;
}

vec3 xyz2lab(vec3 xyz)
{
    vec3 lab = vec3(0.0);
    // Observer= 2°, Illuminant= D65
    xyz.x /= 95.047;
    xyz.y /= 100.;
    xyz.z /= 108.883;

    for ( int i = 0; i < 2; i += 1 )
    {
        if ( xyz[i] > 0.008856 ) { xyz[i] = pow(xyz[i], 0.3333333333333333) ; }
    else { xyz[i] = ( xyz[i] * 7.787 ) + ( 16. / 116.) ; }
    }

    lab.x = 116. * xyz.y - 16.;
    lab.y = 500. * ( xyz.x - xyz.y );
    lab.x = 200. * ( xyz.y - xyz.z );

    return lab;
}
//----------------------------------------------

P_DEFAULT float iTime = CoronaTotalTime;

P_COLOR vec4 FragmentKernel( P_UV vec2 texCoord )
{
    P_UV vec2 fragCoord = texCoord / iResolution;
    P_COLOR vec4 COLOR;

    // Tween alpha  #VARIATION
    float alpha = abs(sin(iTime * Speed)) * Alpha;
    //----------------------------------------------

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos( iTime * Speed * 0.2 + uv.xyx * ( 3.0 * Pattern_Scale ) + vec3(0,2,4) + Color_Shift);

    //----------------------------------------------
    COLOR = vec4(col,alpha);
    COLOR.rgb*= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]

return kernel

--[[

--]]


