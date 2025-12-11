#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec4 asteroid_glowmap(vec3 point, float height, float slope) {
  vec3 p = point * 6.0 + Randomize;
  float dist = 10.0 * colorDistMagn *
               noise_fbm_float(
                   p * 0.2, mk_noise(Octaves(5), DEFAULT_LACUNARITY, H(0.3)));
  float varyTemp = 1.0 - 5.0 * RidgedMultifractal(p, 16.0);
  float globTemp =
      0.95 -
      abs(noise_fbm_float((p + dist) * 0.01,
                          mk_noise(Octaves(3), DEFAULT_LACUNARITY, H(0.3)))) *
          0.08;

  // Copied from height shader, for extra detail
  float venus = 0.0;

  vec3 distort =
      noise_fbm_vec3(point * 0.3,
                     mk_noise(Octaves(4), DEFAULT_LACUNARITY, H(0.9))) *
      1.5;
  venus = noise_fbm_float((point + distort) * 1.0,
                          mk_noise(Octaves(6), DEFAULT_LACUNARITY, H(0.9))) *
          (0.3);

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
  OutColor = asteroid_glowmap(point, height, slope);
}

//-----------------------------------------------------------------------------

#endif
