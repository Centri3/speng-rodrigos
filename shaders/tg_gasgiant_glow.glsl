#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main()
{
   // float intheat = lavaCoverage * 3;
	
	//if (intheat > surfTemperature)
	//{
	//	surfTemperature = intheat;
	//}
	
	float surfTemp = (1.0 - 0.2 * GetSurfaceHeight()) * surfTemperature; // in thousand Kelvins
    surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
	OutColor = vec4(surfTemp);
}

//-----------------------------------------------------------------------------

#endif
