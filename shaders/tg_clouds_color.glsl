#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main() {
    float height = GetSurfaceHeight();

    OutColor = GetCloudsColor(height);

    if(cloudsCoverage == 1.0) {
        float modulate = height * height * 3.5 + height;

        OutColor.rgb = pow(OutColor.rgb, vec3(modulate));
        OutColor.a = 1.0;

        float latitude = abs(GetSurfacePoint().y);
        // Drown out poles
        // TODO: Occasionally make the equator drowned out, like Titan
        OutColor.rgb = pow(OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.4)));
    } else {
        float modulate = pow(height * 15.0, 0.8);

        OutColor.rgb = pow(OutColor.rgb, 1.0 / vec3(modulate));
        OutColor.a *= modulate;
    }

    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
