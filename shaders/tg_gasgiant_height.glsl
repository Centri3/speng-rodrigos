#include "tg_common.glh"
#include "tg_gmail.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
    vec3 point = GetSurfacePoint();
    float height = (HeightMapCloudsGasGiantGmail(point, true, stripeZones) + HeightMapCloudsGasGiantGmail2(point) + HeightMapCloudsGasGiantGmail3(point));
    OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif