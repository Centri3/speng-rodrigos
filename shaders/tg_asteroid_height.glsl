#include "tg_common.glh"

#ifdef _FRAGMENT_


//-----------------------------------------------------------------------------


// Function // Altered Crater Height Formula
float   _CraterHeightFunc(float lastlastLand, float lastLand, float height, float r)
{
    float distHeight = craterDistortion * height;

    float t = 1.0 - r/radPeak;
    float peak = heightPeak * craterDistortion * smoothstep(0.0, 1.0, t);

    t = smoothstep(0.0, 1.0, (r - radInner) / (radRim - radInner));
    float inoutMask = t*t*t;
    float innerRim = heightRim * distHeight * smoothstep(0.0, 1.0, inoutMask);

    t = smoothstep(0.0, 1.0, (radOuter - r) / (radOuter - radRim));
    float outerRim = distHeight * mix(0.05, heightRim, t*t);

    t = saturate((1.0 - r) / (1.0 - radOuter));
    float halo = 0.05 * distHeight * t;

    return mix(lastlastLand + height * heightFloor + peak + innerRim, lastLand + outerRim + halo, inoutMask);
}


//-----------------------------------------------------------------------------


// Function // Altered Crater Noise
float   _CraterNoise(vec3 point, float cratMagn, float cratFreq, float cratSqrtDensity, float cratOctaves)
{
    //craterSphereRadius = cratFreq * cratSqrtDensity;
    //point *= craterSphereRadius;
    point = (point * cratFreq + Randomize) * cratSqrtDensity;

    float  newLand = 0.0;
    float  lastLand = 0.0;
    float  lastlastLand = 0.0;
    float  lastlastlastLand = 0.0;
    float  amplitude = 1.0;
    float  cell;
    float  radFactor = 1.0 / cratSqrtDensity;

    // Craters roundness distortion
    noiseH           = 0.5;
    noiseLacunarity  = 2.218281828459;
    noiseOffset      = 0.8;
    noiseOctaves     = 3;
    craterDistortion = 1.0;
    craterRoundDist  = 0.03;

    radPeak  = 0.0; //0.03;
    radInner = 0.0; //0.15;
    radRim   = 0.0; //0.2;
    radOuter = 0.0; //0.8;

    for (int i=0; i<cratOctaves; i++)
    {
        lastlastlastLand = lastlastLand;
        lastlastLand = lastLand;
        lastLand = newLand;

        //vec3 dist = craterRoundDist * Fbm3D(point*2.56);
        //cell = Cell2NoiseSphere(point + dist, craterSphereRadius, dist).w;
        //craterSphereRadius *= 1.83;
        cell = Cell3Noise(point + craterRoundDist * Fbm3D(point * 2.56));
        newLand = _CraterHeightFunc(lastlastlastLand, lastLand, amplitude, cell * radFactor);

        //cell = inverseSF(point + 0.2 * craterRoundDist * Fbm3D(point*2.56), fibFreq);
        //rad = hash1(cell.x * 743.1) * 0.9 + 0.1;
        //newLand = CraterHeightFunc(lastlastlastLand, lastLand, amplitude, cell.y * radFactor / rad);
        //fibFreq   *= craterFreqPower;
        //radFactor *= craterRadFactorPower;

        if (cratOctaves > 1)
        {
            point       *= craterFreqPower;
            amplitude   *= craterAmplPower;
            heightPeak  *= craterPeakPower;
            heightFloor *= craterFloorPower;
            radInner    *= craterRadiusPower;
        }
    }

    return  cratMagn * newLand;
}


//-----------------------------------------------------------------------------


// Function // Construct Height Map
float   HeightMapAsteroid(vec3 point)
{
    // GlobalModifier // Global landscape
    vec3  p = point * venusFreq + Randomize;
    float height = venusMagn * (0.5 - Noise(p) * 2.0);

    noiseOctaves = 10;
    noiseLacunarity = 2.0;
    height += 0.05 * iqTurbulence(point * 2.0 * mainFreq + Randomize, 0.35);



    // TerrainFeature // Hills
    noiseOctaves = 5;
    noiseLacunarity  = 2.218281828459;
    float hills = (0.5 + 1.5 * Fbm(p * 0.0721)) * hillsFreq;
    hills = Fbm(p * hills) * 0.15;
    noiseOctaves = 2;
    float hillsMod = smoothstep(0.0, 1.0, Fbm(p * hillsFraction) * 3.0);
    height *= 1.0 + hillsMagn * hills * hillsMod;



    // TerrainFeature // Craters
    heightFloor = -0.1;
    heightPeak  =  0.6;
    heightRim   =  0.4;
	//float crater = 0.4 * CraterNoise(point, craterMagn, craterFreq, craterSqrtDensity, craterOctaves);
    float crater = 1.0 * CraterNoise(point, craterMagn, craterFreq, craterSqrtDensity, craterOctaves);

    noiseOctaves = 10;
    noiseLacunarity = 2.0;
	//crater += montesMagn * crater * iqTurbulence(point * montesFreq, 0.52);	
    crater = 0.4 * crater + 0.15 * crater * iqTurbulence(point * montesFreq + Randomize, 0.55);

    height += crater;



    // TerrainFeature // Equatorial ridge 
    if (eqridgeMagn > 0.0)
    {
        noiseOctaves = 4.0;
        float x = point.y / eqridgeWidth;
        float ridgeHeight = exp(-0.5 * x*x);
        float ridgeModulate = saturate(1.0 - eqridgeModMagn * (Fbm(point * eqridgeModFreq - Randomize) * 0.5 + 0.5));
        height += eqridgeMagn * ridgeHeight * ridgeModulate;
    }



    // GlobalModifier // Soften max/min height
    height = softPolyMin(height, 0.99, 0.3);
    height = softPolyMax(height, 0.01, 0.3);



	// Return height
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
