local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "color"
kernel.name = "invertTween"

kernel.vertexData =
{
  { name = "Intensity", default = 0, min = 0, max = 1, index = 0, },
  { name = "Speed",     default = 1, min = 0, max = 5, index = 1, },
}

kernel.isTimeDependent = true

kernel.fragment =
[[

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
  float Intensity = CoronaVertexUserData.x;
  float Speed     = CoronaVertexUserData.y;
  vec3 tweener;
  tweener.r = abs(sin(CoronaTotalTime*Speed * 1.0));
  tweener.g = abs(sin(CoronaTotalTime*Speed * 0.6));
  tweener.b = abs(sin(CoronaTotalTime*Speed * 1.4));
  tweener *= Intensity;
  P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );
  P_COLOR vec4 inv = vec4(1.0 - COLOR.rgb, COLOR.a);
  COLOR.r = mix(COLOR.r, inv.r, tweener.r);
  COLOR.g = mix(COLOR.g, inv.g, tweener.g);
  COLOR.b = mix(COLOR.b, inv.b, tweener.b);
  COLOR.rgb *= COLOR.a;
  return CoronaColorScale(COLOR);
}
]]

return kernel
