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
  OutColor =
      GetGasGiantCloudsColor(max(height * stripeFluct * 0.5, 1.0 - float(BIOME_CLOUD_LAYERS - 1) /
                                                   float(BIOME_SURF_LAYERS))) *
          0.3 +
      0.4 * GetGasGiantCloudsColor(
                min(height * stripeFluct * 0.5, 0.7 - float(BIOME_CLOUD_LAYERS - 1) /
                                      float(BIOME_SURF_LAYERS)));
  OutColor.rgb = (pow(OutColor.rgb, vec3(height * stripeFluct)));

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    float height = HeightMapFogGasGiant(GetSurfacePoint());
    OutColor.rgb = height * GetGasGiantCloudsColor(1.0).rgb;
    OutColor.a = 1.0;
  }

  if (volcanoActivity != 0.0) {
    float latitude = abs(GetSurfacePoint().y);
    // Drown out poles
    OutColor.rgb = pow(OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.4)));
  }

  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif