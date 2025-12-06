#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   HeightMapAsteroid(vec3 point)
{
    float _hillsMagn = hillsMagn;
    if (hillsMagn < 0.05)
    {
        _hillsMagn = 0.05;
    }

    // Global landscape
    vec3  p = point * venusFreq + Randomize;
    float height = venusMagn * (0.5 - Noise(p) * 2.0);

    noiseOctaves = 10;
    noiseLacunarity = 2.0;
    height += 0.05 * iqTurbulence(point * 2.0 * mainFreq + Randomize, 0.35);

    // Hills
    noiseOctaves = 5;
    noiseLacunarity  = 2.218281828459;
    float hills = (0.5 + 1.5 * Fbm(p * 0.0721)) * hillsFreq;
    hills = Fbm(p * hills) * 0.15;
    noiseOctaves = 2;
    float hillsMod = smoothstep(0.0, 1.0, Fbm(p * hillsFraction) * 3.0);
    height *= 1.0 + _hillsMagn * hills * hillsMod;

    // Craters
    heightFloor = -0.1;
    heightPeak  =  0.6;
    heightRim   =  0.4;
    float crater = 0.4 * CraterNoise(point, craterMagn, craterFreq, craterSqrtDensity, craterOctaves);

    noiseOctaves = 10;
    noiseLacunarity = 2.0;
	crater += montesMagn * crater * iqTurbulence(point * montesFreq, 0.52);	

    height += crater;

    // Equatorial ridge
    if (eqridgeMagn > 0.0)
    {
        noiseOctaves = 4.0;
        float x = point.y / eqridgeWidth;
        float ridgeHeight = exp(-0.5 * x*x);
        float ridgeModulate = saturate(1.0 - eqridgeModMagn * (Fbm(point * eqridgeModFreq - Randomize) * 0.5 + 0.5));
        height += eqridgeMagn * ridgeHeight * ridgeModulate;
    }

    // smoothly limit the height
    height = softPolyMin(height, 0.99, 0.3);
    height = softPolyMax(height, 0.01, 0.3);

    return height;
}

//-----------------------------------------------------------------------------

void main()
{
    float height = HeightMapAsteroid(GetSurfacePoint());
    OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif
