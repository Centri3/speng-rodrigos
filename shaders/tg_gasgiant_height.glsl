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

  float hotStrength = 1.0;
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
  vec4 cell;
  vec3 v;
  float r, fi, rnd, dist, dist2, dir;
  float offs = 0.5 / (cloudsLayer + 1.0);
  float strength = 10.0;
  float freq = cycloneFreq;
  float dens = cycloneDensity;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);
  vec3 randomize = Randomize;

  for (int i = 0; i < cycloneOctaves; i++) {
    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);
    randomize.z = hash1(randomize.z);

    float angleY = randomize.y * 12.56637061;

    // clang-format off
    mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                         0.0, 1.0, 0.0,
                         -sin(angleY), 0.0, cos(angleY));
    // clang-format on

    point *= rotY;

    twistedPoint = point;
    cell = _Cell2NoiseVec(point * freq, 0.2, randomize * 12.56637061);
    v = cell.xyz - point;
    v.y *= 1.9;
    rnd = hash1(cell.x);
    if (rnd < dens) {
      dir = sign(0.5 * dens - rnd);
      dist = saturate(1.0 - length(v));
      dist2 = saturate(0.5 - length(v));
      fi = pow(dist, 20.0 * size) * (exp(-60.0 * dist2 * dist2) + 0.5);
      twistedPoint =
          Rotate(dir * cycloneMagn * sign(cell.y) * fi, cell.xyz, point);
      offset += offs * fi * dir * 0.3;
    }

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

  return height + offset;
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
  
  if (volcanoActivity !=
      0.0) // volcanoActivity != 0.0 && colorDistFreq < 200000000
  {
    height = 3.0 * stripeFluct * HeightMapCloudsVenusAli(point) +
             HeightMapCloudsVenusAli2(point);
  } else 
  {
    height = 0.95 * (HeightMapCloudsGasGiantGmail(point, true, stripeZones) + 0.5 * HeightMapCloudsGasGiantGmail2(point) +  0.5 * HeightMapCloudsGasGiantGmail3(point));
//	height = (0.05 * HeightMapCloudsGasGiantAli(point, _stripeFluct) + 0.1 * HeightMapCloudsGasGiantAli2(point, _stripeFluct) + 0.15 * HeightMapCloudsGasGiantAli3(point, _stripeFluct))*0.5;
	
	height = softPolyMax(height, 0.0, 0.0);

  }
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif