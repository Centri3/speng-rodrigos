#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
  float _stripeFluct = 0.2 + stripeFluct * 0.4;

  // GlobalModifier // Convert height to color
  vec3 point = GetSurfacePoint();
  float height = GetSurfaceHeight();
  // Don't go crazy with stripeFluct on venuslikes.
  float gaseousBuff = volcanoActivity != 0.0 ? 1.0 : 4.0;
  OutColor =
      0.5 *
          _GetGasGiantCloudsColor(max(height * _stripeFluct * 0.5 * gaseousBuff,
                                      1.0 - float(BIOME_CLOUD_LAYERS - 1) /
                                                float(BIOME_SURF_LAYERS))) +
      0.5 *
          _GetGasGiantCloudsColor(min(height * _stripeFluct * 0.5 * gaseousBuff,
                                      0.7 - float(BIOME_CLOUD_LAYERS - 1) /
                                                float(BIOME_SURF_LAYERS)));
  OutColor.rgb =
      (pow(OutColor.rgb, vec3(height * _stripeFluct * 6.0 * gaseousBuff)));

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    OutColor.a = 0.0;
  }

  if (volcanoActivity != 0.0) {
    float latitude = abs(GetSurfacePoint().y);
    // Drown out poles
    OutColor.rgb = mix(GetGasGiantCloudsColor(abs(Randomize.x) * 0.1666667 +
                                              abs(Randomize.y) * 0.1666667 +
                                              abs(Randomize.z) * 0.1666667)
                           .rgb,
                       OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.1)));
  }

  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif