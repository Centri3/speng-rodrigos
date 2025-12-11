#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec4 ColorMapAsteroid(vec3 point, float height, float slope) {
  float _hillsMagn = hillsMagn;
  if (hillsMagn < 0.05) {
    _hillsMagn = 0.05;
  }

  noiseOctaves = 5.0;
  height = DistFbm(point * 3.7 + Randomize, 1.5);

  noiseOctaves = 5.0;
  vec3 p = point * colorDistFreq * 2.3;
  p += Fbm3D(p * 0.5) * 1.2;
  float vary = saturate((Fbm(p) + 0.7) * 0.7);

  // Scale detail texture UV and add a small distortion to it to fix
  // pixelization
  vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
  noiseOctaves = 4.0;
  vec2 shatterUV = Fbm2D2(detUV * 16.0) * (16.0 / 512.0);
  detUV += shatterUV;

  Surface surf = GetBaseSurface(height, detUV);

  surf.color.rgb *= 0.5 + slope;
  return surf.color;
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height = 0, slope = 0;
  GetSurfaceHeightAndSlope(height, slope);
  OutColor = ColorMapAsteroid(point, height, slope);
  OutColor.rgb = pow(OutColor.rgb, colorGamma);
  // OutColor2 = vec4(height, slope, 0.0, 1.0);
}

//-----------------------------------------------------------------------------

#endif
