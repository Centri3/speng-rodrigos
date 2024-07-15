#include "tg_common.glh"  

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

void ColorMapTerra(vec3 point, in BiomeData biomeData, out vec4 ColorMap) {
    Surface surf;

    // Assign a climate type
//RODRIGO
    vec3 p = point * mainFreq + Randomize;
    noiseOctaves = 5;
    vec3 distort = 0.35 * Fbm3D(p * 0.73);
    noiseOctaves = 12.0;

    noiseH = 0.5;
    noiseLacunarity = 2.218281828459;
    noiseOffset = 0.8;
    float climate, latitude, dist;
    if(tidalLock <= 0.0) {
        latitude = abs(point.y);
        latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        latitude = saturate(latitude);
        if(latitude < latTropic - tropicWidth)
            climate = mix(climateTropic, climateEquator, saturate((latTropic - latitude - tropicWidth) / latTropic));
        else if(latitude > latTropic + tropicWidth)
            climate = mix(climateTropic, climatePole, saturate((latitude - latTropic - tropicWidth) / (1.0 - latTropic)));
        else
            climate = climateTropic;
    } else {
        latitude = 1.0 - point.x;
        latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        climate = mix(climateTropic, climatePole, saturate(latitude));
    }

    // Litosphere cells
    //float lithoCells = LithoCellsNoise(point, climate, 1.5);

    // Change climate with elevation
    noiseOctaves = 5.0;
    noiseLacunarity = 3.5;
    float vary = Fbm(point * 1700.0 + Randomize);
    float snowLine = biomeData.height + 0.25 * vary * biomeData.slope;
    float montHeight = saturate((biomeData.height - seaLevel) / (snowLevel - seaLevel));
    climate = min(climate + heightTempGrad * montHeight, climatePole - 0.125);
    climate = mix(climate, climatePole, saturate((snowLine - snowLevel) * 100.0));

    // Ice caps
    float iceCap = saturate((latitude / latIceCaps - 0.984) * 50.0);
    climate = mix(climate, climatePole, iceCap);

    // Surpress vegetation in deserts
    //if (biomeData.biome == BIOME_SAND)
    //    climate = 0.3;

    // Flatland climate distortion

//RODRIGO - small changes 
    noiseOctaves = 14.0;
    noiseLacunarity = 2.218281828459;
    vec3 pp = (point + Randomize) * (0.0005 * hillsFreq / (hillsMagn * hillsMagn));
    float fr = 0.20 * (1.5 - RidgedMultifractal(pp, 2.0)) +
        0.05 * (1.5 - RidgedMultifractal(pp * 10.0, 2.0)) +
        0.02 * (1.5 - RidgedMultifractal(pp * 100.0, 2.0));
    p += Fbm3D(p * 0.38) * 1.2;
    vary = Fbm(p) * 0.35 + 0.245;
    climate += 2.8 * vary * saturate(1.0 - 3.0 * biomeData.slope) * saturate(1.0 - 1.333 * climate);

    float height = GetSurfaceHeight();
    // Shield volcano lava
    vec2 volcMask = vec2(0.0);
    if(volcanoOctaves > 0) {
        // Global volcano activity mask
        noiseOctaves = 3.0;
        float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
        // Lava in volcano caldera and flows
        volcMask = VolcanoGlowNoise(point);
        volcMask.x *= volcActivity;
    }

    // Model lava as rocks texture
    climate = mix(climate, 0.375, volcMask.x);
    biomeData.slope = mix(biomeData.slope, 1.0, volcMask.x);

    // Global albedo variations
//RODRIGO - modify albedo noise
    noiseOctaves = 14.0;
    distort = Fbm3D((point + Randomize) * 0.07) * 1.5;

    vary = 1.0 - Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) + RidgedMultifractal(pp * 0.999, 8.0)));
    vary *= 0.5 * vary * vary;

    // Scale detail texture UV and add a small distortion to it to fix pixelization
    vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
    noiseOctaves = 4.0;
    vec2 shatterUV = Fbm2D2(detUV * 1.0) * (1.0 / 512.0);
    detUV += shatterUV;

    surf = GetBaseSurface(biomeData.height, detUV);

    // Vegetation
    if(plantsBiomeOffset > 0.0) {
        noiseH = 0.5;
        noiseLacunarity = 2.218281828459;
        noiseOffset = 0.8;
        noiseOctaves = 2.0;
        float plantsTransFractal = abs(0.125 * Fbm(point * 3.0e5) + 0.125 * Fbm(point * 1.0e3));

        // Modulate by humidity

//Rodrigo - Changed albedoVaryDistort to distort

        noiseOctaves = 8.0;
        float humidityMod = Fbm((point + distort) * 1.73) - 1.0 + humidity * 2.0;

        float plantsFade = smoothstep(beachWidth, beachWidth * 2.0, biomeData.height - seaLevel) *
            smoothstep(0.750, 0.650, biomeData.slope) *
            smoothstep(-0.5, 0.5, humidityMod);

        // Interpolate previous surface to the vegetation surface
        ModifySurfaceByPlants(surf, detUV, climate, plantsFade, plantsTransFractal);
    }

    // Polar cap ice
    /*if (iceCap > 0)
    {
        Surface ice = DetailTextureMulti(detUV, BIOME_SNOW);
        surf = BlendMaterials(surf, ice, iceCap);
    }*/

    // Mountain/winter snow
    if(climate > 0.9 && latitude > latTropic) {
        float snowTransition = smoothstep(0.9, 0.92, climate);
        Surface snow = DetailTextureMulti(detUV, BIOME_SNOW);
        surf = BlendMaterials(surf, snow, snowTransition);
    }

    // Sedimentary layers
    #define CLIFF_TRANSITION_BEGIN 0.35 // 0.50
    #define CLIFF_TRANSITION_END   0.65 // 0.55
    if((iceCap == 0.0) && (biomeData.slope > CLIFF_TRANSITION_BEGIN)) {
        // Generate layers pattern
        p = point * 378.3 + NoiseVec3(point * 967.7) * 10.0;
        noiseOctaves = 5.0;
        vary = saturate(Fbm(p) * 0.7 + 0.5);
        noiseOctaves = 4.0;
        float layers = Fbm(vec3(biomeData.height * 168.4 + 0.17 * vary, 0.43 * (p.x + p.y), 0.43 * (p.z - p.y)));

        // Get a steep cliff surface and modulate its color by the layer pattern
        Surface cliff = DetailTextureMulti(detUV, BIOME_ROCK);
        cliff.color.rgb *= vec3(1.0) - vec3(0.0, 0.25, 0.5) * layers;

        // Interpolate previous surface to the cliff surface
        float cliffTransition = smoothstep(CLIFF_TRANSITION_BEGIN, CLIFF_TRANSITION_END, biomeData.slope);
        surf = BlendMaterials(surf, cliff, cliffTransition);
    }

    // Ice cracks
//RODRIGO -Change albedovary to vary
    float mask = 1.0;
    if(cracksOctaves > 0.0)
        vary *= mix(1.0, CrackColorNoise(point, mask), iceCap);
    vary += iceCap * 0.7;

    // Apply albedo variations
    surf.color.rgb *= mix(colorVary, vec3(1.0), vary);

    // water mask for planets with oceans (oceanType == 0 on dry planets)

//RODRIGO - chage surf.color.a to surf.color 
    if(oceanType != 0.0)
        surf.color += saturate((seaLevel - biomeData.height) * 200.0);

    ColorMap = surf.color;

    //SurfA   surf0 = DetailTextureNoTiled(detUV, 10.0, 0.0, 10.0);
    //ColorMap = surf0.color;
    //ColorMap = texture(DiffTexArraySampler, vec3(detUV, 10.0));

//#define VISUALIZE_CLIMATE
#ifdef VISUALIZE_CLIMATE
    vec4 col = vec4(1.0 - climate, 0.5 * (1.0 - climate), climate, 0.0);
    ColorMap = mix(ColorMap, col, 0.75);
#endif

//#define VISUALIZE_CLIMATE
#ifdef VISUALIZE_CLIMATE
    ColorMap = vec4(climate);
#endif

//#define VISUALIZE_BIOMES
#ifdef VISUALIZE_BIOMES
    const vec4 BiomeDebugColor[BIOME_SURF_LAYERS] = vec4[BIOME_SURF_LAYERS](vec4(0.5, 0.1, 0.5, 0.0),   // BIOME_BOTTOM
    vec4(0.0, 0.4, 0.8, 0.0),   // BIOME_SHELF
    vec4(0.2, 0.2, 0.2, 0.0),   // BIOME_BEACH
    vec4(0.2, 0.4, 0.2, 0.0),   // BIOME_LOWLAND
    vec4(0.0, 0.4, 1.0, 0.0),   // BIOME_UPLAND
    vec4(0.3, 0.2, 0.1, 0.0),   // BIOME_ROCK
    vec4(0.9, 1.0, 1.0, 1.0),   // BIOME_SNOW
    vec4(0.8, 0.8, 1.0, 1.0),   // BIOME_ICE
    vec4(0.1, 0.1, 0.1, 0.0),   // BIOME_LAVA
    vec4(0.8, 0.7, 0.0, 0.0),   // BIOME_ORG_M_STEPPE
    vec4(0.1, 1.0, 0.1, 0.0),   // BIOME_ORG_M_FOREST
    vec4(0.6, 0.7, 0.2, 0.0),   // BIOME_ORG_M_GRASS
    vec4(0.8, 0.7, 0.0, 0.0),   // BIOME_ORG_U_STEPPE
    vec4(0.1, 1.0, 0.1, 0.0),   // BIOME_ORG_U_FOREST
    vec4(0.6, 0.7, 0.2, 0.0),   // BIOME_ORG_U_GRASS
    vec4(0.8, 0.7, 0.0, 0.0),   // BIOME_EXO_M_STEPPE
    vec4(0.1, 1.0, 0.1, 0.0),   // BIOME_EXO_M_FOREST
    vec4(0.6, 0.7, 0.2, 0.0),   // BIOME_EXO_M_GRASS
    vec4(0.8, 0.7, 0.0, 0.0),   // BIOME_EXO_U_STEPPE
    vec4(0.1, 1.0, 0.1, 0.0),   // BIOME_EXO_U_FOREST
    vec4(0.6, 0.7, 0.2, 0.0)    // BIOME_EXO_U_GRASS
    );

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

    //vec4 col0 = BiomeDebugColor[int(surf.matIDs.x)];
    //vec4 col1 = BiomeDebugColor[int(surf.matIDs.y)];
    //vec4 colb = mix(col0, col1, surf.matIDs.z);
    vec4 colb = BiomeDebugColor[int(surf.matIDs.x)];
    ColorMap = mix(ColorMap, colb, 0.75);
#endif
}

//-----------------------------------------------------------------------------

void main() {
    vec3 point = GetSurfacePoint();
    BiomeData biomeData = GetSurfaceBiomeData();
    ColorMapTerra(point, biomeData, OutColor);

    OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif
