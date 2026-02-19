#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec3 TurbulenceGasGiantAli(vec3 point) {
  vec3 twistedPoint = point + Fbm(point * 8.0);
  vec3 cellCenter = vec3(0.0);
  vec2 cell;
  float r, fi, rnd, dist, dist2, dir;
  float strength = 13.0 + smoothstep(1.0, 0.09, cloudsFreq) * 30.0;
  vec3 randomize;
  randomize.x = hash1(Randomize.x);
  randomize.y = hash1(Randomize.y);
  randomize.z = hash1(Randomize.z);
  float freq = 100.0 - 90.0 * lavaCoverage;
  // minijupiters have low cloudsFreq. special-case them to make them look good as well.
  float size = max(
      9.0 - 8.0 * lavaCoverage - 8.0 * smoothstep(1.0, 0.09, cloudsFreq), 1.0);
  float dens = 1.0;

  for (int i = 0; i < 80; i++) {
    float angleY = randomize.y * 0.03 + lavaCoverage * 0.897 +
                   smoothstep(1.0, 0.09, cloudsFreq) * 0.097 * 6.283185;

    randomize.y = hash1(randomize.y);

    // clang-format off
    // TODO: Make a helper function for this!
    mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY),
                          0.0, 1.0, 0.0,
                          -sin(angleY), 0.0, cos(angleY));
    // clang-format on

    point *= rotY;

    twistedPoint = point;
    vec2 cell = inverseSF(point, freq, cellCenter);
    rnd = hash1(cell.x);
    r = size * cell.y;

    if ((rnd < dens)) {
      dir = sign(0.5 * dens - rnd);
      dist = saturate(1.0 - r);
      dist2 = saturate(0.5 - r);
      fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.25);
      twistedPoint =
          Rotate(dir * min(stripeTwist * 4.0, 15.0) * sign(cellCenter.y) * fi,
                 cellCenter.xyz, point);
    }

    size *= 1.02;
    strength = max(strength * 0.98, 6.0);
    point = twistedPoint;
  }

  return twistedPoint;
}

//-----------------------------------------------------------------------------

vec3 CycloneNoiseGasGiantAli(vec3 point, inout float offset) {
  vec3 rotVec = normalize(Randomize);
  vec3 twistedPoint = point;
  vec3 cellCenter = vec3(0.0);
  vec2 cell;
  float r, fi, rnd, dist, dist2, dir;
  float offs = 0.5 / (cloudsLayer + 1.0);
  float squeeze = 1.9;
  float strength = 10.0;
  float freq = cycloneFreq * 30.0;
  float dens = cycloneDensity * 0.02;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);

  for (int i = 0; i < cycloneOctaves; i++) {
    cell = inverseSF(vec3(point.x, point.y * squeeze, point.z),
                     freq + cloudsLayer, cellCenter);
    rnd = hash1(cell.x);
    r = size * cell.y;

    if ((rnd < dens)) {
      dir = sign(0.7 * dens - rnd);
      dist = saturate(1.0 - r);
      dist2 = saturate(0.3 - r);
      fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.5);
      twistedPoint = Rotate(cycloneMagn * dir * sign(cellCenter.y + 0.001) * fi,
                            cellCenter.xyz, point);
      offset += offs * fi * dir * 0.3;
    }

    freq = min(freq * 2.0, 6400.0);
    dens = min(dens * 3.5, 0.3);
    size = min(size * 1.5, 15.0);
    offs = offs * 0.85;
    squeeze = max(squeeze - 0.3, 1.0);
    strength = max(strength * 1.3, 0.5);
    point = twistedPoint;
  }

  return twistedPoint;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantAli(vec3 point) {
  vec3 twistedPoint = point;

  float zones = -cos(point.y * 1.75 * pow(abs(stripeTwist + 0.2), 0.3) *
                     stripeZones * 0.3);
  float ang = zones * 2;
  float offset = 0.0;

  // Compute cyclons
  if (cycloneOctaves > 0.0)
    twistedPoint = CycloneNoiseGasGiantAli(twistedPoint, offset);

  // Compute turbulence
  twistedPoint = TurbulenceGasGiantAli(twistedPoint);

  noiseOctaves = 12.0;
  noiseLacunarity = 4.0;
  noiseH = 0.6;

  // Compute stripes
  noiseOctaves = cloudsOctaves;
  float turbulence = Fbm(twistedPoint * 0.03);
  twistedPoint = twistedPoint * (0.43 * cloudsFreq) * (0.01 + smoothstep(1.0, 0.0, lavaCoverage)) + Randomize + cloudsLayer;
  twistedPoint.y *= 9.0 + turbulence;
  float height =
      unwrap_or(stripeFluct, 0.0) * 1.0 * (Fbm(twistedPoint * 2.0) * 0.8 + 0.1);

  // TODO: Add proper random number generator.
  // Also change other hashed Randomize instances to this.
  return height + hash1(HASHED_RANDOMIZE) + offset;
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height;
  if (volcanoActivity !=
      0.0) // volcanoActivity != 0.0 && colorDistFreq < 200000000
  {
    height = 3.0 * stripeFluct * HeightMapCloudsVenusAli(point) +
             HeightMapCloudsVenusAli2(point);
  } else {
    height = 0.5 * HeightMapCloudsGasGiantAli(point);
  }
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif