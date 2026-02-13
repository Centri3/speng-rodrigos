#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float HeightMapFogGasGiant(vec3 point) {
  return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

void main() {
	// GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();
    OutColor = 0.1 * GetGasGiantCloudsColor(max(height * stripeFluct * 0.5, 1.0 - float(BIOME_CLOUD_LAYERS - 1) / float(BIOME_SURF_LAYERS))) + 0.1 * GetGasGiantCloudsColor(min(height * stripeFluct * 0.5, 0.7 - float(BIOME_CLOUD_LAYERS - 1) / float(BIOME_SURF_LAYERS)));
	OutColor.rgb = (pow(OutColor.rgb, vec3(height * stripeFluct)));
	
	// GlobalModifier // Change cloud alpha channel
	   // Changed lowest cloud layer to be full alpha // by Sp_ce
	// centri
    //OutColor.a *= 0.5;
	
	// TPE
	if (cloudsLayer == 0) {
		// OutColor.rgb = 5.0 * height * GetGasGiantCloudsColor(height).rgb;
        vec3 color = 4.0 * height * GetGasGiantCloudsColor(height).rgb;
		float minColor = min(min(color.r, color.g), color.b);
		float maxColor = max(max(color.r, color.g), color.b);
		float averageMinMax = (minColor + maxColor) / 2.0; // Calculate average of min and max color
		OutColor.rgb = mix(vec3(averageMinMax), color, 0.85);
		OutColor.a = 1.0 * dot(OutColor.rgb, vec3(0.299, 0.587, 0.114)); 
	}
	else {
        // OutColor.rgb = height * GetGasGiantCloudsColor(5.0).rgb;
		float height = HeightMapFogGasGiant(GetSurfacePoint());
		vec3 color = height * GetGasGiantCloudsColor(1.0).rgb;
		float minColor = min(min(color.r, color.g), color.b);
		float maxColor = max(max(color.r, color.g), color.b);
		float averageMinMax = (minColor + maxColor) / 2.0; // Calculate average of min and max color
		OutColor.rgb = mix(vec3(averageMinMax), color, 0.7);
		OutColor.a *= 0.5 * dot(OutColor.rgb, vec3(0.2126, 0.7152, 0.0722));
	}
	
	if (volcanoActivity != 0.0)
	{
		float latitude = abs(GetSurfacePoint().y);
		// Drown out poles
		OutColor.rgb = mix(GetGasGiantCloudsColor(0.0).rgb, OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.1)));
	}

	// OutColor.rgb = height * GetGasGiantCloudsColor(0.85).rgb;

	// GlobalModifier // Change alpha for certain layers
	//centri
    //if (OutColor.a == 0.0) {
    //    OutColor.a = 1.0;
    //}
	
	//sp_ce
	//
	
	//sp_ce 2
	//if  (cloudsLayer != 0) {
    //    OutColor.a *= 5.0;
    //}


	// Output color
    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
