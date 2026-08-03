#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   _HeightMapSun(vec3 point)
{
    // Flows
    noiseOctaves = 5;
    vec3  p = point * sunFlowDistFreq + Randomize;
    vec3  dist = 2.5 * Fbm3D(p * 0.5);
    noiseOctaves = 3;
    float flows = Fbm(p * 7.5 + dist);

    // Granularity
    noiseOctaves    = sunGranOctaves;
    noiseLacunarity = 2.218281828459;
    noiseH          = 0.8;
    p = point * sunGranFreq + Randomize;
    dist = sunGranDistort * Fbm3D(p * 0.2);
    vec2  cell = Cell3Noise2(p + dist);
    float gran = smoothstep(0.1, 1.0, sqrt(abs(cell.y - cell.x))) - 0.5;

    // Solar spots
    float botMask = 1.0;
    float filMask = 0.0;
    float filaments = 0.0;
    if (sunSpotSqrtDensity > 0.01)
    {
        noiseOctaves = 5;
        SolarSpotsHeightNoise(point, botMask, filMask, filaments);
    }

    const float surfHeight = 1.0;
    const float filHeight  = 0.6;
    const float spotHeight = 0.5;

    //float height = (flows * 0.1 + gran * (1.0 - filMask)) * mix(spotHeight, surfHeight, botMask) + filMask * mix(spotHeight, filHeight, filaments);
    //float height = (0.8 + flows * 0.1) * botMask + gran * 0.03 * (1.0 - filMask) + saturate(filaments) * 0.1 * filMask;
    float height = (0.8 + flows * 0.1) * sunFlowMagn * botMask + gran * sunGranMagn * (1.0 - filMask) + saturate(filaments) * 0.1 * sunGranMagn * filMask;

    // smoothly limit the height
    height = softPolyMin(height, 0.99, 0.3);
    height = softPolyMax(height, 0.01, 0.3);

    return height;
}

//-----------------------------------------------------------------------------

void main()
{
    vec3  point  = GetSurfacePoint();
    float height = _HeightMapSun(point);
    OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif
