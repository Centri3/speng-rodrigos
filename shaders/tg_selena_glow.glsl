#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec4  GlowMapSelena(vec3 point, float height, float slope)
{
	// Thermal emission temperature (in thousand Kelvins)
    noiseOctaves = 5;
    vec3  p = point * 600.0 + Randomize;
    float dist = 10.0 * colorDistMagn * Fbm(p * 0.2);
    noiseOctaves = 3;
	float globTemp = 0.95 - abs(Fbm((p + dist) * 0.01)) * 0.08;
    noiseOctaves = 8;
	float varyTemp = abs(Fbm(p + dist));  //surfTemperature

	// Global surface melting
	float surfTemp = surfTemperature *
		(globTemp + varyTemp * 0.08) *
		saturate(2.0 * (lavaCoverage * 0.4 + 0.4 - 5 * height)) *
		saturate((lavaCoverage - 0.01) * 25.0);


	// Global lava Cover
float lavaTemp = volcanoTemp;

if (surfTemperature > volcanoTemp || lavaCoverage == 0)
	{
		lavaTemp = surfTemperature;
	}
if (lavaCoverage > 0)
{
     surfTemp = (lavaTemp) *
        (globTemp + varyTemp * 0.08) *
        saturate(2 * (lavaCoverage * 0.4 + 0.4 - 5 * height)) *
		saturate((lavaCoverage - 0.01) * 25.0);
}

if (height < 0.00001 && lavaCoverage > 0)
{	
	surfTemp = lavaTemp *
		(globTemp + varyTemp * 0.08) * saturate((0.00001-height) * 200000.0);
		//saturate(1.0 * (lavaCoverage * 0.4 + 0.4 - 5000 * height));// *
		//saturate((lavaCoverage - 0.01) * 25.0);
}


    // Io-like volcanoes
    //float volcIo = saturate(abs(Fbm(point * 6.3 + Randomize) * 1.4)); // * 1.4 * volcActivity));
    //surfTemp = max(surfTemp, volcIo * (0.75 + 0.25 * varyTemp));

    // Shield volcano lava
    if (volcanoOctaves > 0)
    {
        // Global volcano activity mask
        noiseOctaves = 3;
        float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
        // Lava in the volcano caldera and lava flows
		vec2  volcMask = _VolcanoGlowNoise(point);
        volcMask.x *= (0.75 + 0.25 * varyTemp) * volcActivity * volcanoTemp;
	    surfTemp = max(surfTemp, volcMask.x);
    }

    surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
	return vec4(surfTemp);
}

//-----------------------------------------------------------------------------

void main()
{
    vec3  point = GetSurfacePoint();
    float height =  - lavaCoverage, slope = 0;
    GetSurfaceHeightAndSlope(height, slope);
    OutColor = GlowMapSelena(point, height, slope);
}

//-----------------------------------------------------------------------------

#endif

