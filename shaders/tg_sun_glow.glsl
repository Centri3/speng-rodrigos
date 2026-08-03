#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   _GlowMapSun(vec3 point)
{
    // Flows
    noiseOctaves = 5;
    vec3  p = point * sunFlowDistFreq + Randomize;
    vec3  dist = 2.5 * Fbm3D(p * 0.5);
    noiseOctaves = 3;
    float flows = sunGranMagn * Fbm(p * 7.5 + dist); // TODO: replace sunGranMagn with independent parameter!

    // Granularity
    noiseOctaves    = sunGranOctaves;
    noiseLacunarity = 2.218281828459;
    noiseH          = 0.5;
    p = point * sunGranFreq + Randomize;
    dist = sunGranTempDistort * Fbm3D(p * 0.2);     // Rd giants: sunGranTempDistort == sunGranDistort to make temp pattern match heights
    vec2  cell = Cell3Noise2(p + dist);
    float gran = smoothstep(0.1, 1.0, sqrt(abs(cell.y - cell.x)));   //1-pow(abs((-JordanTurbulence(point * 10.0 + Randomize, 1.1, 0.9, 0.9, 0.8, 0.3, 0.3, 1.7) * 1.5) - JordanTurbulence(point * 3.0 + Randomize, 1.1, 0.9, 0.9, 0.8, 0.3, 0.3, -1.7) * 0.3) * 0.28, 1.5)

    // Solar spots
    float botMask   = 1.0;
    float filMask   = 0.0;
    float filaments = 0.0;
    if (sunSpotSqrtDensity > 0.01)
    {
        noiseOctaves = 5;
        SolarSpotsTempNoise(point, botMask, filMask, filaments);
    }

	float spotTempOffset = 1.27944 * pow(0.999889, lavaParams.z * 1000.0);
    float surfTemp = 1.0;
    float filTemp  = sunGranTopTemp;
    float spotTemp = sunGranBotTemp * clamp(spotTempOffset, 0.1, 0.95);
	
	float granTemp  = mix(sunGranBotTemp, sunGranTopTemp, gran);
	float umbraTemp = mix(sunGranBotTemp, sunGranTopTemp, pow(saturate(2.0 * gran - 1.0), 4.0));

    return (flows + mix(sunGranBotTemp, sunGranTopTemp, gran) * (1.0 - filMask)) * mix(spotTemp, surfTemp, botMask) + filMask * mix(spotTemp, filTemp, filaments);
}

//-----------------------------------------------------------------------------

void main()
{
    vec3  point = GetSurfacePoint();
    float surfTemp = _GlowMapSun(point) * surfTemperature; // in thousand Kelvins
    surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
	OutColor = vec4(surfTemp);
}

//-----------------------------------------------------------------------------

#endif
