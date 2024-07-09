#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   _HeightMapCloudsGasGiant(vec3 point)
{
    vec3  twistedPoint = point;

    // Compute zones
    vec3  zonePoint = Randomize * 7.1563;
    zonePoint.y += twistedPoint.y * stripeZones * 0.5;
    float zones = Noise(zonePoint) * 0.6 + 0.25;
    float offset = 0.0;

    // Compute cyclons
    if (cycloneOctaves > 0.0)
        twistedPoint = CycloneNoiseGasGiant(twistedPoint, offset);

    // Compute turbulence
    twistedPoint = TurbulenceGasGiant(twistedPoint);

    // Compute stripes
    noiseOctaves = cloudsOctaves;
    float turbulence = Fbm(twistedPoint * 3.6);
    twistedPoint = twistedPoint * (0.00515 * cloudsFreq) - turbulence * 0.001;
	//twistedPoint = twistedPoint * (0.05 * cloudsFreq) + Randomize;
    twistedPoint.y *= 100.0 + turbulence;
    float height = stripeFluct * (Fbm(twistedPoint) * 0.7 + 0.5);



    return zones + height + offset;
}

//-----------------------------------------------------------------------------

float   _HeightMapCloudsGasGiant2(vec3 point)


{
    vec3  twistedPoint = point;

    // Compute zones
    vec3  zonePoint = Randomize * 7.1563;
    zonePoint.y += twistedPoint.y * stripeZones * 0.5;
    float zones = Noise(zonePoint) * 0.6 + 0.25;
    float offset = 0.0;

    // Compute cyclons
    if (cycloneOctaves > 0.0)
        twistedPoint = CycloneNoiseGasGiant(twistedPoint, offset);

    // Compute turbulence
    twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute stripes
    noiseOctaves = cloudsOctaves;
    float turbulence = Fbm(twistedPoint * 1.2);
    twistedPoint = twistedPoint * (0.00515 * cloudsFreq) - turbulence * 0.001;
	//twistedPoint = twistedPoint * (0.05 * cloudsFreq) + Randomize;
    twistedPoint.y *= 100.0 + turbulence;
    float height = stripeFluct * (Fbm(twistedPoint) * 1.7 + 0.5);

    return zones + height + offset;
}

//-----------------------------------------------------------------------------

void main()
{
    if (cloudsLayer == 0.0)
    {
        vec3  point = GetSurfacePoint();
        float height = 1.6*(0.5 * _HeightMapCloudsGasGiant(point))+ (0.5 * HeightMapCloudsGasGiant(point));
        OutColor = vec4(height);
    }
    else
        OutColor = vec4(0.0);
}

//-----------------------------------------------------------------------------

#endif
