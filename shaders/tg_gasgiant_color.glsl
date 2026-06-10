#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float HeightMapFogGasGiant(vec3 point) {
  return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

float CycloneColorGasGiantAli(vec3 point) {
  vec3 rotVec = normalize(Randomize);
  vec3 twistedPoint = point;
  vec3 cellCenter = vec3(0.0);
  vec2 cell;
  float r, fi, rnd, dist, dist2, dir;
  float offset = 0.0;
  float offs = 0.5 / (cloudsLayer + 1.0);
  float squeeze = 1.9;
  float strength = 10.0;
  float freq = cycloneFreq * 30.0;
  float dens = cycloneDensity * 0.02;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);

  for (int i = 0; i < cycloneOctaves; i++) {
    cell = inverseSF(vec3(point.x, point.y * squeeze, point.z),
                     freq + cloudsLayer, cellCenter);
    rnd = hash1(cell.x);
    r = size * cell.y;

    if ((rnd < dens)) {
      dir = sign(0.7 * dens - rnd);
      dist = saturate(1.0 - r);
      dist2 = saturate(0.3 - r);
      fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.5);
      twistedPoint =
          Rotate(cycloneMagn * dir * sign(cellCenter.y + 0.001) * fi * 3.0,
                 cellCenter.xyz, point);
      offset += offs * fi * dir * 16.0;
    }

    freq = min(freq * 2.0, 6400.0);
    dens = min(dens * 3.5, 0.3);
    size = min(size * 1.5, 15.0);
    offs = offs * 0.5;
    squeeze = max(squeeze - 0.3, 1.0);
    strength = max(strength * 1.3, 0.5);
    point = twistedPoint;
  }

  return offset;
}

//-----------------------------------------------------------------------------

vec3 GasGiantColorsTPE(vec3 point) {
	// GlobalModifier // Convert height to color
    float height;
	float slope;
	GetSurfaceHeightAndSlope(height, slope);
	// Don't go crazy with stripeFluct on venuslikes.
	float gaseousBuff = volcanoActivity != 0.0 ? 1.0 : 4.0;
    OutColor = 0.5 * GetGasGiantCloudsColor(max(height * stripeFluct * 0.5 * gaseousBuff, 1.0 - float(BIOME_CLOUD_LAYERS - 1) / float(BIOME_SURF_LAYERS))) + 0.5 * GetGasGiantCloudsColor(min(height * stripeFluct * 0.5 * gaseousBuff, 0.7 - float(BIOME_CLOUD_LAYERS - 1) / float(BIOME_SURF_LAYERS)));
	OutColor.rgb = (pow(OutColor.rgb, vec3(height * stripeFluct * gaseousBuff)));

	/*
	OutColor = rgb_to_lch(OutColor);
	vec4 cycloneColor = texture(BiomeDataTable, vec2(1.0, 0.0)); // always the first cloud layer
	OutColor.rgb = mix(OutColor.rgb, rgb_to_lch(cycloneColor).rgb, saturate(abs(CycloneColorGasGiantAli(point))));
	OutColor.r = OutColor.r * min(height, 0.5) + 50.0;
	OutColor.g *= 1.25;
	OutColor = lch_to_rgb(OutColor);
	*/
	
	if (volcanoActivity != 0.0)
	{
		float latitude = abs(GetSurfacePoint().y);
		// Drown out poles
		OutColor.rgb = mix(GetGasGiantCloudsColor(hash1(Randomize.x) * 0.333 + hash1(Randomize.y) * 0.333 + hash1(Randomize.z) * 0.333).rgb, OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.1)));
	}
	
	// TPE
	if (cloudsLayer == 0) {
		// OutColor.rgb = 5.0 * height * GetGasGiantCloudsColor(height).rgb;
        vec3 color = 4.0 * height * GetGasGiantCloudsColor(height * stripeFluct * 0.2 * gaseousBuff).rgb;
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
    return OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

vec3 GasGiantColorsRMR(vec3 point) {
    // GlobalModifier // Convert height to color
    float height = GetSurfaceHeight();	
	float boost = 5 + Randomize.z;
	
	if (height >= 1/(boost))  //Height without boost can't go over 1.357 with boosts
	{
		height = 1/(boost);
	}
	OutColor = _GetGasGiantCloudsColor(max(height * boost, 1 - float(BIOME_CLOUD_LAYERS + 5) / float(BIOME_SURF_LAYERS))) * 0.3 + 0.4 * _GetGasGiantCloudsColor(height * boost);

	height = GetSurfaceHeight();
	vec4 OutColor2 = _GetGasGiantCloudsColor(max(height, 1 - float(BIOME_CLOUD_LAYERS - 1 + Randomize.z) / float(BIOME_SURF_LAYERS))) * 0.3 + 0.4 * GetGasGiantCloudsColor(min(height, 0.7 - float(BIOME_CLOUD_LAYERS - 1) / float(BIOME_SURF_LAYERS)));
	// OutColor = OutColor * (0.8 * height + 0.1) + OutColor2 * (-0.8 * height + 0.9);
	// OutColor = OutColor * (0.6 * height + 0.2) + OutColor2 * (-0.6 * height + 0.8);
	OutColor = OutColor * (0.4 * height + 0.3) + OutColor2 * (-0.4 * height + 0.7);
	// OutColor = OutColor;
	if (volcanoActivity != 0.0) 
	{
		//OutColor = GetGasGiantCloudsColor(max(height, 1.0 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)))*0.3+0.4*GetGasGiantCloudsColor(min(height, 0.7 - float(BIOME_CLOUD_LAYERS-1) / float(BIOME_SURF_LAYERS)));
		height = height / 3;
	}
	
	OutColor.rgb = (pow(OutColor.rgb, vec3(height * 3)));

	// GlobalModifier // Change cloud alpha channel
	   // Changed lowest cloud layer to be full alpha // by Sp_ce
	if (cloudsLayer == 0) {
		//OutColor = GetGasGiantCloudsColor(height);
		OutColor.a = 1.0; 
	}
	else {
		float height = HeightMapFogGasGiant(GetSurfacePoint());
        OutColor.rgb = height * tpeGetGasGiantCloudsColor(1.0).rgb;
        OutColor.a = 1.0;
	}
	/*
	//polar suppression  uncomment for full Centri Venus-likes
	if (volcanoActivity != 0.0)
	{
		float latitude = abs(GetSurfacePoint().y);
		// Drown out poles
		OutColor.rgb = mix(GetGasGiantCloudsColor(0.0).rgb, OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.3)));
	}
	*/
	// GlobalModifier // Output color
    return OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

void main()
{
	if (cloudsLayer == 0.0)
	{
		vec3  point = GetSurfacePoint();
		OutColor.rgb = GasGiantColorsRMR(point);
		OutColor.a = 1.0;
	}
	else
	{
		vec3  point = GetSurfacePoint();
		OutColor.rgb = GasGiantColorsTPE(point);
		OutColor.a = 0.5;
	}
}

//-----------------------------------------------------------------------------

#endif
