#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//#define VISUALIZE_BIOMES

//-----------------------------------------------------------------------------

// Function // Reduce height required to increase palette color
Surface _GetBaseSurface(float height, vec2 detUV)
{
	float h = (height * 2.0 - seaLevel * 2.0) / (1.0 - seaLevel) * float(BIOME_ROCK - BIOME_BEACH + 1) + float(BIOME_BEACH);
	int h0 = clamp(int(floor(h)), 0, BIOME_ROCK);
	int h1 = clamp(h0 + 1, 0, BIOME_ROCK);
	float dh = fract(h);

	// interpolate between two heights
	Surface surfH0 = DetailTextureMulti(detUV, h0);
	Surface surfH1 = DetailTextureMulti(detUV, h1);
	return BlendMaterials(surfH0, surfH1, dh);
}

//-----------------------------------------------------------------------------

vec4 ColorMapTerra(vec3 point, float height, float slope, in BiomeData biomeData, out vec4 ColorMap)
{
	Surface surf;
	
	float _hillsMagn = hillsMagn;
	if (hillsMagn < 0.05)
	{
		_hillsMagn = 0.05;
	}
	else
	{
		_hillsMagn = hillsMagn;
	}
	float _hillsFreq = hillsFreq;
	if (riversMagn > 0.0 && cracksOctaves == 0 && texScale > 8200)
	{
		_hillsFreq = hillsFreq * 8;
	}
	else
	{
		_hillsFreq = hillsFreq;
	}
	
	// Biome domains
	vec3  p = point * mainFreq + Randomize;
	vec4  col;
	noiseOctaves = 6;
	vec3  distort = p * 2.3 + 13.5 * Fbm3D(p * 0.06);
	vec2  cell = Cell3Noise2Color(distort, col);
	float biome = col.r;
	float biomeScale = saturate(2.0 * (pow(abs(cell.y - cell.x), 0.7) - 0.05));
	float global = 1.0 - Cell3Noise(p + distort);
	float landform = 0.0;
	
	landform = RidgedMultifractalErodedDetail(p * Randomize, mainFreq, erosion, global);

#ifdef VISUALIZE_BIOMES
	vec4  colorOverlay;
	if (biome < dunesFraction)
		colorOverlay = vec4(0.8, 0.7, 0.5, 0.0); // Sandy color for dunes
	else if (biome < hillsFraction)
		colorOverlay = vec4(0.5, 0.4, 0.3, 0.0); // Brownish color for rocky hills
	else if (biome < hills2Fraction)
		colorOverlay = vec4(0.2, 0.5, 0.2, 0.0); // Greenish color for hills
	else if (biome < canyonsFraction)
		colorOverlay = vec4(0.6, 0.3, 0.1, 0.0); // Reddish-brown for canyons
	else
		colorOverlay = vec4(0.9, 0.9, 0.9, 0.0); // Light grey for high-altitude areas
#endif

	// Assign a climate type
	noiseOctaves	= 6.0;
	noiseH		  = 0.45; // Slightly less roughness for smoother transitions
	noiseLacunarity = 2.0; // Adjusted for more natural-looking patterns
	noiseOffset	 = 0.75; // Lower offset for subtler variations
	float climate, latitude, dist;
	if (tidalLock <= 0.0)
	{
		latitude = abs(point.y);
		latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
		latitude = saturate(latitude);
		if (latitude < latTropic - tropicWidth)
			climate = mix(climateTropic, climateEquator, saturate((latTropic - latitude - tropicWidth) / latTropic));
		else if (latitude > latTropic + tropicWidth)
			climate = mix(climateTropic, climatePole, saturate((latitude - latTropic - tropicWidth) / (1.0 - latTropic)));
		else
			climate = climateTropic;
	}
	else
	{
		latitude = 1.0 - point.x;
		latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
		climate = mix(climateTropic, climatePole, saturate(latitude));
	}

	// Litosphere cells
	//float lithoCells = LithoCellsNoise(point, climate, 1.5);

	// Change climate with elevation
	noiseOctaves	= 5.0;
	noiseLacunarity = 3.5;
	noiseH = 0.75;
	float vary = Fbm(point * 1700.0 + Randomize);
	float TempGrad = 4 * heightTempGrad -1.5;
	float snowTrue = 1;
	if (latIceCaps == 2.0)
	{
		snowTrue = 0;
	}
	// float snowLine = biomeData.height + 0.25 * vary * biomeData.slope + ((latitude * latitude) * TempGrad - latTropic);
	float snowLine = biomeData.height + 0.25 * vary * biomeData.slope;
	float montHeight = saturate((biomeData.height - seaLevel) / (snowLevel - seaLevel));
	climate = min(climate + heightTempGrad * montHeight, climatePole - 0.125);
	// climate = min(climate + heightTempGrad * montHeight, climatePole - 0.03);
	climate = mix(climate, climatePole, saturate((snowLine - snowLevel) * 100.0));

	// Ice caps
	float iceCap = saturate((latitude / latIceCaps - 0.8) * 5.0 + Fbm((p + distort) * 5.0));  // TPE
	// float iceCap = saturate((latitude / latIceCaps - 0.982) * 50.0);  // Donetelo
	climate = mix(climate, climatePole, iceCap);
	/*
	// Surpress vegetation in deserts
	if (biomeData.biome == BIOME_SAND)
		climate = 0.3;
	*/
	// Flatland climate distortion
	noiseOctaves = 14.0;
	noiseLacunarity = 2.218281828459;
	vec3 pp = (p + Randomize) * (0.0005 * _hillsFreq / (max(_hillsMagn, 0.01) * max(_hillsMagn, 0.01)));
	// vec3 pp = (point + Randomize) * 22.25 * (0.0005 * _hillsFreq / (hillsMagn * hillsMagn));
	p = point * 0.5 * mainFreq + Randomize;
	distort = 0.05 * Fbm3D(p * riversSin) + 0.035 * Fbm3D(p * riversSin * 5.0) + (0.001 *RidgedMultifractalEroded(point * canyonsFreq + Randomize,8.0, erosion));

	cell = Cell3Noise2(riversFreq * p + 1.5 * distort);

	distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	noiseOctaves = 8.0;
		
	float fr = 1.0 - Fbm((point + distort) * 0.78) +
			   0.20 * (1.5 - RidgedMultifractal(pp, 2.0)) +
			   0.05 * (1.5 - RidgedMultifractal(pp * 10.0, 2.0)) +
			   0.04 * (1.5 - RidgedMultifractal(pp * 100.0, 4.0));
			   
	p = point * (colorDistFreq * 0.005) + vec3(fr);
	p += Fbm3D(p * 0.38) * 1.2;
	vary = Fbm(p) * 0.35 + 0.245;
	climate += 0.8 * vary * saturate(1.0 - 3.0 * biomeData.slope) * saturate(1.0 - 1.333 * climate);
	
	// Shield volcano lava
	vec2 volcMask = vec2(0.0);
	if (volcanoOctaves > 0)
	{
        // Global volcano activity mask
        noiseOctaves = 3.0;
        float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
        // Lava in volcano caldera and flows
        volcMask = _VolcanoGlowNoise(point);
        volcMask.x *= volcActivity;
	}

	// Model lava as rocks texture
	climate = mix(climate, 0.375, volcMask.x);
	biomeData.slope = mix(biomeData.slope, 1.0, volcMask.x);
	
	// Global albedo variations
	// RODRIGO - modify albedo noise
	noiseOctaves = 14.0;
	noiseH = 0.2 + smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
	noiseOctaves = 14.0;
	distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	
	if (volcanoMagn != 0.0)
	{
		if (cracksOctaves == 0 && volcanoActivity >= 1.0)
		{
			distort = (saturate(iqTurbulence(point + Randomize, 0.55) * (2 * (volcanoActivity - 1))) + saturate(iqTurbulence(point + Randomize, 0.75) * (2 * (volcanoActivity - 1)))) * (volcanoActivity - 1) + (Fbm3D((point + Randomize) * 0.07) * 1.5) * (2 - volcanoActivity);  //Io like on atmosphered planets
		}
		else if (cracksOctaves == 0 && volcanoActivity < 1.0)
		{
			distort = Fbm3D((point + Randomize) * 0.07) * 1.5;  //For less Volcanic planets
		}
		else if (cracksOctaves > 0)  // Test Ice planets later
		{
			distort =Fbm3D((point * 0.26 + Randomize) * (volcanoActivity/2+1)) * (1.5 + venusMagn ) + saturate(iqTurbulence(point + Randomize, 0.15) * volcanoActivity);  //albedoVaryDistort =Fbm3D((point * volcanoActivity + Randomize) * volcanoActivity) * (1.5 + venusMagn );
		}
	}
	
	// distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	vary = 1.0 - Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) + RidgedMultifractal(pp * 0.999, 8.0)));
	vary *= 0.5 * vary * vary;

	// Scale detail texture UV and add a small distortion to it to fix pixelization
	vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
	noiseOctaves = 4.0;
	vec2 shatterUV = Fbm2D2(detUV * 1.0) * (1.0 / 512.0);
	detUV += shatterUV;

	surf = _GetBaseSurface(biomeData.height, detUV);

	// Vegetation
	if (plantsBiomeOffset > 0.0)
	{
		noiseH		  = 0.5;
		noiseLacunarity = 2.218281828459;
		noiseOffset	 = 0.8;
		noiseOctaves	= 2.0;
		float plantsTransFractal = abs(0.125 * Fbm(point * 3.0e5) + 0.125 * Fbm(point * 1.0e3));

		// Modulate by humidity
		// Rodrigo - Changed albedoVaryDistort to distort
		noiseOctaves = 8.0;
		float humidityMod = Fbm((point + distort) * 1.73) - 1.0 + humidity * 2.0;

		float plantsFade = smoothstep(beachWidth * 0.1, beachWidth * 0.3, biomeData.height - seaLevel) * smoothstep(0.750, 0.650, biomeData.slope) * smoothstep(-0.5, 0.5, humidityMod);
		// float plantsFade = smoothstep(beachWidth, beachWidth * 2.0, biomeData.height - seaLevel) * smoothstep(0.750, 0.650, biomeData.slope) * smoothstep(-0.5, 0.5, humidityMod);


		// Interpolate previous surface to the vegetation surface
		ModifySurfaceByPlants(surf, detUV, climate, plantsFade, plantsTransFractal);
	}
	
	// Polar cap ice
	if (iceCap > 0 && latIceCaps < 1.0 && biomeData.height > seaLevel)
	{
		Surface ice = DetailTextureMulti(detUV, BIOME_SNOW);
		surf = BlendMaterials(surf, ice, iceCap);
		// surf.color += saturate(iceCap * 200.0);
	}
	/*
	// Mountain/winter snow
	if (climate > 0.9 && snowLevel != 2.0)
	{
		// float snowTransition = smoothstep(0.8, 1.0, climate) * smoothstep(0.75, 0.65, biomeData.slope);
		float snowTransition = smoothstep( 0.9, 0.92, climate); // * smoothstep(0.75, 0.65, biomeData.slope);
		Surface snow = DetailTextureMulti(detUV, BIOME_SNOW);
		surf = BlendMaterials(surf, snow, snowTransition);
	}
	*/
    // Mountain/winter snow
    if (oceanType !=0)
	{
		if((climate > 0.9 && biomeData.height >= 0.25 * beachWidth+seaLevel) || latitude > latIceCaps )// && latitude > latTropic) || latitude > latIceCaps) 
		{
			float snowTransition = smoothstep(0.9, 0.92, climate);

			//	   float snowTransition =
			//        smoothstep(0.8, 1.0, climate) *
			//        smoothstep(latTropic, latTropic + 0.2,
			//                   latitude);
		
			Surface snow = DetailTextureMulti(detUV, BIOME_SNOW);
			//climate = mix(climate, climatePole, iceCap);
			surf = BlendMaterials(surf, snow, snowTransition);

			//if (biom  suppress ice under beach
		
			if (surf == snow)
			{
				vary = vary * 1.0 + 1.0;
			}
		}
	}
    if (oceanType == 0)
	{
		if((climate > 0.9))
		{
			float snowTransition = smoothstep(0.9, 0.92, climate);

			Surface snow = DetailTextureMulti(detUV, BIOME_SNOW);
			//climate = mix(climate, climatePole, iceCap);
			surf = BlendMaterials(surf, snow, snowTransition);
		
			//if (biom  suppress ice under beach

			if (surf == snow)
			{
				vary = vary * 0.5 + 0.5;
			}
		}
	}

	// Sedimentary layers
	noiseOctaves = 6.0;
	float layers = Fbm(vec3(biomeData.height * 150.0 + 0.15 * vary, 0.4 * (p.x + p.y), 0.4 * (p.z - p.y)));
	layers *= smoothstep(0.45, 0.5, biomeData.slope); // Adjusted for a broader range of slopes
	layers *= step(surf.color.a, 0.02);	 // Slightly higher threshold for snow
	layers *= saturate(1.0 - 4.0 * volcMask.x); // Adjusted for lava
	layers *= saturate(1.0 - 4.0 * volcMask.y); // Adjusted for volcanos
	surf.color.rgb *= vec3(1.0) - vec3(0.1, 0.6, 1.0) * (layers * 0.7); // Adjusted color modulation for layers

	// Sedimentary layers 2
	#define CLIFF_TRANSITION_BEGIN 0.35
	#define CLIFF_TRANSITION_END   0.40
	if ((iceCap == 0.0) && (biomeData.slope > CLIFF_TRANSITION_BEGIN))
	{
		// Generate layers pattern
		p = point * 350.0 + NoiseVec3(point * 900.0) * 10.0; // Adjusted for more realistic layering
		noiseOctaves = 6.0;
		vary = saturate(Fbm(p) * 0.7 + 0.5); // Adjusted noise base and amplitude
		noiseOctaves = 5.0;
		float layers = Fbm(vec3(biomeData.height * 160.0 + 0.18 * vary, 0.42 * (p.x + p.y), 0.42 * (p.z - p.y))); // Adjusted for more realistic layers

		// Get a steep cliff surface and modulate its color by the layer pattern
		Surface cliff = DetailTextureMulti(detUV, BIOME_ROCK);
		cliff.color.rgb *= vec3(1.0) - vec3(0.2, 0.7, 1.2) * layers; // More pronounced color variation

		// Interpolate previous surface to the cliff surface
		float cliffTransition = smoothstep(CLIFF_TRANSITION_BEGIN, CLIFF_TRANSITION_END, biomeData.slope);
		surf = BlendMaterials(surf, cliff, cliffTransition);
	}

	// Ice cracks
	float mask = 1.0;
	if (cracksOctaves > 0.0)
		vary *= mix(1.0, CrackColorNoise(point, mask), iceCap);
	vary += iceCap * 0.7;  // Donetello
	
	// Ice Belts for High Axial tilt custom planets. ~ TPE
	if(eqridgeMagn > 0.0 && biomeData.height > seaLevel)
	{
		float x = (point.y + 0.1 * Fbm(pp + Randomize)) / eqridgeWidth;
		// float ridgeHeight = exp(-0.75 * pow(abs(x), 5));
		// float eqridgeHeight = pow(eqridgeMagn, 1.25);
		// if((climate > 0.9))
		// {
				climate = mix(climate, climatePole, snowLevel);
				float snowTransition = smoothstep(0.0, abs(x), climate);
				Surface ice = DetailTextureMulti(detUV, BIOME_SNOW);
				surf = BlendMaterials(surf, ice, snowTransition);
				if (surf == ice)
				{
					vary = vary * 1.0 + 1.0;
				}
		// }
	}

	// Lava Lakes
	Surface obsidian = DetailTextureMulti(detUV, BIOME_LAVA);
	Surface glacier = DetailTextureMulti(detUV, BIOME_SNOW);
	p = point * 600.0 + Randomize;
    cell = Cell3Noise2(p + dist);
	noiseOctaves = 5;
	dist = 10.0 * colorDistMagn * Fbm(p * 0.2);
    noiseOctaves = 3;
	float varyTemp = 1.0 - 5.0 * smoothstep(0.1, 1.0, sqrt(abs(cell.y - cell.x)));
	noiseOctaves = 8;
	float globTemp = 0.95 - abs(Fbm((p + dist) * 0.01)) * 0.08;
	
	if(lavaCoverage > 0.0 && (cracksOctaves == 0 || volcanoTemp >= 0.75) && oceanType == 0.0 && biomeData.height == 0)  //(lavaCoverage > 0.0 && (volcanoTemp > 0.7 || hillsMagn <=0.09) && oceanType == 0.0 && biomeData.height <=0.00001)
	{
        surf = obsidian;
		vary = -(globTemp + varyTemp * 0.0) + 0.5;
	}

	if(biomeData.height < 0.00019 && biomeData.height > 0 && lavaCoverage > 0 && cracksOctaves == 0 && oceanType == 0.0)
	{
        surf = DetailTextureMulti(detUV, BIOME_ROCK);;
	}
	
	if(oceanType != 0 && biomeData.height == 0)
	{
		vary = vary * ((1 / seaLevel) * height);  //vary = vary*((1/seaLevel)*height)
	}

	// Apply albedo variations
	// surf.color *= mix(vec4(0.67, 0.58, 0.36, 0.00), vec4(1.0), vary);  // TPE
	surf.color.rgb *= mix(colorVary, vec3(1.0), vary) + RidgedMultifractalDetail(p + distort, vary, iceCap);  // Donatello + TPE

	// water mask for planets with oceans (oceanType == 0 on dry planets)

	// GlobalModifier // Slope contrast
	noiseH = 0.3;
	surf.color.rgb *= 0.85 + biomeData.slope * (Fbm(p) * 1.6 + 1.0) * 0.15;

	//RODRIGO - chage surf.color.a to surf.color 
	if (oceanType != 0.0)
		surf.color += saturate((seaLevel - biomeData.height) * 200.0);

	ColorMap = surf.color;

#ifdef VISUALIZE_BIOMES
	surf.color = mix(surf.color, colorOverlay * biomeScale, 0.25);
	//surf.color.rg *= lithoCells;
#endif

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
	const vec4	BiomeDebugColor[BIOME_SURF_LAYERS] = vec4[BIOME_SURF_LAYERS](
		vec4(0.5, 0.1, 0.5, 0.0),   // BIOME_BOTTOM
		vec4(0.0, 0.4, 0.8, 0.0),   // BIOME_SHELF
		vec4(1.0, 1.0, 0.2, 0.0),   // BIOME_BEACH
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
		vec4(0.6, 0.7, 0.2, 0.0)	// BIOME_EXO_U_GRASS
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

	return surf.color;
}

//-----------------------------------------------------------------------------

void main()
{
	vec3  point = GetSurfacePoint();
	float height, slope;
	BiomeData biomeData = GetSurfaceBiomeData();
	GetSurfaceHeightAndSlope(height, slope);
	OutColor = ColorMapTerra(point, height, slope, biomeData, OutColor);
	OutColor.rgb = pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif

