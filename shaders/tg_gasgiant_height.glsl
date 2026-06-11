#include "tg_rmr.glh"

//float freq = (70.0 - 60.0 * lavaCoverage);
#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec3 TurbulenceGasGiantAli(vec3 point) {   //actually turbulance ali but I'm being lazy
  vec4 cell;
  vec3 v;
  float r, fi, rnd, dist, dist2, dir;
  // float squeeze = 1.9;
  float dens = 1.0;

  vec3 randomize;
  randomize.x = hash1(Randomize.x);
  randomize.y = hash1(Randomize.y);
  randomize.z = hash1(Randomize.z);

  vec3 coolJupiter = point;
  vec3 hotJupiter = point;
  vec3 swirls = point;

  float coolStrength = 1.0 - 1.0 * smoothstep(0.0, 0.5, lavaCoverage);
  float coolFreq = (5.0 - 3.6 * smoothstep(0.0, 0.5, lavaCoverage));
  float coolSize = 18.0 - 14.0 * smoothstep(0.0, 0.5, lavaCoverage);

  // cool jupiter algorithm: faster and allows for more octaves
  for (int i = 0; i < 80 - smoothstep(0.0, 0.5, lavaCoverage) * 20.0; i++) {
    float angleY =
        (randomize.y * 0.01 + 0.09 * smoothstep(0.2, 0.5, lavaCoverage)) *
        6.283185;

    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);

    // clang-format off
    mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                         0.0, 1.0, 0.0,
                         -sin(angleY), 0.0, cos(angleY));
    // clang-format on

    coolJupiter *= rotY;

    cell = _Cell2NoiseVec((coolJupiter * coolFreq), 0.6, randomize * 12.5663706);
    v = cell.xyz - coolJupiter;
    rnd = hash1(cell.x);
    if (rnd < dens) {
      dir = sign(0.5 * dens - rnd);
      dist = saturate(1.0 - length(v));
      dist2 = saturate(0.5 - length(v));
      fi =
          pow(dist, 12.0 * coolSize) *
          (exp(-60.0 * dist2 * dist2) + 0.5); // TODO add back old complex logic
      coolJupiter = Rotate(dir * min(stripeTwist * 4.0, 15.0) * sign(cell.y) *
                               fi * coolStrength,
                           cell.xyz, coolJupiter);
    }

    coolSize *= 1.02;
    coolStrength = max(coolStrength * 0.98, 0.4);
  }

  float hotStrength = 0.5;
  float hotSize = 1.0;

  // hot jupiter/minijupiter algorithm: this is separate because cellular noise
  // breaks down at low frequencies. we just place points randomly because we
  // don't need many octaves.
  for (int i = 0; i < 80; i++) {
    float lat = acos(2.0 * randomize.x - 1.0) - (3.1415926 / 2.0);
    float lon = (2.0 * 3.1415926 * randomize.z);

    float x = cos(lat) * cos(lon);
    float y = cos(lat) * sin(lon);
    float z = sin(lat);

    cell = vec4(x, y, z, 0.0);
    v = cell.xyz - hotJupiter;

    dir = sign(0.5 * dens - randomize.x);
    dist = saturate(
        1.0 - length(v) -
        distance(cell.y, hotJupiter.y) * (5.0 + lavaCoverage * 5.0) *
            smoothstep(0.5, 0.3, lavaCoverage) *
            smoothstep(0.3, 0.5, cloudsFreq));
    dist2 = saturate(
        0.5 - length(v) -
        distance(cell.y, hotJupiter.y) * (2.5 + lavaCoverage * 5.0) *
            smoothstep(0.5, 0.3, lavaCoverage) *
            smoothstep(0.3, 0.5, cloudsFreq)); // only apply on non-minijupiters.
    fi = pow(dist, 12.0 * hotSize) * (exp(-60.0 * dist2 * dist2) + 0.5);
    hotJupiter = Rotate(dir * min(stripeTwist * 4.0, 15.0) * sign(cell.y) *
                            fi * hotStrength,
                        cell.xyz, hotJupiter);

    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);
    randomize.z = hash1(randomize.z);
  }

  return mix(coolJupiter, hotJupiter, saturate(smoothstep(0.5, 1.0, lavaCoverage) + smoothstep(1.0, 0.09, cloudsFreq)));
}

//-----------------------------------------------------------------------------

