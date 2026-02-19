#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
  float _stripeFluct = 0.3 + stripeFluct * 1.2;

  // GlobalModifier // Convert height to color
  vec3 point = GetSurfacePoint();
  float height = GetSurfaceHeight();
  float modulate = height * 1.5 + height * 5.0;
  // Don't go crazy with stripeFluct on venuslikes.
  float gaseousBuff = volcanoActivity != 0.0 ? 1.0 : 4.0;
  float isMini = smoothstep(0.09, 1.0, cloudsFreq);
  OutColor =
      0.5 *
          _GetGasGiantCloudsColor(height - 0.5 * _stripeFluct * 0.0666666 * gaseousBuff) +
      0.5 *
          _GetGasGiantCloudsColor(height - 0.5 * _stripeFluct * 0.0666666 * gaseousBuff);
  OutColor = rgb_to_lch(OutColor);
  OutColor = lch_to_rgb(OutColor);

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