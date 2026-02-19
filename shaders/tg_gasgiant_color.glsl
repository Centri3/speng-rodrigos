#include "tg_rmr.glh"

#ifdef _FRAGMENT_
//-----------------------------------------------------------------------------

float HeightMapFogGasGiant(vec3 point) {
  return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

void main() {
  // GlobalModifier // Convert height to color
  float height;
  float slope;
  GetSurfaceHeightAndSlope(height, slope);
  // Don't go crazy with stripeFluct on venuslikes.
  float gaseousBuff = volcanoActivity != 0.0 ? 1.0 : 4.0;
  OutColor =
      _GetGasGiantCloudsColor(height * stripeFluct * 0.5 * gaseousBuff);

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    float height = HeightMapFogGasGiant(GetSurfacePoint());
    OutColor.rgb = height * _GetGasGiantCloudsColor(1.0).rgb;
    OutColor.a = 1.0;
  }

  if (volcanoActivity != 0.0) {
    float latitude = abs(GetSurfacePoint().y);
    // Drown out poles
    OutColor.rgb = mix(GetGasGiantCloudsColor(hash1(Randomize.x) * 0.333 +
                                              hash1(Randomize.y) * 0.333 +
                                              hash1(Randomize.z) * 0.333)
                           .rgb,
                       OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.1)));
  }

  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif