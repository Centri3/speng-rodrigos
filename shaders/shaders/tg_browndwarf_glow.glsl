#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main()
{
    vec3  point = GetSurfacePoint();
    float surfTempS = GlowMapSun(point); // in thousand Kelvins

    float height = GetSurfaceHeight();
    float surfTempB = mix(1.0, GetGasGiantCloudsColor(height).a, cloudsLayer);
    surfTempB *= (1.0 - 0.2 * height);

    float surfTemp = mix(surfTempB, surfTempS, erosion) * surfTemperature; // in thousand Kelvins

		
    surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
	OutColor = vec4(surfTemp);
}

//-----------------------------------------------------------------------------

#endif
