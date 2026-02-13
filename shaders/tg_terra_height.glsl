#include "tg_rmr.glh" 
 
#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

//	RODRIGO - SMALL CHANGES TO RIVERS AND RIFTS
// Modified Rodrigo's rivers

void _PseudoRivers(vec3 point, float damping, inout float height)
{
	noiseOctaves = 8.0;
	noiseH	   = 1.0;
	noiseLacunarity = 2.1;

	// FIX: Don't apply this separately in each octave (like before) so that
	// rivers don't become cutoff when intersecting each other at different
	// octaves.
	float valleys = 1.0;
	float rivers = 1.0;

	for (int i = 0; i < 3; i++)
	{
		vec3 p = point + i * mainFreq + Randomize;
		vec3 distort = 0.325 * Fbm3D(p * riversSin * 0.3);
		distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq+1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2) * seaLevel;

		vec2 cell = 2.5 * Cell3Noise2(riversFreq * 3.0 * seaLevel * 0.2 * p + 0.5 * distort);
		
		valleys = saturate(1.36 * abs(cell.y - cell.x) * riversMagn);
		// valleys = smoothstep(0.0, 1.0, valleys) * damping;
		
		rivers = saturate(6.5 * abs(cell.y - cell.x) * riversMagn);
		// rivers = smoothstep(0.0, 1.0, rivers) * damping;
	}
	float errorcor = pow(0.992, (1 / seaLevel));  //Correct Rivers on marine planets
	
	height = min(mix(height, seaLevel + 0.019 + errorcor * 0.042, (1.0 - valleys) * damping), height);

	height = min(mix(height, seaLevel + 0.004 + errorcor * 0.052, (1.0 - rivers) * damping * smoothstep(0.7, 0.68, seaLevel)), height);
}

void _PseudoCracks(vec3 point, float damping, inout float height) {
	noiseOctaves = 8.0;
	noiseH = 1.0;
	noiseLacunarity = 2.1;

	float cracks = 0.0;

	vec3 p = point * 2.0 * mainFreq + Randomize;
	vec3 distort = 0.325 * Fbm3D(p * riversSin * 0.7);
	distort = 0.65 * Fbm3D(p * riversSin * 0.7) + 0.03 * Fbm3D(p * riversSin * 6.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2);

	vec2 cell = 2.5 * Cell3Noise2(cracksFreq * 10.0 * p + 0.5 * distort);

	cracks = 1.0 - (saturate(0.36 * abs(cell.y - cell.x) * cracksFreq * 10.0));
	cracks = smoothstep(0.0, 1.0, cracks) * damping;
	height = mix(height, seaLevel + 0.03, cracks);
}

//-----------------------------------------------------------------------------
// Alternate Rodrigo's rivers

void RmPseudoRivers(vec3 point, float global, float rocks, float damping, inout float height)
{
	float deNerf = hillsFreq;
	if (riversMagn > 0.0 && cracksOctaves == 0 && texScale > 8200)
	{
		deNerf = hillsFreq * 8;
	}
	else
	{
		deNerf = hillsFreq;
	}
	
	noiseOctaves = 8.0;
	noiseH	   = 1.0;
	noiseLacunarity = 2.1;

	// FIX: Don't apply this separately in each octave (like before) so that
	// rivers don't become cutoff when intersecting each other at different
	// octaves.
	float valleys = 1.0;
	float rivers = 1.0;

	for (int i = 0; i < 3; i++)
	{
		vec3 p = point * mainFreq + Randomize;
		vec3 distort = 0.325 * Fbm3D(p * riversSin);
		distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (global - (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel) + Randomize, 8.0, erosion, 2);

		vec2 cell = 2.5 * Cell3Noise2(riversFreq * 3.0 * p + 0.5 * distort);
		
		valleys = saturate(1.36 * abs(cell.y - cell.x) * riversMagn);
		// valleys = smoothstep(0.0, 1.0, valleys) * damping;
		
		rivers = saturate(6.5 * abs(cell.y - cell.x) * riversMagn);
		// rivers = smoothstep(0.0, 1.0, rivers) * damping;
	}
	
	float errorcor = pow(0.992, (1 / seaLevel));  //Correct Rivers on marine planets
		
	height = min(mix(height, seaLevel + 0.03 + errorcor * 0.042, (1.0 - valleys) * damping), height);

	height = min(mix(height, seaLevel + 0.015 + errorcor * 0.052, (1.0 - rivers) * damping * smoothstep(0.7, 0.68, seaLevel)), height);
}

//-----------------------------------------------------------------------------
// Alternate Rodrigo's rivers 2

void pseudoRivers2(vec3 point, float global, float rocks, float damping, inout float height)
{
	float deNerf = hillsFreq;
	if (riversMagn > 0.0 && cracksOctaves == 0 && texScale > 8200)
	{
		deNerf = hillsFreq * 8;
	}
	else
	{
		deNerf = hillsFreq;
	}
	
	noiseOctaves = 12.0;
	noiseH	   = 0.8;
	noiseLacunarity = 2.3;

	// FIX: Don't apply this separately in each octave (like before) so that
	// rivers don't become cutoff when intersecting each other at different
	// octaves.
	float valleys = 1.0;
	float rivers = 1.0;

	for (int i = 0; i < 3; i++)
	{
		vec3 p = point * 2.0 * mainFreq + Randomize;
		vec3 distort = 0.325 * Fbm3D(p * riversSin);
		distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (global - (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel) + Randomize, 8.0, erosion, 2);

		vec2 cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
		
		valleys = saturate(0.36 * abs(cell.y - cell.x) * riversMagn);
		// valleys = smoothstep(0.0, 1.0, valleys) * damping;
		
		rivers = saturate(6.5 * abs(cell.y - cell.x) * riversMagn);
		// rivers = smoothstep(0.0, 1.0, rivers) * damping;
	}
	
	float errorcor = pow(0.992, (1 / seaLevel));  //Correct Rivers on marine planets
		
	height = min(mix(height, seaLevel + 0.03 + errorcor * 0.042, (1.0 - valleys) * damping), height);

	height = min(mix(height, seaLevel + 0.015 + errorcor * 0.052, (1.0 - rivers) * damping * smoothstep(0.7, 0.68, seaLevel)), height);
}

//-----------------------------------------------------------------------------
// Modified Rodrigo's rifts

void _Rifts(vec3 point, float damping, inout float height)
{
	float riftsBottom = seaLevel;

	noiseOctaves	= 6.6;
	noiseH		  = 1.0;
	noiseLacunarity = 4.0;
	noiseOffset	 = 0.95;

	// 2 slightly different octaves to make ridges inside rifts
	vec3 p = point * 0.12;
	float rifts = 0.0;
	for (int i = 0; i < 2; i++)
	{
		vec3  distort = 0.5 * Fbm3D(p * riftsSin)+ 0.1 * Fbm3D(p * 3 * riftsSin);
		vec2  cell = Cell3Noise2(riftsFreq * p + distort);
		float width = 0.8 * riftsMagn * abs(cell.y - cell.x);
		rifts = softExpMaxMin(rifts, 1.0 - 2.75 * width, 32.0);
		p *= 1.02;
	}

	float riftsModulate = smoothstep(-0.1, 0.2, Fbm(point * 2.3 + Randomize));
	rifts = smoothstep(0.0, 1.0, rifts * riftsModulate) * damping;

	height = mix(height, riftsBottom, rifts);

	// Slope modulation
	if (rifts > 0.0)
	{
		float slope = smoothstep(0.1, 0.9, 1.0 - 2.0 * abs(rifts * 0.35 - 0.5));
		float slopeMod = 0.5 * slope * RidgedMultifractalErodedDetail(point * 5.0 * canyonsFreq + Randomize, 8.0, erosion, 8.0);
		slopeMod *= 0.05 * riftsModulate;
		height = softExpMaxMin(height - slopeMod, riftsBottom, 32.0);
	}
}

//-----------------------------------------------------------------------------

void HeightMapTerra(vec3 point, out vec4 HeightBiomeMap)
{
	float _hillsMagn = hillsMagn;
	if (hillsMagn < 0.05)
	{
		_hillsMagn = 0.05;
	}
	float deNerf = hillsFreq;
	if (riversMagn > 0.0 && cracksOctaves == 0 && texScale > 8200)
	{
		deNerf = hillsFreq * 8;
	}
	else
	{
		deNerf = hillsFreq;
	}
	// Assign a climate type
	noiseOctaves	= 12.0;
	noiseH		  = 0.5;
	noiseLacunarity = 2.218281828459;
	noiseOffset	 = 0.8;
	float climate, latitude;
	if (tidalLock <= 0.0)
	{
		latitude = abs(point.y);
		latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
		latitude = saturate(latitude);
		if (latitude < latTropic - tropicWidth)
			climate = mix(climateTropic, climateEquator, saturate((latTropic - tropicWidth - latitude) / latTropic));
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

	// Global landscape
	vec3 p = point * mainFreq + Randomize;

	// TODO: Make a utils function for this.
	// Give the global landscape a random angle to reduce chances of "vertical"
	// continents
	float angleX = Randomize.x * 6.283185;
	float angleY = Randomize.y * 6.283185;
	float angleZ = Randomize.z * 6.283185;

	// clang-format off
	mat3x3 rotX = mat3x3(1.0, 0.0, 0.0, 0.0, cos(angleX), -sin(angleX), 0.0, sin(angleX), cos(angleX));

	mat3x3 rotY = mat3x3(cos(angleY), 0.0, sin(angleY), 0.0, 1.0, 0.0, -sin(angleY), 0.0, cos(angleY));

	mat3x3 rotZ = mat3x3(cos(angleZ), -sin(angleZ), 0.0, sin(angleZ), cos(angleZ), 0.0, 0.0, 0.0, 1.0);
	// clang-format on

	p *= rotX;
	p *= rotY;
	p *= rotZ;

	// Replace old baseline terrain with more complex features.
	noiseOctaves = 5;
	// noiseH is not used on JordanTurbulence and iqTurbulence
	noiseLacunarity = 2.5 + smoothstep(0.1, 0.0, colorDistMagn) * 0.5;
	vec3 distort = 0.35 * Fbm3D(p * 0.73);
	noiseOctaves = 4;
	distort += 0.005 * (1.0 - abs(smoothstep(0.2, 0.01, JordanTurbulence3D(p * 132.3, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0))));
	float global = 1.0 - smoothstep(0.0, 1.0, iqTurbulence(p + distort + Randomize, smoothstep(0.1, 0.0, colorDistMagn) * mainFreq));
	// float global = 1.0 - RidgedMultifractal(p + distort + Randomize, 1.0);
	// float global = 1.0 - JordanTurbulence(p * _hillsMagn + distort + Randomize, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0); 
	noiseOctaves = 12;
	
	// Custom Planets using volcanoes for "city lights" are extremely crinkly.
	// Exclude special volcanism code when volcanoMagn is 0 for city lights generation.
	float globalVolcanic;

	if (volcanoMagn != 0.0)
	{
		globalVolcanic = (0.45 + seaLevel * 0.45) - JordanTurbulence(p + distort, 0.1, 0.7, 1.0 + venusMagn, 1.0, 3.0, 3.0, 1.0);
		global = mix(global, globalVolcanic, smoothstep(1.0, 2.0, volcanoActivity));
	}

	// Make sea bottom more flat; shallow seas resembles those on Titan;
	// but this shrinks out continents, so value larger than 1.5 is unwanted
	global = softPolyMax(global, 0.0, 0.1);
	global = pow(global, 1.5);

	// Reduce height of land to allow rivers to appear at "higher" altitudes;
	// seaLevel shouldn't be just a sphere, this is a workaround! Use smoothstep
	// to avoid "islands" where low values that are otherwise oceans become land
	// again, limit it to seaLevel.
	if (oceanType != 0.0)
	{
		global = mix(global + 0.1, pow(2.71828, global + 0.1) * _hillsMagn, smoothstep(seaLevel, 1.2, global));
	}

	// Venus-like structure
	float venus = 0.0;
	
	noiseOctaves = 4;
	distort = JordanTurbulence3D(p * _hillsMagn + (point + Randomize) * 0.07, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0) * (1.5 + venusMagn);
	// distort = Fbm3D(point * 0.3) * 1.5;
	noiseOctaves = 6;
	venus = Fbm((point + distort + Randomize) * venusFreq) * (venusMagn + 0.3);

	global = (global + venus - seaLevel) * 0.5 + seaLevel;
	global = clamp(global, seaLevel - 0.1, seaLevel + 0.1);
	float shore = saturate(70.0 * (global - seaLevel));

	// Biome domains
	noiseOctaves = 6;
	vec3  pb = p * 2.3 + 0.5 * Fbm3D(p * 1.5);
	vec4  col;
	vec2  cell = Cell3Noise2Color(pb, col);
	float biome = col.r;
	float biomeScale = saturate(2.0 * (pow(abs(cell.y - cell.x), 0.7) - 0.05));
	float terrace = col.g;
	float terraceLayers = max(col.b * 10.0 + 3.0, 3.0);
	terraceLayers += Fbm(pb * 5.41);

	float montRange = saturate(DistNoise(point * 22.6 + Randomize, 2.5) + 0.5);
	montRange *= montRange;
	float montBiomeScale = min(pow(2.2 * biomeScale, 3.5), 1.0) * montRange;

	float inv2montesSpiky = 1.0 / (montesSpiky * montesSpiky);
	float heightD  = 0.0;
	float height   = 0.0;
	float landform = 0.0;
	float dist;

	//	RODRIGO 
		landform = RidgedMultifractalErodedDetail(point * Randomize, 1.0, erosion, global);
		noiseOctaves = 8;
		vec3  pp = (point + Randomize) * (0.0005 * deNerf / (hillsMagn * hillsMagn));

		noiseOctaves = 10.0;
		noiseH = 1.0;
		noiseLacunarity = 2.3;
		noiseOffset = montesSpiky;
		float rocks = -0.005 * iqTurbulence(point * 200.0, 1.0) * smoothstep(2, 1, volcanoActivity);
		// float rocks = -0.013 * iqTurbulence(point * 80 , 1);
		rocks = smoothstep(-0.9, 0.1, rocks);

	//small terrain elevations   
		noiseOctaves = 8.0;
		/*
		float fr = 0.20 * (1.5 - RidgedMultifractal(pp, 2.0)) + 0.05 * (1.5 - RidgedMultifractal(pp * 10.0,  2.0));
		fr *= 1 - smoothstep(0.0, 0.02, seaLevel-global);
		global = mix(global,global+0.2,fr);
		*/
		float fr = 0.40 * (1.0 - RidgedMultifractal(pp, 2.0)) + 0.85 * (1.0 - RidgedMultifractal(pp * 10.0, 2.0)) + rocks;
		fr *= 1 - smoothstep(-0.005, 0.01, seaLevel-global);
		global = global + (0.00000001 * (deNerf * deNerf + 900000) * fr);
		
	//Mesas		
		float zr = 1.0 + 2 * Fbm(point + distort) + 7 * (1.5 - RidgedMultifractalEroded(pp * 0.8, 8.0, erosion)) - 6 * (1.5 - RidgedMultifractalEroded(pp * 0.1, 8.0, erosion)) - 0.01 * (1.5 - RidgedMultifractalEroded(pp * 4, 8.0, erosion));
		zr = smoothstep(0.0, 1.0, 0.2 * zr * zr);
		zr *= 1 - smoothstep(0.0, 0.02, seaLevel - global);
		zr = 0.1 * deNerf * smoothstep(0.0, 1.0, zr);
		global =  mix(global, global + 0.0006, zr);

		noiseOctaves = 10.0;
		noiseH = 1.0;
		noiseLacunarity = 2.3;
		noiseOffset = montesSpiky;
		float rr  = 0.3 * ((0.15 * iqTurbulence(point * 0.4 * montesFreq +Randomize, 0.45)) * (RidgedMultifractalDetail(point * point * montesFreq * 0.8 + venus + Randomize, 1.0, montBiomeScale)));
		rr *= 1 - smoothstep(0.0, 0.02, seaLevel - global);
		global += rr;

	// global = saturate(0.99 * global);
	global = global + 0.06 * ((fr * zr * rr) * _hillsMagn);
	// global = 0.9 * global + 0.06 * fr;
	/*
	//Eroded terrain & Mesas no rocks
		float t1 = 1.0; 
			t1 *= 1.0 - smoothstep(0.05, 0.105, global-seaLevel); 
		t1 *= 1.0 - smoothstep(-0.05, -0.025, seaLevel - global); 
			height = mix(height, height + 0.008, t1);
		float t2 = 1.0; 
			t2 *= 1.0 - smoothstep(0.13, 0.185, global-seaLevel); 
		t2 *= 1.0 - smoothstep(-0.13, -0.105, seaLevel - global); 
			height = mix(height, height + 0.010, t2);
		float t4 = 1.0; 
			t4 *= 1.0 - smoothstep(0.21, 0.265, global-seaLevel); 
		t4*= 1.0 - smoothstep(-0.21, -0.185, seaLevel - global); 
			height = mix(height, height + 0.010, t4);
		float t6 = 1.0; 
			t6*= 1.0 - smoothstep(-0.29, -0.265, global-seaLevel); 
		height = mix(height, height + 0.010, t6);
		*/
	//Eroded terrain & Mesas with rocks
		float t1 = 1.0; 
			t1 *= 1.0 - smoothstep(0.03, 0.105, global - (0.000000008 * (deNerf * deNerf + 900000) * rocks)-seaLevel);
		t1 *= 1.0 - smoothstep(-0.03, -0.026, seaLevel - (global - (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel));
			height = mix(height, height + 0.008, t1);
		float t2 = 1.0; 
			t2 *= 1.0 - smoothstep(0.11, 0.185, global - (0.000000008 * (deNerf * deNerf + 900000) * rocks)-seaLevel);
		t2 *= 1.0 - smoothstep(-0.11, -0.106, seaLevel - (global - (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel));
			height = mix(height, height + 0.008, t2);
		float t4 = 1.0; 
			t4 *= 1.0 - smoothstep(0.19, 0.265, global - (0.000000008 * (deNerf * deNerf + 900000) * rocks)-seaLevel);
		t4*= 1.0 - smoothstep(-0.19, -0.186, seaLevel - (global- (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel));
			height = mix(height, height + 0.008, t4);
		float t6 = 1.0; 
			t6*= 1.0 - smoothstep(-0.27, -0.266, global - (0.000000008 * (deNerf * deNerf + 900000) * rocks) - seaLevel);
		height = mix(height, height + 0.008, t6);

	if (biome < dunesFraction)
	{
		// Dunes
		noiseOctaves = 2.0;
		dist = dunesFreq + Fbm(p * 1.21);
		float desert = max(Fbm(p * dist), 0.0);
		float dunes  = DunesNoise(point, 3);
		landform = (0.0002 * desert + dunes) * pow(biomeScale, 3);
		heightD += dunesMagn * landform;
	}
	else if (biome < hillsFraction)
	{
		// Mountains
		if (oceanType != 0.0)
		{
			noiseOctaves = 10.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.0;
			noiseOffset  = montesSpiky * 1.2;
			height = hillsMagn * 2.4 * ((1.25 + iqTurbulence(point * 0.5 * deNerf * inv2montesSpiky * 1.25 + Randomize, 0.55)) * (0.05 * RidgedMultifractalErodedDetail(point * 1.0 * deNerf * inv2montesSpiky * 1.5 + Randomize, 1.0, erosion, montBiomeScale)));
		}
		else
		{
			noiseOctaves = 10.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.0;
			noiseOffset  = montesSpiky * 1.2;
			height = hillsMagn * 7.5 * ((1.25 + iqTurbulence(point * 0.5 * (deNerf / 2) * inv2montesSpiky * 1.25 + Randomize, 0.55)) * (0.05 * RidgedMultifractalDetail(point * 1.0 * (deNerf / 2) * inv2montesSpiky * 1.5 + Randomize, 1.0, montBiomeScale)));
		}
	}
	else if (biome < hills2Fraction)
	{
		// "Eroded" hills
		if (oceanType != 0.0)
		{
			noiseOctaves = 10.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.1;
			height = (0.5 + 0.4 * iqTurbulence(point * 0.5 * deNerf + Randomize, 0.55)) * (montBiomeScale * hillsMagn * (0.05 - (0.4 * RidgedMultifractalDetail(point * deNerf + Randomize, 2.0, venus)) + 0.3 * RidgedMultifractalErodedDetail(point * deNerf + Randomize, 2.0, 1.1 * erosion, montBiomeScale)));
		}
		else
		{
			noiseOctaves = 8.0; // Decrease the number of octaves for smoother terrain
			noiseLacunarity = 2.0; // Slightly increase lacunarity for more variation in frequency
			height = montBiomeScale * hillsMagn * JordanTurbulence(point * deNerf + Randomize, 0.7, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0);
		}
	}
	else if (biome < canyonsFraction)
	{
		if (oceanType != 0.0)
		{
			// TPE Canyons
			noiseOctaves = 10.0;
			noiseH	   = 0.1;
			noiseLacunarity = 2.1;
			noiseOffset  = montesSpiky;
			height = -canyonsMagn * 4 * ((0.5 + 0.8 * iqTurbulence(point * 0.5 * (canyonsFreq * 2) + Randomize, 0.55)) * (0.1 * RidgedMultifractalDetail(point * 0.7 * (canyonsFreq * 2) + Randomize, 1.0, montBiomeScale)));
			// if (terrace < terraceProb)
			{
				terraceLayers *= 5.0;
				float h = height * terraceLayers;
				height = (floor(h) + smoothstep(0.1, 0.9, fract(h))) / terraceLayers;
			}
		}
		else
		{
			// TPE Canyons
			noiseOctaves = 8.0; // Reduced for smoother transitions
			noiseH	   = 0.2; // Increased for more variation
			noiseLacunarity = 2.0; // Adjusted for smoother noise
			noiseOffset  = montesSpiky;
			height = -canyonsMagn * ((0.4 + 0.7 * iqTurbulence(point * 0.4 * (canyonsFreq * 2) + Randomize, 0.5)) * (0.08 * RidgedMultifractalDetail(point * 0.6 * (canyonsFreq * 2) + Randomize, 0.9, montBiomeScale)));
			//if (terrace < terraceProb)
			{
 			   terraceLayers *= 4.0; // Adjusted for less abrupt terracing
 			   float h = height * terraceLayers;
 			   height = (floor(h) + smoothstep(0.05, 0.85, fract(h))) / terraceLayers; // Adjusted for smoother terracing
			}
		}
	}
	else
	{
		// Mountains
		if (oceanType != 0.0)
		{
			noiseOctaves = 10.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.1;
			noiseOffset  = montesSpiky;
			// height = montesMagn * 5.0 * (0.5 + 0.4 * iqTurbulence(point * 0.5 * montesFreq + Randomize, 0.55))* 0.7* montesMagn * montRange * RidgedMultifractalErodedDetail(point * montesFreq * inv2montesSpiky + Randomize, 2.0, erosion, montBiomeScale)+ 0.6 * biomeScale * hillsMagn * JordanTurbulence(point/4 * deNerf/4 + Randomize, 0.8, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0);
			height = (0.5 + 0.4 * iqTurbulence(point * 0.5 * (montesFreq * 3) + Randomize, 0.55)) * 0.4 * montesMagn * montRange * RidgedMultifractalErodedDetail(point * (montesFreq * 3) * inv2montesSpiky + Randomize, 2.0, erosion, montBiomeScale);
		}
		else
		{
			noiseOctaves = 10.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.3;
			noiseOffset  = montesSpiky;
			height = montesMagn * 5.0 * ((0.5 + 0.8 * iqTurbulence(point * 0.5 * montesFreq + Randomize, 0.55)) * (0.1 * RidgedMultifractalDetail(point *  montesFreq + venus + Randomize, 1.0, montBiomeScale)));
		}
	}

	// Mare
	//	RODRIGO - Edited Mare. Supress mare in terras
	float mare = global;
	float mareFloor = global;
	float mareSuppress = 1.0;

	if (oceanType != 0.0)
	{
		mare = global;
	}
	else
	{
		if (mareSqrtDensity > 0.05 && mareFreq != 0.0)
		{
			//noiseOctaves = 2;
			//mareFloor = 0.6 * (1.0 - Cell3Noise(0.3*p));
			noiseH		   = 0.5;
			noiseLacunarity  = 2.218281828459;
			noiseOffset	  = 0.8;
			craterDistortion = 1.0;
			noiseOctaves	 = 6.0;  // Mare roundness distortion
			mare = MareNoise(point, global, 0.0, mareSuppress);
			//lithoCells *= 1.0 - saturate(20.0 * mare);
		}
	}

	height *= saturate(20.0 * mare);		// suppress mountains, canyons and hills (but not dunes) inside mare
	height = (height + heightD) * shore;	// suppress all landforms inside seas
	//height *= lithoCells;				 // suppress all landforms inside lava seas

	// Ice caps
	// Make more steep slope on oceanic planets (oceanType == 0.1) and shallower on earth-like planets (oceanType == 1.0)
	float oceaniaFade = (oceanType == 1.0) ? 0.2 : 1.0;
	// float iceCap = smoothstep(0.0, 1.0, saturate((latitude / latIceCaps - 1.0) * 50.0 * oceaniaFade)); // RMR version
	float iceCap = smoothstep(0.0, 1.0, saturate((latitude / latIceCaps - 1.0) * 5.0 * oceaniaFade));  // TPE Version

	// Ice cracks
	float mask = 1.0;
	if (cracksOctaves > 0.0)
	{
		landform = CrackNoise(point, mask) * iceCap;
		height += landform;
	}

	// Craters
	float crater = 0.0;
	if (craterSqrtDensity > 0.05)
	{
		heightFloor = -0.1;
		heightPeak  =  0.6;
		heightRim   =  1.0;
		crater = CraterNoise(point, 0.5 * craterMagn, craterFreq, craterSqrtDensity, craterOctaves);
		noiseOctaves	= 10.0;
		noiseLacunarity = 2.0;
		crater = 0.2 * crater + 0.05 * crater * RidgedMultifractalErodedDetail(point * 0.5 * montesFreq + Randomize, 2.0, 0.55 * crater, erosion);
	}

	height += mare + crater;

	// Sea bottom
	/*const float seaBottomTranstionStart = 0.0008;
	const float seaBottomTranstionEnd   = 0.0010;
	float depth = height - seaLevel;*/

	//	RODRIGO - Edited Rivers and Rifts. No more inverse rifts on mare
	float rodrigoDamping;
	rodrigoDamping = global - seaLevel - rodrigoDamping;
	float damping;

	// Pseudo rivers
	if ((riversMagn > 0.0) && (climateSteppeMax > 0) && (climateForestMax > 0) && (climateGrassMax > 0))
	{
		if (erosion >= 0.101)
		{
			noiseOctaves = 12.0;
			noiseH	   = 0.8;
			noiseLacunarity = 2.3;
			p = point * 2.0 * mainFreq + Randomize;
			distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01* RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky + 1)) + Randomize, 8.0, erosion, montBiomeScale * 2);
			cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
			/*
			float pseudoRivers2 = 1.0 - (saturate(0.36 * abs(cell.y - cell.x) * riversMagn));
				pseudoRivers2 = smoothstep(0.25, 0.99, pseudoRivers2); 
				pseudoRivers2 *= 1.0 - smoothstep(0.075, 0.085, rodrigoDamping); // disable rivers inside continents
				pseudoRivers2 *= 1.0 - smoothstep(0.000, 0.0001, seaLevel - height); // disable rivers inside oceans
				height = mix(height, seaLevel + 0.003, pseudoRivers2);
			float RmPseudoRivers = 1.0 - (saturate(2.8 * abs(cell.y - cell.x) * riversMagn));
				RmPseudoRivers = smoothstep(0.0, 1.0, RmPseudoRivers); 
				RmPseudoRivers *= 1.0 - smoothstep(0.085, 0.087, global-seaLevel);
				RmPseudoRivers *= 1.0 - smoothstep(0.00, 0.005, seaLevel - height); // disable rivers inside oceans
				height = mix(height, seaLevel - 0.0035, RmPseudoRivers);
			*/
			damping = (smoothstep(0.165, 0.155, rodrigoDamping)) * (smoothstep(-0.0016, -0.018, seaLevel - height));  // disable rivers inside oceans
			_PseudoRivers(point, damping, height);
			
			// Cracks
			damping = (smoothstep(cracksMagn * 0.5 + 0.01, cracksMagn * 0.5, rodrigoDamping)) * (smoothstep(-0.0016, -0.018 - pow(0.992, (1 / seaLevel)) * 0.09, seaLevel - height));
			_PseudoCracks(point, damping, height);
		}
		else
		{
			noiseOctaves	= riversSin;
			noiseLacunarity = 2.218281828459;
			noiseH		  = 0.5;
			noiseOffset	 = 0.8;
			p = point * mainFreq + Randomize;
			distort = 0.350 * Fbm3D(p * riversSin) + 0.035 * Fbm3D(p * riversSin * 5.0) + 0.010 * Fbm3D(p * riversSin * 25.0);
			cell = Cell3Noise2(riversFreq * p + distort);
			float _PseudoRivers = 1.0 - saturate(abs(cell.y - cell.x) * riversMagn);
				_PseudoRivers = smoothstep(0.0, 1.0, _PseudoRivers);
				_PseudoRivers *= 1.0 - smoothstep(0.06, 0.10, rodrigoDamping); // disable rivers inside continents
				_PseudoRivers *= 1.0 - smoothstep(0.00, 0.01, seaLevel - height); // disable rivers inside oceans
				height = mix(height, seaLevel-0.02, _PseudoRivers);
				
				damping = (smoothstep(0.145, 0.135, rodrigoDamping)) *	// disable rivers inside continents
						(smoothstep(-0.0016, -0.018, seaLevel - height));  // disable rivers inside oceans
				PseudoRivers(point, global, damping, height);
				
			// Cracks
			damping = (smoothstep(cracksMagn * 0.5 + 0.01, cracksMagn * 0.5, rodrigoDamping)) * (smoothstep(-0.0016, -0.018 - pow(0.992, (1 / seaLevel)) * 0.09, seaLevel - height));
			_PseudoCracks(point, damping, height);
		}
	}
	else if (riversMagn > 0.0)
	{
		noiseOctaves = 12.0;
		noiseH	   = 0.8;
		noiseLacunarity = 2.3;
		p = point * 2.0 * mainFreq + Randomize;
		distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky + 1)) + Randomize, 8.0, erosion, montBiomeScale * 2);
		cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
		damping = (smoothstep(0.145, 0.135, rodrigoDamping)) *	// disable rivers inside continents
			(smoothstep(-0.0016, -0.018, seaLevel - height));  // disable rivers inside oceans
		_PseudoRivers(point, damping, height);

		// Cracks
		damping = (smoothstep(cracksMagn * 0.5 + 0.01, cracksMagn * 0.5, rodrigoDamping)) * (smoothstep(-0.0016, -0.018 - pow(0.992, (1 / seaLevel)) * 0.09, seaLevel - height));
		_PseudoCracks(point, damping, height);
	}

	// Rifts
	if (riftsMagn > 0.0)
	{
		damping = (smoothstep(1.0, 0.1, height - seaLevel)) * (smoothstep(-0.1, -0.2, seaLevel - height));
		_Rifts(point, damping, height);
	}

	// Shield volcano
	if (volcanoOctaves > 0)
		height = VolcanoNoise(point, global, height);

	// Mountain glaciers
	if (climate > 0.9)
	{
		noiseOctaves = 4.0; // Reduced for more natural variation
		noiseLacunarity = 2.5; // Adjusted for smoother transitions
		float glacierVary = Fbm(point * 1500.0 + Randomize); // Adjusted scale for more realistic glacier patterns
		float snowLine = (height + 0.2 * glacierVary - snowLevel) / (1.0 - snowLevel); // Subtle variation along the snowline
		height += 0.0003 * smoothstep(0.0, 0.25, snowLine); // Adjusted for gradual buildup of glaciers
	}

	// Apply ice caps
	// Suppress everything except ice caps in oceanic planets
	//height = height * oceaniaFade + (seaLevel + icecapHeight) * iceCap; // old version
	// height = height * oceaniaFade + (0.3 * seaLevel + icecapHeight) * iceCap; // donatelo version
	height = height * oceaniaFade + icecapHeight * 5.0 * smoothstep(0.0, snowLevel, iceCap) * ((RidgedMultifractalErodedDetail(point * (venusFreq + dunesFreq) + Randomize, 2.0, (erosion * 1.5), iceCap) * icecapHeight + 9.2) * 0.1);  // TPE Version
	/*
	// TerrainFeature // Rayed craters
	if (craterSqrtDensity * craterSqrtDensity * craterRayedFactor > 0.05 * 0.05)
	{
		heightFloor = -1.5;
		heightPeak = 0.15;
		heightRim = 1.0;
		float craterRayedDensity = craterSqrtDensity * sqrt(craterRayedFactor);
		float craterRayedOctaves = floor(craterOctaves + smoothstep(0.0, 0.5, craterRayedFactor) * 60.0);
		float craterRayedMagn = craterMagn * 0.25; // * pow(1.0, craterOctaves - craterRayedOctaves);  // toned down rayed crater depth donatelo200 12/07/2025
		crater = _RayedCraterNoise(point, craterRayedMagn, craterFreq, craterRayedDensity, craterRayedOctaves);
		height += crater * (height + 0.2);  // toned down rayed crater depth donatelo200 12/07/2025 (mostly works but some edge cases still break)
	}
	*/
	//	RODRIGO - Terrain noise matching albedo noise
	noiseOctaves	= 14.0;
	noiseLacunarity = 2.218281828459;
	noiseH = 0.6 + smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
	// distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	vec3 albedoVaryDistort = Fbm3D((point + Randomize) * 0.07) * 1.5; // Fbm3D((point + Randomize) * 0.07) * 1.5;
	if (cracksOctaves > 0)
	{
		noiseH += 0.3;
	}
	distort = JordanTurbulence3D((point + Randomize) * .07, 0.6, 0.6, 0.6, 0.8, 0.0, 1.0, 3.0) * (1.5 + venusMagn); // Fbm3D((point + Randomize) * 0.07) * 1.5;
	if (cracksOctaves == 0 && volcanoActivity >= 1.0)
	{
		distort = saturate(iqTurbulence3D(point + Randomize, 0.65)) * (2 * (min(volcanoActivity, 1.6) - 1)) * saturate(min(volcanoActivity, 1.6) - 0.5) * 2.0;
	}
	else if (cracksOctaves == 0 && volcanoActivity < 1.0)
	{
		distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	}
	
	float vary = 1.0 - 5 * (Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) + RidgedMultifractal(pp * 0.999, 8.0))));

	// Equatorial ridge
	if(eqridgeMagn > 0.0) {
		float prevHeight = height;

		noiseOctaves = 5.0;
		float x = point.y / eqridgeWidth;
		float ridgeHeight = exp(-0.5 * x * x);
		float ridgeModulate = 1.0;
		for(int i = 0; i < 5; i++) {
			ridgeModulate -= eqridgeModMagn * (Fbm(point * eqridgeModFreq - Randomize) * 0.5);
		}
		height += eqridgeMagn * ridgeHeight * ridgeModulate;

		noiseOctaves = 10.0;
		ridgeModulate = 1.0;
		for(int i = 0; i < 5; i++) {
			ridgeModulate -= eqridgeModMagn * (Fbm(point * eqridgeModFreq - Randomize) * 0.5);
		}
		height += eqridgeMagn * ridgeHeight * ridgeModulate * 0.1;
		height = max(height, prevHeight);
	}

	float drivenMaterial = 0.0;

	if(abs(drivenDarkening) >= 0.55) {
		noiseOctaves = 3;
		drivenMaterial = -point.z * sign(drivenDarkening);
		drivenMaterial += 0.2 * Fbm(point * 1.63);
		drivenMaterial = saturate(drivenMaterial);
		drivenMaterial *= (1.0 / 0.45 * 0.9 - abs(point.y)) * (drivenDarkening - 0.55);
	}
	
	height = mix(height, height + 0.0001,vary);
	
	// height = max(height, seaLevel + 0.057);
	
	// ocean basins
	if (oceanType != 0.0)
	{
		if (venusMagn < 0.05 || venusFreq < 0.5)
		{
			height = min(smoothstep(seaLevel - 0.08, seaLevel + 0.164, height), height); // reduce ocean depth near shore
			float h = smoothstep(seaLevel - 1.03, seaLevel + 0.18, height);
			height = mix(height, max(height, seaLevel + 0.0595), h);
		}
		else
		{
			height = min(smoothstep(seaLevel - 0.16, seaLevel + 0.184, height), height); // reduce ocean depth near shore
			float h = smoothstep(seaLevel - 1.23, seaLevel + 0.38, height);
			height = mix(height, max(height, seaLevel + 0.0595), h);
		}
	}
	
	// Centri Super-Oceanic Fix
	if (oceanType == 1.0)  
    {
        height = softPolyMin(height, 0.01, 0.5);
        height = softPolyMax(height, 0.0, 0.3);
    }
	else
	{
		// smoothly limit the height
		height = softPolyMin(height, 0.99, 0.3);
		height = softPolyMax(height, 0.05, 0.1);
	}

	if (riversMagn > 0.0)
	{
		HeightBiomeMap = vec4(height-0.06);
	}
	else
	{
		HeightBiomeMap = vec4(height);
	}
}

//-----------------------------------------------------------------------------

void main()
{
	vec3  point = GetSurfacePoint();
	HeightMapTerra(point, OutColor);
}

//-----------------------------------------------------------------------------

#endif

