#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float HeightMapAsteroid(vec3 point) {
  float _hillsMagn = hillsMagn;
  if (hillsMagn < 0.05) {
    _hillsMagn = 0.05;
  }

  // GlobalModifier // Global landscape
  vec3 p = point * venusFreq + Randomize;
  noiseOctaves = 10.0;
  noiseLacunarity = 3.0;
  float height = venusMagn *
                 (0.5 - Noise(p) - RidgedMultifractal(p * mainFreq, 2.0) * 0.3);

  noiseOctaves = 10;
  noiseLacunarity = 2.0;
  height += 0.05 * iqTurbulence(point * 2.0 * mainFreq + Randomize, 0.35);

  // TerrainFeature // Hills
  noiseOctaves = 5;
  noiseLacunarity = 2.218281828459;
  float hills = (0.5 + 1.5 * Fbm(p * 0.0721)) * hillsFreq;
  hills = Fbm(p * hills) * 0.15;
  noiseOctaves = 2;
  float hillsMod = smoothstep(0.0, 1.0, Fbm(p * hillsFraction) * 3.0);
  height *= 1.0 + _hillsMagn * hills * hillsMod;

  // TerrainFeature // Craters (Old)
  heightFloor = -0.1;
  heightPeak = 0.6;
  heightRim = 0.4;
  float crater = 0.4 * CraterNoise(point, craterMagn * 0.3, craterFreq * 10.0,
                                   craterSqrtDensity, craterOctaves);

  noiseOctaves = 10;
  noiseLacunarity = 2.0;
  crater += montesMagn * crater * iqTurbulence(point * montesFreq, 0.52);

  height += crater;

  // TerrainFeature // Equatorial ridge
  // 18-07-2024 by Sp_ce // Attempting improvement to bring inline with iapetus
  if (eqridgeMagn > 0.0) {
    // noiseOctaves    = 4.0;
    noiseOctaves = 10.0;
    noiseLacunarity = 2.0;
    noiseH = 0.9;
    noiseOffset = 0.5;
    float x = (point.y + 0.1 * Fbm(point)) / eqridgeWidth;
    float ridgeHeight = exp(-0.75 * pow(abs(x), 1.5));
    // height = max(height + (eqridgeMagn * ridgeHeight * iqTurbulence(point
    // * 1.0 * eqridgeModFreq + Randomize, eqridgeModMagn)), height);
    // eqridgeModMagn 0.7 - 1.2
    // eqridgeModFreq 4
    float eqridgeHeight = pow(eqridgeMagn, 1.25);
    height =
        max(height + (eqridgeMagn * ridgeHeight * 1.5 *
                      iqTurbulence(point * 0.4 * eqridgeModFreq + Randomize,
                                   0.2 * eqridgeModMagn)),
            height);
  }

  // GlobalModifier // Terrain noise match colorvary
  vec3 pp =
      (point + Randomize) * (0.0005 * hillsFreq / (_hillsMagn * _hillsMagn));
  noiseOctaves = 14.0;
  noiseLacunarity = 2.218281828459;
  noiseH = smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
  vec3 distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
  float vary =
      (1.0 -
       5 * (Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) +
                                     RidgedMultifractal(pp * 0.999, 8.0))))) *
      0.001;
  height += saturate(vary);

  // GlobalModifier // Soften max/min height
  height = softPolyMin(height, 0.99, 0.3);
  height = softPolyMax(height, 0.01, 0.3);

  return height;
}

//-----------------------------------------------------------------------------

void main() {
  float height = HeightMapAsteroid(GetSurfacePoint());
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif
