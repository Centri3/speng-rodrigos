#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec4    ColorMapAsteroid(vec3 point, in BiomeData biomeData)
{
    float _hillsMagn = hillsMagn;
    if (hillsMagn < 0.05)
    {
        _hillsMagn = 0.05;
    }

    noiseH = 0.1;
    noiseOctaves = 5.0;

    noiseOctaves = 5.0;
    vec3 p = point * colorDistFreq * 2.3;
    p += Fbm3D(p * 0.5) * 1.2;
    float vary = saturate((Fbm(p) + 0.7) * 0.7);

    // GlobalModifier // ColorVary setup
    vec3 zz = (point + Randomize) * (0.0005 * hillsFreq / (_hillsMagn * _hillsMagn));
	noiseOctaves = 14.0;
    noiseH = smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
	vec3 albedoVaryDistort = Fbm3D((point + Randomize) * 0.07) * (1.5 + venusMagn);
    vary = 1.0 - Fbm((point + albedoVaryDistort) * (1.5 - RidgedMultifractal(zz, 8.0)+ RidgedMultifractal(zz*0.999, 8.0)));

    // Scale detail texture UV and add a small distortion to it to fix pixelization
    vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
    noiseOctaves = 4.0;
    vec2 shatterUV = Fbm2D2(detUV * 16.0) * (16.0 / 512.0);
    detUV += shatterUV;

    Surface surf = GetBaseSurface(biomeData.height, detUV);

    // GlobalModifier // ColorVary apply
	surf.color.rgb *= mix(colorVary, vec3(1.0), vary);

    surf.color.rgb *= 0.9 + biomeData.slope * 0.3;
    return surf.color;
}

//-----------------------------------------------------------------------------

void main()
{
    vec3  point = GetSurfacePoint();
    BiomeData biomeData = GetSurfaceBiomeData();
    OutColor = ColorMapAsteroid(point, biomeData);
    OutColor.rgb = pow(OutColor.rgb, colorGamma);
    //OutColor2 = vec4(height, slope, 0.0, 1.0);
}

//-----------------------------------------------------------------------------

#endif
