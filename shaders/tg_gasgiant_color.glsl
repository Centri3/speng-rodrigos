#include "tg_rmr.glh"

#ifdef _FRAGMENT_

float HeightMapFogGasGiant(vec3 point) {
  return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height = GetSurfaceHeight();
  OutColor = _GetGasGiantCloudsColor(height);

  if (volcanoActivity != 0.0) {
    height = height / 3;
  }

  OutColor.rgb = (pow(OutColor.rgb, vec3(height)));

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    float height = HeightMapFogGasGiant(GetSurfacePoint());
    OutColor.rgb = height * _GetGasGiantCloudsColor(1.0).rgb;
    OutColor = rgb_to_lch(OutColor);
    OutColor.r *= height;
    OutColor.b += height * 20.0;
    OutColor = lch_to_rgb(OutColor);
    OutColor.a = 1.0;
  }
  /*
  if (volcanoActivity != 0.0) {   //polar suppression  uncomment for full Centri
  Venus-likes float latitude = abs(GetSurfacePoint().y);
      // Drown out poles
      OutColor.rgb = mix(GetGasGiantCloudsColor(0.0).rgb, OutColor.rgb,
                         1.0 - vec3(saturate(latitude - 0.3)));
    }
  */
  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif