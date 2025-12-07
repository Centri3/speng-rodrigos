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
