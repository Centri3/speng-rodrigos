#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
	// GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();
    OutColor = pow(GetGasGiantCloudsColor(height), vec4(height));
	
	
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
		vec3 color = height * GetGasGiantCloudsColor(1.0).rgb;
		float minColor = min(min(color.r, color.g), color.b);
		float maxColor = max(max(color.r, color.g), color.b);
		float averageMinMax = (minColor + maxColor) / 2.0; // Calculate average of min and max color
		OutColor.rgb = mix(vec3(averageMinMax), color, 0.7);
		OutColor.a *= 0.5 * dot(OutColor.rgb, vec3(0.2126, 0.7152, 0.0722));
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