vec3 CycloneNoiseGasGiantAli(vec3 point, inout float offset) {
  vec3 rotVec = normalize(Randomize);
  vec3 twistedPoint = point;
  float offs = 1.0 / (cloudsLayer + 1.0);
  float strength = 10.0;
  float freq = cycloneFreq*4;
  float dens = cycloneDensity;
  float size = 0.3 * pow(cloudsLayer + 1.0, 5.0);
  vec3 randomize = Randomize;

  for (int i = 0; i < cycloneOctaves; i++) {
    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);
    randomize.z = hash1(randomize.z);

    float angleY = randomize.y * 6.283185;
    // clang-format off
    mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                         0.0, 1.0, 0.0,
                         -sin(angleY), 0.0, cos(angleY));
    // clang-format on

    point *= rotY;
    
    vec3 p_freq = point * freq;
    vec3 cell_base = floor(p_freq);
    

    // Accumulators for our splatted displacements
    vec3 point_disp = vec3(0.0);
    float offset_disp = 0.0;

    // Search the surrounding 3x3x3 grid cells
    for (float z = -1.0; z <= 1.0; z++) {
      for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
          vec3 d = vec3(x, y, z);
          vec3 grid_cell = cell_base + d;
          
          // Generate a stable hash for this specific grid cell to determine density
          float rnd = hash1(grid_cell.x * 127.1 + grid_cell.y * 311.7 + grid_cell.z * 74.7);
          
          if (rnd < dens) {
            // Get jittered position for the storm core (using your 0.2 jitter)
            vec3 rnd_offset = NoiseNearestUVec4((grid_cell + randomize) / NOISE_TEX_3D_SIZE).xyz * 0.2;
            vec3 local_center = grid_cell + vec3(0.5) + rnd_offset;
            
            vec3 v = local_center - p_freq;
            v.y *= 1.9; //  Squish
            
            float dist = length(v);
            
            // CRITICAL: max_rad must be <= 1.4 to ensure the storm's influence 
            // drops to absolute zero before it escapes our 3x3x3 search box. 
            // This guarantees no tearing.
            float max_rad = 1.3; 
            
            if (dist < max_rad) {
              float dir = sign(0.5 * dens - rnd);
              
              // Normalize distances 
              float dist_norm = saturate(1.0 - (dist / max_rad));
              float dist2_norm = saturate(0.5 - (dist / max_rad));
              
              // Falloff formula
              float fi = pow(dist_norm, 40.0 * size) * (exp(-60.0 * dist2_norm * dist2_norm) + 0.5);
              
              // The spherical axis of rotation for this specific storm
              vec3 axis = normalize(local_center); 
              
              // Calculate how much this specific storm wants to rotate our point
              vec3 rotated_p = Rotate(dir * cycloneMagn * sign(axis.y) * fi, axis, point);
              
              // Accumulate the displacement vectors
              point_disp += (rotated_p - point);
              offset_disp += offs * fi * dir * 0.4;
            }
          }
        }
      }
    }

    // Apply the accumulated twists to the point
    twistedPoint = point + point_disp;
    offset += offset_disp;

    freq *= 1.5;
    size *= 1.5;
    strength *= 1.3;
    point = twistedPoint;
  }
	
	// polar round cyclones


     vec2  cell;
	 vec3  cellCenter = vec3(0.0);
	 float r, fi, rnd, dist, dist2, dir;
	float latitude = abs(point.y);
	
	strength = 7.125;
    freq = cycloneFreq2 * 10.0;
    dens = 0;
//	if (latitude >= cycloneLatitude2)
//	{
	dens = 100.0* smoothstep(cycloneLatitude2 - 0.1, cycloneLatitude2 + 0.1, abs(point.y));
//    }
	
	size =  0.2 / smoothstep(cycloneLatitude2 - 0.1, cycloneLatitude2 + 0.1, abs(point.y));
    offs = -cycloneMagn2 *1.5 / (cloudsLayer + 1.0);// * smoothstep(cycloneLatitude2 - 0.1, cycloneLatitude2 + 0.1, abs(point.y));

    for (int i=0; i<cycloneOctaves2; i++)
{
    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);
    randomize.z = hash1(randomize.z);

    float angleY = randomize.y * 6.283185;
    // clang-format off
    mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                         0.0, 1.0, 0.0,
                         -sin(angleY), 0.0, cos(angleY));
    // clang-format on

    point *= rotY;
    
    vec3 p_freq = point * freq;
    vec3 cell_base = floor(p_freq);
    

    // Accumulators for our splatted displacements
    vec3 point_disp = vec3(0.0);
    float offset_disp = 0.0;

    // Search the surrounding 3x3x3 grid cells
    for (float z = -1.0; z <= 1.0; z++) {
      for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
          vec3 d = vec3(x, y, z);
          vec3 grid_cell = cell_base + d;
          
          // Generate a stable hash for this specific grid cell to determine density
          float rnd = hash1(grid_cell.x * 127.1 + grid_cell.y * 311.7 + grid_cell.z * 74.7);
          
          if (rnd < dens) {
            // Get jittered position for the storm core (using your 0.2 jitter)
            vec3 rnd_offset = NoiseNearestUVec4((grid_cell + randomize) / NOISE_TEX_3D_SIZE).xyz * 0.2;
            vec3 local_center = grid_cell + vec3(0.5) + rnd_offset;
            
            vec3 v = local_center - p_freq;
            v.y *= 1.9; //  Squish
            
            float dist = length(v);
            
            // CRITICAL: max_rad must be <= 1.4 to ensure the storm's influence 
            // drops to absolute zero before it escapes our 3x3x3 search box. 
            // This guarantees no tearing.
            float max_rad = 1.3; 
            
            if (dist < max_rad) {
              float dir = sign(0.5 * dens - rnd);
              
              // Normalize distances for your original shaping math
              float dist_norm = saturate(1.0 - (dist / max_rad));
              float dist2_norm = saturate(0.5 - (dist / max_rad));
              
              // Your original falloff formula
              float fi = pow(dist_norm, 40.0 * size) * (exp(-60.0 * dist2_norm * dist2_norm) + 0.5);
              
              // The spherical axis of rotation for this specific storm
              vec3 axis = normalize(local_center); 
              
              // Calculate how much this specific storm wants to rotate our point
              vec3 rotated_p = Rotate(dir * cycloneMagn * sign(axis.y) * fi, axis, point);
              
              // Accumulate the displacement vectors
              point_disp += (rotated_p - point);
              offset_disp += offs * fi * dir * 0.4;
            }
          }
        }
      }
    }

    // Apply the accumulated twists to the point
    twistedPoint = point + point_disp;
    offset += offset_disp;

    freq *= 1.5;
    size *= 1.5;
    strength *= 1.3;
    point = twistedPoint;
  }

  return twistedPoint;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail(vec3 point, bool cyclones,
                                   float _stripeZones) {
  vec3 twistedPoint = point;

	// Compute zones
  float zones = Noise(vec3(0.0, twistedPoint.y * _stripeZones * 0.6 + cloudsLayer, 0.35)) * 0.8 + 0.20;
  float offset = 0.0;

  // Compute cyclons
  if (cycloneOctaves > 0.0 && cyclones)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  noiseOctaves = cloudsOctaves;
  float turbulence = Fbm(twistedPoint * 0.03);
  twistedPoint = twistedPoint * (0.43 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 9.0 + turbulence;
  float height =
      unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.8 + 0.1);

  return height + offset;
}
//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail2(vec3 point) {
  vec3 twistedPoint = point;

    // Compute zones
    float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.5 + cloudsLayer, 0.3)) * 0.5 + 0.10;
    float offset = 0.1;

  // Compute cyclons
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  noiseOctaves = cloudsOctaves;
  float turbulence = Fbm(twistedPoint * 0.01);
  twistedPoint = twistedPoint * (0.32 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 30.0 + turbulence;
  float height =
      unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.5 + 0.4);

  return zones + height + offset;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail3(vec3 point) {
  vec3 twistedPoint = point;

    // Compute zones
    float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.9 + cloudsLayer, 0.3)) * 0.4 + 0.08865;
    float offset = 0.0;

  // Compute cyclons
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  noiseOctaves = cloudsOctaves;
  float turbulence = Fbm(twistedPoint * 8.86);
  twistedPoint = twistedPoint * (1.12 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 80.0 + turbulence;
  float height =
      unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.25 + 0.4);

  return height + offset;
}

//-----------------------------------------------------------------------------


void main() {
  vec3 point = GetSurfacePoint();
  float height;
  float _stripeFluct = 0.3 + stripeFluct * 1.2;
  
  if (volcanoActivity !=0.0) // volcanoActivity != 0.0 && colorDistFreq < 200000000
  {
    height = 3.0 * stripeFluct * HeightMapCloudsVenusAli(point) +
             HeightMapCloudsVenusAli2(point);
			 height = softPolyMax(height, 0.0, 0.2);
  } else 
  {
    height = 0.95 * (HeightMapCloudsGasGiantGmail(point, true, stripeZones) + 0.5 * HeightMapCloudsGasGiantGmail2(point) +  0.5 * HeightMapCloudsGasGiantGmail3(point));
//	height = (0.05 * HeightMapCloudsGasGiantAli(point, _stripeFluct) + 0.1 * HeightMapCloudsGasGiantAli2(point, _stripeFluct) + 0.15 * HeightMapCloudsGasGiantAli3(point, _stripeFluct))*0.5;
	
	height = softPolyMax(height, 0.0, 0.2);

  }
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif