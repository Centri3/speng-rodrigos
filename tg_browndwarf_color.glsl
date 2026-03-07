#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main()
{
    float height = GetSurfaceHeight();
    OutColor = GetGasGiantCloudsColor(max(height, 1.0 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)))*0.3+0.4*GetGasGiantCloudsColor(min(height, 0.7 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)));
	OutColor.rgb = (pow(OutColor.rgb, vec3(height*3)));

    //float a = cloudsLayer - height;
    //OutColor.a = exp(-55.0 * a * a) * cloudsCoverage;
    OutColor.a = 1.0 * dot(OutColor.rgb, vec3(0.299, 0.587, 0.114));

    OutColor.rgb *= pow(OutColor.rgb, colorGamma);
    //OutColor2 = vec4(0.0);
}

//-----------------------------------------------------------------------------

#endif
