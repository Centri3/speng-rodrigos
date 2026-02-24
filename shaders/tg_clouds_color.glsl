#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main()
{
    float height = GetSurfaceHeight();
    float modulate = saturate(height * height * 3.5 + height);
	
    OutColor = GetCloudsColor(height);
	
	if (cloudsCoverage < 1.0) // fix cloud gaps on fully cloudy worlds -- HarbingerDawn
        OutColor = GetCloudsColor(height) * modulate;
	
    OutColor.rgb = pow(OutColor.rgb, colorGamma);
//	if (cloudsCoverage == 1)
//	{
//	OutColor.rgb *= pow(OutColor.rgb, colorGamma);
//	}
	
    //OutColor2 = vec4(0.0);
}

//-----------------------------------------------------------------------------

#endif
