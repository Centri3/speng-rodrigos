#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
    float height = GetSurfaceHeight();
    OutColor = pow(GetGasGiantCloudsColor(height), vec4(height));
    OutColor.a *= 0.5;

    if (OutColor.a == 0.0) {
        OutColor.a = 1.0;
    }

    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
