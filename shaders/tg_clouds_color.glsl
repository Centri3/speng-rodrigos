#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
  float _stripeFluct = unwrap_or(stripeFluct, 0.6);

  float height = GetSurfaceHeight();

  float modulate = saturate(log(height + 1.0) * 3.0);
  OutColor = GetCloudsColor(modulate);

  // Venus-like clouds
  if (cloudsCoverage == 1.0) {
    // RDH gas giants
    OutColor = GetGasGiantCloudsColor(
                   max(height * _stripeFluct * 0.5, 1.0 - float(BIOME_CLOUD_LAYERS - 1) /
                                         float(BIOME_SURF_LAYERS))) *
                   0.3 +
               0.4 * GetGasGiantCloudsColor(
                         min(height * _stripeFluct * 0.5, 0.7 - float(BIOME_CLOUD_LAYERS - 1) /
                                               float(BIOME_SURF_LAYERS)));
    OutColor.rgb *= (pow(OutColor.rgb, vec3(height) * 0.1));

    if (cloudsLayer == 0) {
      OutColor.a = 1.0;
    } else {
      OutColor.a *= modulate;
    }

    float latitude = abs(GetSurfacePoint().y);
    // Drown out poles
    // TODO: Occasionally make the equator drowned out, like Titan
    OutColor.rgb = pow(OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.4)));

    if (cloudsLayer == 0.0 && cloudsNLayers != 1) {
      OutColor.a = 0.0;
    }
  } else {
    OutColor *= modulate;
  }

  OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
