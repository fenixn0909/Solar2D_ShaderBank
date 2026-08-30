

--[[
  Focused Blast
  https://godotshaders.com/shader/focused-blast/
  gringer November 26, 2024

  Restored to match the original: the version here had accumulated
  extra experimental code not present in the source (a maskColor/
  checkColor detour whose "if UV.x > UV.x-mag_scale" condition has the
  UV.x terms cancel out algebraically, making it a uniform, time-only
  toggle that zeroed the entire texture's alpha - not spatial masking
  at all - whenever mag_scale was 0). The original's own composite,
  `COLOR = baseTexture + colour`, was present but commented out, so the
  named effect (the wave interference glow) never actually showed. Both
  are fixed below: back to a single scaled texture sample, glow added
  on top, matching the source exactly. `animation_time` (a Godot global
  shader uniform in the original, set via a project-level autoload) is
  CoronaTotalTime here, which was already the right adaptation.
--]]


local kernel = {}

kernel.language = "glsl"
kernel.category = "filter"
kernel.group = "FX"
kernel.name = "focusedBlast"

kernel.isTimeDependent = true

kernel.uniformData =
{
    {
        index = 0,
        type = "mat4",
        name = "uniSetting",
        paramName = {
            'Point_Count','Wave_Length','Focal_Radius','Falloff_Sd',
            'Point_Sd','Cycle_Period','Starting_Offset','Scale_Texture',
            '','','','',
            '','','','',
        },
        default = { 7,.15,.121,.2,  .5,15,-.75,1,  0,0,0,0,  0,0,0,0, },
        min =     { 2,.02,.02,.05,  .1,2,-3,0,      0,0,0,0,  0,0,0,0, },
        max =     { 16,.5,.5,1,     2,30,3,1,       1,1,1,1,  1,1,1,1, },
    },
}
kernel.fragment = [[

uniform P_COLOR mat4 u_UserData0;

int   point_count      = int( u_UserData0[0][0] );
float wave_length      = u_UserData0[0][1];
float focal_radius     = u_UserData0[0][2];
float falloff_sd       = u_UserData0[0][3];
float point_sd         = u_UserData0[1][0];
float cycle_period     = u_UserData0[1][1];
float starting_offset  = u_UserData0[1][2];
bool  scale_texture    = u_UserData0[1][3] > 0.5;




// ----------------------------------------------------------------------------------------------------

vec2 map_scale(vec2 uv, float x, float y){
  mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));

  uv -= 0.5; // centre on origin
  uv = uv * scale; // apply scaling
  uv += 0.5; // re-centre to 0.5,0.5
  return uv;
}

// ----------------------------------------------------------------------------------------------------

float PI = 3.14159265359;
P_COLOR vec4 COLOR;
P_DEFAULT float TIME = CoronaTotalTime;
// ----------------------------------------------------------------------------------------------------

P_COLOR vec4 FragmentKernel( P_UV vec2 UV )
{
    
    // ----------------------------------------------------------------------------------------------------
    float ampSum = 0.0;
      float timeFrac = mod(TIME, cycle_period);
      // Initial inteference pattern
      for(int i = 0; i < point_count; i++){
        vec2 pt = vec2(sin(float(i) * 2.0 * PI / float(point_count)) * focal_radius + 0.5,
                       cos(float(i) * 2.0 * PI / float(point_count)) * focal_radius + 0.5);
        float dist = distance(pt, UV) / (wave_length);
        float point_smoothing = 2.0 / (point_sd * sqrt(2.0 * PI)) *
                                 exp(-1.0 * pow((dist - starting_offset - timeFrac / (wave_length * cycle_period)), 2.0) / pow(point_sd, 2.0));
        ampSum += sin(fract(dist + starting_offset - timeFrac / (wave_length * cycle_period)) * 2.0 * PI) * point_smoothing;
      }
      // how many waves is it into the centre
      float wave_centre_count = focal_radius / wave_length;
      // how long does it take to get there?
      float seconds_per_wave = wave_length * cycle_period;
      // [added fudge of 'sqrt(cycle_period / 10.0)'; I don't know why this is needed]
      float wave_centre_time = seconds_per_wave * wave_centre_count * sqrt(cycle_period / 10.0);
      float mag_scale = 0.0;
      if(scale_texture){
        if((timeFrac + starting_offset) > wave_centre_time){
          mag_scale = (clamp(((timeFrac + starting_offset) - wave_centre_time) / (wave_centre_time), 0.0, 1.0));
        }
      } else {
        mag_scale = 1.0;
      }
      // global filtering curve
      float centreDist = distance(vec2(0.5, 0.5), UV);
      float outer_smoothing = 1.0 / (falloff_sd * sqrt(2.0 * PI)) *
                              exp(-1.0 * pow(centreDist, 2.0) / pow(falloff_sd, 2.0));
      ampSum *= outer_smoothing;

      vec4 baseTexture = texture2D( CoronaSampler0, map_scale(UV, 1.0 / mag_scale, 1.0 / mag_scale) );

      // Called for every pixel the material is visible on.
      vec4 colour = vec4(0.1 * ampSum,0.1 * ampSum, 0.1 * ampSum,abs(ampSum / 4.0));

      COLOR = baseTexture + colour;

    // ----------------------------------------------------------------------------------------------------
    COLOR.rgb *= COLOR.a;

    return CoronaColorScale( COLOR );
}
]]
return kernel

--[[

--]]

