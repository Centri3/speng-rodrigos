#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec3 TurbulenceGasGiantAli(vec3 point) {
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

    cell = _Cell2NoiseVec((coolJupiter * coolFreq), 0.6, randomize);
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

  float hotStrength = 0.1;
  float hotSize = 0.2;

  // hot jupiter/minijupiter main algorithm: this is separate because cellular
  // noise breaks down at low frequencies. we just place points randomly because
  // we don't need many octaves.
  for (int i = 0; i < 100; i++) {
    float lat = acos(2.0 * randomize.x - 1.0) - (3.1415926 / 2.0);
    float lon = 2.0 * 3.1415926 * randomize.z;

    float x = cos(lat) * cos(lon);
    float y = cos(lat) * sin(lon);
    float z = sin(lat);

    for (int j = 0; j < 3; j++) {
      float angleY =
          randomize.y * 0.13 + smoothstep(0.0, 0.5, lavaCoverage) * 0.17;

      // clang-format off
      mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                           0.0, 1.0, 0.0,
                           -sin(angleY), 0.0, cos(angleY));
      // clang-format on

      hotJupiter *= rotY;

      cell = vec4(x, y, z, 0.0);
      v = cell.xyz - hotJupiter;

      dir = sign(0.5 * dens - randomize.x);
      dist = saturate(1.0 - length(v));
      dist2 = saturate(0.5 - length(v));
      fi = pow(dist, 12.0 * hotSize) * (exp(-60.0 * dist2 * dist2) + 0.5);
      hotJupiter = Rotate(dir * min(stripeTwist * 4.0, 15.0) * sign(cell.y) *
                              fi * hotStrength,
                          cell.xyz, hotJupiter);

      randomize.y = hash1(randomize.y);
    }

    hotStrength *= 1.03;
    hotSize *= 1.03;

    randomize.x = hash1(randomize.x);
    randomize.z = hash1(randomize.z);
  }

  float swirlsStrength = 1.0;
  float swirlsSize = 1.1;
  float swirlsMask = 0.0;

  for (int i = 0; i < 20; i++) {
    float lat = acos(2.0 * randomize.x - 1.0) - (3.1415926 / 2.0);
    float lon = 2.0 * 3.1415926 * randomize.z;

    float x = cos(lat) * cos(lon);
    float y = cos(lat) * sin(lon);
    float z = sin(lat);

    for (int j = 0; j < 3; j++) {
      float angleY =
          randomize.y * 0.43 + smoothstep(0.0, 0.5, lavaCoverage) * 0.57;

      // clang-format off
      mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                           0.0, 1.0, 0.0,
                           -sin(angleY), 0.0, cos(angleY));
      // clang-format on

      swirls *= rotY;

      cell = vec4(x, y, z, 0.0);
      v = cell.xyz - swirls;

      dir = sign(0.5 * dens - randomize.x);
      dist = saturate(1.0 - length(v));
      dist2 = saturate(0.5 - length(v));
      fi = pow(dist, 12.0 * swirlsSize) * (exp(-60.0 * dist2 * dist2) + 0.5);
      swirlsMask += dist * 0.2;
      swirls = Rotate(dir * min(stripeTwist * 4.0, 15.0) * sign(cell.y) * fi *
                          swirlsStrength,
                      cell.xyz, swirls);

      randomize.y = hash1(randomize.y);
    }

    randomize.x = hash1(randomize.x);
    randomize.z = hash1(randomize.z);
  }

  return mix(coolJupiter, mix(hotJupiter, swirls, saturate(swirlsMask)),
             saturate(smoothstep(0.5, 1.0, lavaCoverage) +
                      smoothstep(0.5, 0.09, cloudsFreq)));
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
  float freq = cycloneFreq * 0.2;
  float dens = cycloneDensity;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);
  vec3 randomize = Randomize;


  for (int i = 0; i < cycloneOctaves; i++) {
    randomize.x = hash1(randomize.x);
    randomize.y = hash1(randomize.y);
    randomize.z = hash1(randomize.z);

    twistedPoint = point;
    cell = _Cell2NoiseVec(point * freq, 0.3, randomize * 10.0);
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
      offset += offs * fi * dir * 0.1 * cycloneMagn;
    }

    freq = min(freq * 2.0, 6400.0);
    dens = min(dens * 3.5, 0.3);
    size = min(size * 1.5, 15.0);
    strength = max(strength * 1.3, 0.5);
    point = twistedPoint;
  }

  return twistedPoint;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail(vec3 point, float _stripeFluct) {
  vec3 twistedPoint = point;

  noiseOctaves = cloudsOctaves;
  noiseLacunarity = 4.0;
  noiseH = 0.6 + min(smoothstep(0.5, 1.0, lavaCoverage) * 0.3 +
                         smoothstep(0.5, 0.09, cloudsFreq) * 0.3,
                     0.3);

  // Compute cyclons
  float offset = 0.0;
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  float turbulence = Fbm(twistedPoint * 0.03);
  twistedPoint = twistedPoint * (0.43 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 9.0 * stripeZones * 0.12 + turbulence;
  float height = _stripeFluct * 0.5 * (Fbm(twistedPoint) * 0.8 + 0.1);

  return height * 6.0 + offset;
}
//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail2(vec3 point, float _stripeFluct) {
  vec3 twistedPoint = point;

  noiseOctaves = cloudsOctaves;
  noiseLacunarity = 4.0;
  noiseH = 0.5 + min(smoothstep(0.5, 1.0, lavaCoverage) * 0.3 +
                          smoothstep(0.5, 0.09, cloudsFreq) * 0.3,
                      0.3);

  // Compute cyclons
  float offset = 0.0;
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  float turbulence = Fbm(twistedPoint * 0.01);
  twistedPoint = twistedPoint * (0.32 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 30.0 * stripeZones * 0.12 + turbulence;
  float height = _stripeFluct * 0.5 * (Fbm(twistedPoint) * 0.5 + 0.4);

  return height * 6.0 + offset;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail3(vec3 point, float _stripeFluct) {
  vec3 twistedPoint = point;

  noiseOctaves = cloudsOctaves;
  noiseLacunarity = 4.0;
  noiseH = 0.5 + min(smoothstep(0.5, 1.0, lavaCoverage) * 0.3 +
                          smoothstep(0.5, 0.09, cloudsFreq) * 0.3,
                      0.3);

  // Compute cyclons
  float offset = 0.0;
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  // Compute stripes
  float turbulence = Fbm(twistedPoint * 8.86);
  twistedPoint = twistedPoint * (1.12 * cloudsFreq) + Randomize + cloudsLayer;
  twistedPoint.y *= 80.0 * stripeZones * 0.12 + turbulence;
  float height = _stripeFluct * 0.5 * (Fbm(twistedPoint) * 0.25 + 0.4);

  return height * 6.0 + offset;
}

//-----------------------------------------------------------------------------

void main() {
  float _stripeFluct = 0.3 + unwrap_or(stripeFluct, 0.0) * 0.2;

  vec3 point = GetSurfacePoint();
  float height;
  if (volcanoActivity !=
      0.0) // volcanoActivity != 0.0 && colorDistFreq < 200000000
  {
    height = 3.0 * _stripeFluct * HeightMapCloudsVenusAli(point) +
             HeightMapCloudsVenusAli2(point);
  } else {
    height = 0.95 * HeightMapCloudsGasGiantGmail(point, _stripeFluct) +
             0.5 * HeightMapCloudsGasGiantGmail2(point, _stripeFluct) +
             0.5 * HeightMapCloudsGasGiantGmail3(point, _stripeFluct);
  }
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif