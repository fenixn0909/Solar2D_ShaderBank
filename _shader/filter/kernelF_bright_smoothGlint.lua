--[[

    https://godotshaders.com/shader/highlight-canvasitem/
    by andich.xyz

    Highlight effect as a CanvasItem Material

    How to use:

    Place a node of a control type (i.e. TextureRect/Button);
    Create a ColorRect child;
    In the Inspector under CanvasItem panel apply the material and select Highlight shader;
    If needed change Clip Children property of the parent node to Clip+Draw (Inspector -> CanvasItem -> Visibility -> Clip Children);
    If experience the change of parent node’s color change the blending mode of either the highlight shader (line 2 of shader code) or the parent node’s material, pick a combination that works for you.
    Parameters:

    Line Smoothness – makes the highlight edges softer, 0 = hard edges;
    Line Width – makes line thiner/wider, 0 = thin line;
    Brightness – multiplicative parameter, that makes the line more visible, diffirent combinations of Line Smoothness, Line Width and Brightness produces various results;
    Rotation Deg – rotates the highlight, incrementing the value rotates the highlight clockwise;
    Distortion – merges line with the edges of the ColorRect (see ColorRect in How to use section);
    Speed – dictates how fast the effect is moving from one side to the opposite;
    Position – manual placement of the highlight line, 0 = Position Min, 1 = Position Max;
    Position Min – starting point of the highlight line;
    Position Max – end point of the highlight line;
    Alpha – controls the overall visibility of the highlight;
    Color is controlled by the object itself, change the color property of the ColorRect to change the highlight, if the shader is applyed to the texture element, then the texture will be clipped by the highlight

]]



local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "bright"
kernel.name = "smoothGlint"
kernel.isTimeDependent = true

-- Expose effect parameters using vertex data
kernel.vertexData   = {
  {
    name = "intensity",
    default = 0.65, 
    min = 0,
    max = 1,
    index = 0,  -- This corresponds to "CoronaVertexUserData.x"
  },
  {
    name = "size",
    default = 0.1, 
    min = 0,
    max = 1,
    index = 1,  -- This corresponds to "CoronaVertexUserData.y"
  },
  {
    name = "tilt",
    default = 0.2, 
    min = 0.0,
    max = 2.0,
    index = 2,  -- This corresponds to "CoronaVertexUserData.z"
  },
  {
    name = "speed",
    default = 1.0, 
    min = 0.1,
    max = 10.0,
    index = 3,  -- This corresponds to "CoronaVertexUserData.w"
  },
}

kernel.fragment =
[[

uniform float Line_Smoothness = 0.145; //: hint_range(0, 0.1) 
uniform float Line_Width = 0.09; //: hint_range(0, 0.2, 0.3) 
uniform float Brightness = 2.0; //: hint_range(3) 
uniform float Rotation_deg = 30; //: hint_range(-90, 90) 
uniform float Distortion = 1.8; //: hint_range(1, 2) 
uniform float Speed = 0.45;
uniform float Position = 0; // : hint_range(0, 1)
uniform float Position_Min = 0.25;
uniform float Position_Max = 0.5;
uniform float Alpha = 1; // : hint_range(0, 1) 


P_DEFAULT float TIME = CoronaTotalTime;

//----------------------------------------------

vec2 rotate_uv(vec2 uv, vec2 center, float rotation, bool use_degrees){
      float _angle = rotation;
      if(use_degrees){
        _angle = rotation * (3.1415926/180.0);
      }
      mat2 _rotation = mat2(
        vec2(cos(_angle), -sin(_angle)),
        vec2(sin(_angle), cos(_angle))
      );
      vec2 _delta = uv - center;
      _delta = _rotation * _delta;
      return _delta + center;
    }


//----------------------------------------------
P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    // real-time params: the old sliders did nothing because the body
    // only read the hardcoded uniforms below. (Never assign TO those
    // uniforms - they are read-only; use locals instead.)
    float vdIntensity = CoronaVertexUserData.x; // glint brightness
    float vdSize      = CoronaVertexUserData.y; // band width
    float vdTilt      = CoronaVertexUserData.z; // band angle 0..90 deg
    float vdSpeed     = CoronaVertexUserData.w; // sweep speed

    float effBrightness = 0.5 + vdIntensity * 3.0;
    float effLineWidth  = 0.01 + vdSize * 0.25;
    float effRotation   = vdTilt * 45.0;
    float effSpeed      = vdSpeed;

    //----------------------------------------------

    P_COLOR vec4 texColor = texture2D( CoronaSampler0, UV );
    P_COLOR vec4 COLOR = texture2D( CoronaSampler0, UV );


    vec2 center_uv = UV - vec2(0.5, 0.5);
    float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y));
    gradient_to_edge = gradient_to_edge * Distortion;
    gradient_to_edge = 1.0 - gradient_to_edge;
    vec2 rotaded_uv = rotate_uv(UV, vec2(0.5, 0.5), effRotation, true);
    
    float remapped_position;
    {
      float output_range = Position_Max - Position_Min;
      remapped_position = Position_Min + output_range * Position;
    }
    
    //float remapped_time = TIME * Speed + remapped_position;
    float remapped_time = abs(sin(TIME)) * effSpeed + remapped_position;
    remapped_time = fract(remapped_time);
    {
      float output_range = 2.0 - (-2.0);
      remapped_time = -2.0 + output_range * remapped_time;
    }
    
    vec2 offset_uv = vec2(rotaded_uv.xy) + vec2(remapped_time, 0.0);
    float line = vec3(offset_uv, 0.0).x;
    line = abs(line);
    line = gradient_to_edge * line;
    line = sqrt(line);
    
    float line_smoothness = clamp(Line_Smoothness, 0.001, 1.0);
    float offset_plus = effLineWidth + line_smoothness;
    float offset_minus = effLineWidth - line_smoothness;
    
    float remapped_line;
    {
      float input_range = offset_minus - offset_plus;
      remapped_line = (line - offset_plus) / input_range;
    }
    remapped_line = remapped_line * effBrightness;
    remapped_line = min(remapped_line, Alpha);
    

    

    float _cChk =  COLOR.r + COLOR.g + COLOR.b;
    float _a = max(sign(_cChk - 0), 0.0);
    remapped_line = remapped_line * _a;
    
    remapped_line = remapped_line * effBrightness;
    remapped_line = min(remapped_line, Alpha);
    //COLOR.rgb = vec3(COLOR.xyz) * vec3(remapped_line);
    //COLOR.a = remapped_line;
    COLOR.rgb = max( COLOR.rgb, vec3(remapped_line));
    COLOR.a = _a;
    

    return CoronaColorScale( COLOR );


    

}
]]

return kernel





--[[

]]









