#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
  float height = GetSurfaceHeight();

  float modulate = saturate(height * height * 3.5 + height * 4.5);
  OutColor = GetCloudsColor(modulate);

  // Venus-like clouds
  if (cloudsCoverage == 1.0) {
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
