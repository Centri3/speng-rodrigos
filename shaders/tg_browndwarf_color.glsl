#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float   HeightMapFogGasGiant(vec3 point)
{
    return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

void main() {
    // GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();	
	float boost = 5 + Randomize.z;
	
	if (height >= 1/(boost))  //Height without boost can't go over 1.357 with boosts
	{
	 height = 1/(boost);
	}
	
	OutColor = _GetGasGiantCloudsColor(max(height*boost, 1 - float(BIOME_CLOUD_LAYERS+5) / float(BIOME_SURF_LAYERS)))*0.3+0.4*_GetGasGiantCloudsColor(height*boost);
	
	height = GetSurfaceHeight();
	vec4 OutColor2 = GetGasGiantCloudsColor(max(height, 1 - float(BIOME_CLOUD_LAYERS+2*Randomize.z) / float(BIOME_SURF_LAYERS)))*0.3+0.4*GetGasGiantCloudsColor(min(height, 0.7 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)));
		
		
	//Original Blended function (Comment out for harsh gas giant colors)
	//OutColor = OutColor * (0.8*height+0.1) + OutColor2 * (-0.8*height+0.9);
	
	//Reduced blend function
	if (GasGiantColor == 0 &&  cracksOctaves <= 0 ||cracksOctaves == 3 || cracksOctaves == 4)
	{
	OutColor = OutColor * (0.6*height+0.2) + OutColor2 * (-0.6*height+0.8);
	}
	
	//Hard Function only (Uncomment for harsh gas giant colors)
	OutColor = OutColor;
	
	OutColor.rgb = (pow(OutColor.rgb, vec3(height*3)));

	// GlobalModifier // Change cloud alpha channel
	   // Changed lowest cloud layer to be full alpha // by Sp_ce
OutColor.a = 1.0 * dot(OutColor.rgb, vec3(0.299, 0.587, 0.114));
/*
if (volcanoActivity != 0.0) {   //polar suppression  uncomment for full Centri Venus-likes
    float latitude = abs(GetSurfacePoint().y);
    // Drown out poles
    OutColor.rgb = mix(GetGasGiantCloudsColor(0.0).rgb, OutColor.rgb,
                       1.0 - vec3(saturate(latitude - 0.3)));
  }
*/
	// GlobalModifier // Output color
    if (GasGiantVibe == 0 &&  cracksOctaves <= 0||cracksOctaves == 1 || cracksOctaves == 3)
	{
	OutColor.rgb *= pow(OutColor.rgb, colorGamma);
	}
	else
	{
	OutColor.rgb = pow(OutColor.rgb, colorGamma);
	}
}

//-----------------------------------------------------------------------------

#endif
