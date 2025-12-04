#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   HeightMapFogGasGiant(vec3 point)
{
    return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

void main() {
	// GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();
	if (cloudsLayer == 0.0) {
    	OutColor = GetGasGiantCloudsColor(height);
	} else {
        float height = HeightMapFogGasGiant(GetSurfacePoint());
        OutColor.rgb = height * GetGasGiantCloudsColor(1.0).rgb;
        OutColor.a = 1.0;
	}
	
	
	// GlobalModifier // Change cloud alpha channel
	   // Changed lowest cloud layer to be full alpha // by Sp_ce
	// centri
    //OutColor.a *= 0.5;
	
	// sp_ce
	if (cloudsLayer == 0) {
		OutColor.a = 1.0; 
	}
	else {
		OutColor.a *= 0.5;
	}


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
