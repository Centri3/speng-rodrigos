#include "tg_common.glh"
#include "height_map_selena.glh"
 
#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void main()
{
    vec3  point = GetSurfacePoint();
    float height = HeightMapSelena(point);
    OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif