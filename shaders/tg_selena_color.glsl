#include "tg_common.glh"  

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void ModifySurfaceByPlantsWithOffset(inout Surface prevSurf, vec2 detUV, float climate, float fade, float transFractal, int plantsBiomeOffsetAdjusted) {
    Surface plants;
    float transition;

    transition = PlantsBlendCoeff(climateSteppeMin, climateSteppeMax, climate, fade, transFractal);
    if(transition > 0.0) {
        plants = DetailTextureMulti(detUV, plantsBiomeOffsetAdjusted); // plantsBiomeOffset is BIOME_*_STEPPE
        prevSurf = BlendMaterials(prevSurf, plants, transition);
    }

    transition = PlantsBlendCoeff(climateForestMin, climateForestMax, climate, fade, transFractal);
    if(transition > 0.0) {
        plants = DetailTextureMulti(detUV, plantsBiomeOffsetAdjusted + 1); // plantsBiomeOffset is BIOME_*_FOREST
        prevSurf = BlendMaterials(prevSurf, plants, transition);
    }

    transition = PlantsBlendCoeff(climateGrassMin, climateGrassMax, climate, fade, transFractal);
    if(transition > 0.0) {
        plants = DetailTextureMulti(detUV, plantsBiomeOffsetAdjusted + 2); // plantsBiomeOffset is BIOME_*_GRASS
        prevSurf = BlendMaterials(prevSurf, plants, transition);
    }
}

//-----------------------------------------------------------------------------

float slopedIceCaps(float slope) {
    if(slope > 0.03 * (2.0 - icecapHeight)) {
        return 1.0;
    }

    return 0.0;
}

//-----------------------------------------------------------------------------

vec4 ColorMapSelena(vec3 point, in BiomeData biomeData) {
    Surface surf;

    // Assign a climate type
    noiseOctaves = 6.0;
    noiseH = 0.5;
    noiseLacunarity = 2.218281828459;
    noiseOffset = 0.8;
    float climate, latitude, dist;
    if(tidalLock <= 0.0) {
        latitude = abs(point.y);
        latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        latitude = saturate(latitude);
        /*if (latitude < latTropic - tropicWidth)
            climate = mix(climateTropic, climateEquator, saturate((latTropic - latitude - tropicWidth) / latTropic));
        else if (latitude > latTropic + tropicWidth)
            climate = mix(climateTropic, climatePole, saturate((latitude - latTropic - tropicWidth) / (1.0 - latTropic)));
        else
            climate = climateTropic;*/
        climate = biomeData.height;
    } else {
        latitude = 1.0 - point.x;
        latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        climate = mix(climateTropic, climatePole, saturate(latitude));
    }

    /*// Change climate with elevation
    noiseOctaves    = 5.0;
    noiseLacunarity = 3.5;
    float vary = Fbm(point * 1700.0 + Randomize);
    float snowLine   = biomeData.height + 0.25 * vary * biomeData.slope;
    float montHeight = saturate((biomeData.height - seaLevel) / (snowLevel - seaLevel));
    climate = min(climate + heightTempGrad * montHeight, climatePole - 0.125);
    climate = mix(climate, climatePole, saturate((snowLine - snowLevel) * 100.0));

    // Ice caps
    float iceCap = saturate((latitude / latIceCaps - 1.0) * 50.0);
    climate = mix(climate, climatePole, iceCap);

    // Flatland climate distortion
    noiseOctaves    = 4.0;
    noiseLacunarity = 2.218281828459;
	vec3  pp = (point + Randomize) * (0.0005 * hillsFreq / (hillsMagn * hillsMagn));
    float fr = 0.20 * (1.5 - RidgedMultifractal(pp,         2.0)) +
               0.05 * (1.5 - RidgedMultifractal(pp * 10.0,  2.0)) +
               0.02 * (1.5 - RidgedMultifractal(pp * 100.0, 2.0));
    vec3  p = point * (colorDistFreq * 0.005) + vec3(fr);
    p += Fbm3D(p * 0.38) * 1.2;
    vary = Fbm(p) * 0.35 + 0.245;
//RODRIGO - MODIFIED VALUES
    climate += 2.3*vary * saturate(1.0 - 3.0 * biomeData.slope) * saturate(1.0 - 1.333 * climate);*/

    // Flatland climate distortion
    noiseOctaves = 15.0;
    dist = 1.5 * floor(2.0 * DistFbm(point * 0.002 * colorDistFreq, 2.0));
    climate += colorDistMagn * dist;

    // Biome domains
    vec3 p = point * mainFreq + Randomize;
    vec4 col;
    noiseOctaves = 6;
    vec3 distort = p * 2.3 + 13.5 * Fbm3D(p * 0.06);
    vec2 cell = Cell3Noise2Color(distort, col);
    float biome = col.r;
    float biomeScale = saturate(2.0 * (pow(abs(cell.y - cell.x), 0.7) - 0.05));

    // Color texture variation
    noiseOctaves = 5;
    p = point * colorDistFreq * 2.3;
    p += Fbm3D(p * 3.5) * 1.2;
    float vary = saturate((Fbm(p) + 0.7) * 9.7);

    // Shield volcano lava
    if(volcanoOctaves > 0) {
        // Global volcano activity mask
        noiseOctaves = 3;
        float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
        // Lava in volcano caldera and flows
        vec2 volcMask = VolcanoGlowNoise(point);
        volcMask.x *= volcActivity;
		// Model lava as rocks texture
        climate = mix(climate, 0.0, volcMask.x);
        biomeData.slope = mix(biomeData.slope, 0.0, volcMask.x);
    }

    //Surface surf = GetSurfaceColor(saturate(climate), slope, vary);

    // Scale detail texture UV and add a small distortion to it to fix pixelization
    vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
    noiseOctaves = 4.0;
    vec2 shatterUV = Fbm2D2(detUV * 16.0) * (16.0 / 512.0);
    detUV += shatterUV;

    surf = GetBaseSurface(biomeData.height, detUV);

    // Global albedo variations
//RODRIGO - MODIFIED ALBEDO NOISE
    vec3 zz = (point + Randomize) * (0.5 * hillsFreq / (hillsMagn * hillsMagn));
    noiseOctaves = 10.0;
    vec3 albedoVaryDistort = Fbm3D((point + Randomize) * 9.7) * (1.5 + venusMagn);

    vary = 1.0 - Fbm((point + albedoVaryDistort) + (9.5 - Fbm(zz) + Fbm(zz * 0.999)));

    vary *= 0.5 * vary * vary;

    if(craterSqrtDensity > 0.05) {
        // Young terrain - suppress craters
        noiseOctaves = 4.0;
        vec3 youngDistort = Fbm3D((point - Randomize) * 0.07) * 1.1;
        noiseOctaves = 8.0;
        float young = 1.0 - Fbm(point + youngDistort);
        young = smoothstep(0.0, 1.0, young * young * young);
        vary = mix(0.0, vary, young);
    }

    // Ice cracks
    float mask = 1.0;
    if(cracksOctaves > 0.0)
        vary *= CrackColorNoise(point, mask);

//ENCELADUS TYPE TERRAINS
    if((cracksOctaves > 0.0) && (canyonsMagn > 0.52) && (mareFreq < 1.7)) {

        if(cracksFreq < 0.6) {
            vary /= CrackColorNoise(point, mask);
            noiseOctaves = 6.0;
            noiseLacunarity = 2.218281828459;
            noiseH = 0.9;
            noiseOffset = 0.5;
            p = point * 0.5 * mainFreq + Randomize;
            distort = Fbm3D(point * 0.1) * 3.5 + Fbm3D(point * 0.1) * 6.5 + Fbm3D(point * 0.1) * 12.5;
            cell = Cell3Noise2(canyonsFreq * 0.05 * p + distort);
            float rima2 = 2 - saturate(abs(cell.y - cell.x) * 250.0 * canyonsMagn);
            rima2 = biomeScale * smoothstep(0.0, 1.0, rima2);

            vary -= 1 - rima2;
            surf.color = mix(vec4(0.75, 0.9, 1.0, 0.00), vec4(1.0), vary);
        }

// EUROPA-TYPE TERRAIN
        else {
            vary *= (0.2 * CrackColorNoise(point * 2, mask) + 0.2 * CrackColorNoise(point * 4, mask) + 0.1 * CrackNoise(point * 32, mask) + 0.05 * CrackNoise(point * 64, mask));
//surf.color *= mix(vec4(0.7, 0.58, 0.36, 0.00), vec4(4), vary); 
        }
    }

    // "Freckles" (structures like on Europa)
    if((biome > hillsFraction) && (biome < hills2Fraction)) {
        noiseOctaves = 10.0;
        noiseLacunarity = 2.0;
        vary *= 1.0 - saturate(2.0 * mask * biomeScale * JordanTurbulence(point * hillsFreq + Randomize, 0.8, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0));
    }

    // Vegetation
    int plantsBiomeOffsetAdjusted = int(plantsBiomeOffset);

    if(plantsBiomeOffset == 0.0) {
        plantsBiomeOffsetAdjusted = 9;
    }

    noiseH = 0.5;
    noiseLacunarity = 2.218281828459;
    noiseOffset = 0.8;
    noiseOctaves = 2.0;
    float plantsTransFractal = abs(0.125 * Fbm(point * 3.0e5) + 0.125 * Fbm(point * 1.0e3));

    // Modulate by humidity
    noiseOctaves = 8.0;
    float humidityMod = Fbm((point + albedoVaryDistort) * 1.73) - 1.0 + humidity * 2.0;

    float plantsFade = smoothstep(beachWidth, beachWidth * 2.0, biomeData.height - seaLevel) *
        smoothstep(0.750, 0.650, biomeData.slope) *
        smoothstep(-0.5, 0.5, humidityMod);

    // Interpolate previous surface to the vegetation surface
    ModifySurfaceByPlantsWithOffset(surf, detUV, climate, plantsFade, plantsTransFractal, plantsBiomeOffsetAdjusted);

    // Make driven hemisphere darker
    float z = -point.z * sign(drivenDarkening);
    if(drivenDarkening != 0.0) {
        noiseOctaves = 3;
        z += 0.2 * Fbm(point * 1.63);
        z = saturate(1.0 - z);
        z *= z;

        if(drivenDarkening < 0.55) {
            surf.color.rgb *= mix(vec3(1.0 - 0.75 * 0.65 * abs(drivenDarkening), 1.0 - 0.75 * 0.67 * abs(drivenDarkening), 1.0 - 0.75 * 0.65 * abs(drivenDarkening)), vec3(1.0), z);
        } else {
            surf.color.rgb *= mix(vec3(1.0 - 0.75 * 0.65 * 0.55, 1.0 - 0.75 * 0.67 * 0.55, 1.0 - 0.75 * 0.65 * 0.55), vec3(1.0), z);
        }
    }

   // Apply albedo variations
    surf.color.rgb *= mix(colorVary, vec3(1.0), vary);

    // Rayed craters
    if(craterSqrtDensity * craterSqrtDensity * craterRayedFactor > 0.05 * 0.05) {
        float craterRayedSqrtDensity = craterSqrtDensity * sqrt(craterRayedFactor);
        float craterRayedOctaves = floor(craterOctaves * craterRayedFactor);
        float crater = RayedCraterColorNoise(point, craterFreq, craterRayedSqrtDensity, craterRayedOctaves);
        surf.color.rgb = mix(surf.color.rgb, vec3(1.0), crater);
    }

    // Ice caps - thin frost

    float height = 0.0;
    float slope = 0.0;
    GetSurfaceHeightAndSlope(height, slope);

    float slopedFactor = slopedIceCaps(slope);
    float iceCap = saturate((latitude - latIceCaps + 0.3) * 2.0 * slopedFactor);
    float snow = float(slope * 1 > (snowLevel + 1.1) * 0.3);

    surf.color.rgb = mix(surf.color.rgb, vec3(1.0), 0.8 * iceCap + snow);

    return surf.color;
}

//-----------------------------------------------------------------------------

void main() {
    vec3 point = GetSurfacePoint();
    BiomeData biomeData = GetSurfaceBiomeData();
    OutColor = ColorMapSelena(point, biomeData);

    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
