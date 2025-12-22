#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

// Function // Fixed GetBaseSurface with default seaLevel with an on average
// increased amount of colors
Surface _GetBaseSurface(float height, vec2 detUV) {
  float _seaLevel = seaLevel;
  if (seaLevel == -1e+38) {
    _seaLevel = 0.6;
  }

  float h = (height * 6.0 - _seaLevel) / (1.0 - _seaLevel) *
                float(BIOME_ROCK - BIOME_BEACH + 1) +
            float(BIOME_BEACH);
  int h0 = clamp(int(floor(h)), 0, BIOME_ROCK);
  int h1 = clamp(h0 + 1, 0, BIOME_ROCK);
  float dh = fract(h);

  // interpolate between two heights
  Surface surfH0 = DetailTextureMulti(detUV, h0);
  Surface surfH1 = DetailTextureMulti(detUV, h1);
  return BlendMaterials(surfH0, surfH1, dh);
}

//-----------------------------------------------------------------------------

vec4 ColorMapAsteroid(vec3 point, in BiomeData biomeData) {
  float _hillsMagn = hillsMagn;
  if (hillsMagn < 0.05) {
    _hillsMagn = 0.05;
  }

  noiseH = 0.1;
  noiseOctaves = 5.0;

  noiseOctaves = 5.0;
  vec3 p = point * colorDistFreq * 2.3;
  p += Fbm3D(p * 0.5) * 1.2;
  float vary = saturate((Fbm(p) + 0.7) * 0.7);

  // GlobalModifier // ColorVary setup
  vec3 zz =
      (point + Randomize) * (0.0005 * hillsFreq / (_hillsMagn * _hillsMagn));
  noiseOctaves = 14.0;
  noiseH = smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
  vec3 albedoVaryDistort =
      Fbm3D((point + Randomize) * 0.07) * (1.5 + venusMagn);
  vary = 1.0 - Fbm((point + albedoVaryDistort) *
                   (1.5 - RidgedMultifractal(zz, 8.0) +
                    RidgedMultifractal(zz * 0.999, 8.0)));

  // Scale detail texture UV and add a small distortion to it to fix
  // pixelization
  vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
  noiseOctaves = 4.0;
  vec2 shatterUV = Fbm2D2(detUV * 16.0) * (16.0 / 512.0);
  detUV += shatterUV;

  float _height = biomeData.height;
  Surface surf = _GetBaseSurface(_height, detUV);

  // GlobalModifier // ColorVary apply
  surf.color.rgb *= mix(colorVary, vec3(1.0), vary);

  // GlobalModifier // Slope contrast
  surf.color.rgb *= 0.9 + biomeData.slope * 0.3;

  return surf.color;
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  BiomeData biomeData = GetSurfaceBiomeData();
  OutColor = ColorMapAsteroid(point, biomeData);
  OutColor.rgb = pow(OutColor.rgb, colorGamma);
  // OutColor2 = vec4(height, slope, 0.0, 1.0);
}

//-----------------------------------------------------------------------------

#endif
