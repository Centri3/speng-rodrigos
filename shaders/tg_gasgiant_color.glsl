#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
    // GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();
    OutColor = GetGasGiantCloudsColor(min(height, 1.0 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)));
	OutColor.rgb = pow(OutColor.rgb, vec3(height));

	// GlobalModifier // Change cloud alpha channel
	   // Changed lowest cloud layer to be full alpha // by Sp_ce
	if (cloudsLayer == 0) {
		OutColor.a = 1.0; 
	}
	else {
		OutColor.a *= 0.5;
	}


	// GlobalModifier // Output color
    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
