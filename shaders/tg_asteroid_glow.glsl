#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec4 GlowMapAsteroid(vec3 point, float height, float slope) {
  // Thermal emission temperature (in thousand Kelvins)
  vec3 p = point * 6.0 + Randomize;
  noiseOctaves = 5;
  noiseH = 0.3;
  float dist = 10.0 * colorDistMagn * Fbm(p * 0.2);
  // float varyTemp = 0.5 * smoothstep(0.0, 0.4, cell.y - cell.x);
  // float varyTemp = 0.5 * sqrt(abs(cell.y - cell.x));
  float varyTemp = 1.0 - 5.0 * RidgedMultifractal(p, 16.0);
  noiseOctaves = 3;
  float globTemp = 0.95 - abs(Fbm((p + dist) * 0.01)) * 0.08;
  noiseOctaves = 8;
  // float varyTemp = abs(Fbm(p + dist));
  // globTemp *= 1.0 - lithoCells;

  // Copied from height shader, for extra detail
  float venus = 0.0;

  noiseOctaves = 4;
  noiseH = 0.9;
  vec3 distort = Fbm3D(point * 0.3) * 1.5;
  noiseOctaves = 6;
  venus = Fbm((point + distort) * 1.0) * (0.3);

  float surfTemp = surfTemperature * (globTemp + venus * varyTemp * 0.08) *
                   saturate(2.0 * (lavaCoverage * 0.4 + 0.4 - 0.8 * height));

  surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
  return vec4(surfTemp);
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height = 0, slope = 0;
  GetSurfaceHeightAndSlope(height, slope);
  OutColor = GlowMapAsteroid(point, height, slope);
}

//-----------------------------------------------------------------------------

#endif
