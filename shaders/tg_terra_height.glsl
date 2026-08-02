#include "tg_rmr.glh" 
 
#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

//	RODRIGO - SMALL CHANGES TO RIVERS AND RIFTS
// Modified Rodrigo's rivers

void _PseudoRivers(vec3 point, float damping, inout float height)
{
	noiseOctaves = 8.0;
	noiseH = 1.0;
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
		distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 2.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.1 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2) * seaLevel;

		vec2 cell = 2.5 * Cell3Noise2(riversFreq * 3.0 * seaLevel * 0.2 * p + 0.5 * distort);

		valleys *= saturate(1.36 * abs(cell.y - cell.x) * riversMagn);
		rivers *= saturate(6.5 * abs(cell.y - cell.x) * riversMagn);
	}

	float errorcor = pow(0.992, (1 / seaLevel)); // Correct rivers on marine planets. seaLevel
												 // is slightly off from actual sea level. :/

	height = min(mix(height, seaLevel + 0.019 + errorcor * 0.042, (1.0 - valleys) * damping), height);
	height = min(mix(height, seaLevel + 0.004 + errorcor * 0.052, (1.0 - rivers) * damping * smoothstep(0.7, 0.68, seaLevel)), height); // dampen rivers at high seaLevel because
									// they become wider and more like cracks
									// even with error correction.
}

void _PseudoCracks(vec3 point, float damping, inout float height)
{
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

//	RODRIGO - SMALL CHANGES TO RIVERS AND RIFTS
// Modified Rodrigo's rivers

void    rdhPseudoRivers(vec3 point, float global, float damping, inout float height)
{
	noiseOctaves = 8.0;
	noiseH       = 1.0;
	noiseLacunarity = 2.1;
	float _seaLevel = seaLevel;

	vec3 p = point * 2.0* mainFreq + Randomize;
	vec3 distort = 0.325 * Fbm3D(p * riversSin);
	distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2);

	vec2 cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort); //(2.5 * height) * Cell3Noise2(riversFreq * p + 0.5 * distort);

	float errorcor = 0;  //Correct Rivers on marine planets pow(0.985, (1 / seaLevel));

	if (_seaLevel >= 0.0 && _seaLevel < 0.2)    //better correction somehow
	{
		errorcor = -20 * (_seaLevel * _seaLevel) + 9 *_seaLevel;
	}
	if (_seaLevel >= 0.2)
	{
		errorcor = 1.0;
	}

	//float adjust = pow(0.992, (height)) * 0 + 1;

	float valleys = 1.0 - (saturate((0.36) * abs(cell.y - cell.x) * riversMagn)); //1 - (saturate(0.36 * abs(cell.y - cell.x) * riversMagn))
	valleys = smoothstep(0.0, 1.0, valleys) * damping;
	height = mix(height, _seaLevel - 0.02 + errorcor*0.08, valleys); //.019 .042 .03  _seaLevel - 0.019 + errorcor*0.082, valleys)

	float rivers = 1.0 - (saturate(6.5 * abs(cell.y - cell.x) * riversMagn));
	rivers = smoothstep(0.0, 1.0, rivers) * damping;
	height = mix(height, _seaLevel - 0.04 + errorcor*0.092, rivers); //.004  .052  .015  _seaLevel - 0.04 + errorcor*0.092
}

//-----------------------------------------------------------------------------

//	RODRIGO - SMALL CHANGES TO RIVERS AND RIFTS
// Modified TPE's rivers

void rmrPseudoRiversTPE(vec3 point, float damping, inout float height)
{
	float _cracksOctaves = cracksOctaves;
	
	float _colorDistMagn = colorDistMagn;
	float colorDistMin = 0.065;
	if (_cracksOctaves > 0) // Prevent some planets from becoming chaos
	{
		colorDistMin = 0.058;
	}
	if (colorDistMagn <= colorDistMin) // Prevent some planets from becoming chaos
	{
		_colorDistMagn = colorDistMin;
	}
	
	noiseOctaves = 8.0;
	noiseH = 1.0;
	noiseLacunarity = 2.1;

	// FIX: Don't apply this separately in each octave (like before) so that
	// rivers don't become cutoff when intersecting each other at different
	// octaves.
	float valleys = 1.0;
	float rivers = 1.0;

	for (int i = 0; i < 3; i++)
	{
		vec3 p = point + i * riversFreq + Randomize;
		vec3 distort = 0.325 * Fbm3D(p * riversSin * 0.3);
		distort = 0.65 * Fbm3D(p * riversSin) + _colorDistMagn * JordanTurbulence(p * riversSin * 2.0, 0.7, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0) + 0.01 * RidgedMultifractalErodedDetail(p * 0.1 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2) * seaLevel;

		vec2 cell = 2.5 * Cell3Noise2(riversFreq * 3.0 * seaLevel * 0.2 * p + 0.5 * distort);

		valleys *= saturate(1.36 * abs(cell.y - cell.x) * riversMagn);
		rivers *= saturate(6.5 * abs(cell.y - cell.x) * riversMagn);
	}

	float errorcor = pow(0.992, (1 / seaLevel)); // Correct rivers on marine planets. seaLevel
												 // is slightly off from actual sea level. :/

	height = min(mix(height, seaLevel + 0.019 + errorcor * 0.042, (1.0 - valleys) * damping), height);
	height = min(mix(height, seaLevel + 0.004 + errorcor * 0.052, (1.0 - rivers) * damping * smoothstep(0.7, 0.68, seaLevel)), height); // dampen rivers at high seaLevel because
									// they become wider and more like cracks
									// even with error correction.
}

//	RODRIGO - SMALL CHANGES TO RIVERS AND RIFTS
// Modified Rodrigo's rivers

void    rdhPseudoRiversTPE(vec3 point, float global, float damping, inout float height)
{
	float _seaLevel = seaLevel;

	float _cracksOctaves = cracksOctaves;
	
	float _colorDistMagn = colorDistMagn;
	float colorDistMin = 0.065;
	if (_cracksOctaves > 0) // Prevent some planets from becoming chaos
	{
		colorDistMin = 0.058;
	}
	if (colorDistMagn <= colorDistMin) // Prevent some planets from becoming chaos
	{
		_colorDistMagn = colorDistMin;
	}
	
	noiseOctaves = 8.0;
	noiseH       = 1.0;
	noiseLacunarity = 2.1;
	vec3 p = point * 2.0 * riversFreq + Randomize;
	vec3 distort = 0.325 * Fbm3D(p * riversSin);
	distort = 0.65 * Fbm3D(p * riversSin) + _colorDistMagn * JordanTurbulence(p * riversSin * 5.0,0.7, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0) + 0.01 * RidgedMultifractalErodedDetail(p * 0.3 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2);

	vec2 cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort); //(2.5 * height) * Cell3Noise2(riversFreq * p + 0.5 * distort);

	float errorcor = 0;  //Correct Rivers on marine planets pow(0.985, (1 / seaLevel));

	if (_seaLevel >= 0.0 && _seaLevel < 0.2)    //better correction somehow
	{
		errorcor = -20 * (_seaLevel * _seaLevel) + 9 *_seaLevel;
	}
	if (_seaLevel >= 0.2)
	{
		errorcor = 1.0;
	}

	//float adjust = pow(0.992, (height)) * 0 + 1;

	float valleys = 1.0 - (saturate((0.36) * abs(cell.y - cell.x) * riversMagn)); //1 - (saturate(0.36 * abs(cell.y - cell.x) * riversMagn))
	valleys = smoothstep(0.0, 1.0, valleys) * damping;
	height = mix(height, _seaLevel - 0.02 + errorcor*0.08, valleys); //.019 .042 .03  _seaLevel - 0.019 + errorcor*0.082, valleys)

	float rivers = 1.0 - (saturate(6.5 * abs(cell.y - cell.x) * riversMagn));
	rivers = smoothstep(0.0, 1.0, rivers) * damping;
	height = mix(height, _seaLevel - 0.04 + errorcor*0.092, rivers); //.004  .052  .015  _seaLevel - 0.04 + errorcor*0.092
}

void rmrPseudoCracksTPE(vec3 point, float damping, inout float height)
{
	float _cracksOctaves = cracksOctaves;
	
	float _colorDistMagn = colorDistMagn;
	float colorDistMin = 0.065;
	if (_cracksOctaves > 0) // Prevent some planets from becoming chaos
	{
		colorDistMin = 0.058;
	}
	if (colorDistMagn <= colorDistMin) // Prevent some planets from becoming chaos
	{
		_colorDistMagn = colorDistMin;
	}
	
	noiseOctaves = 8.0;
	noiseH = 1.0;
	noiseLacunarity = 2.1;

	float cracks = 0.0;

	vec3 p = point * 2.0 * cracksFreq + Randomize;
	vec3 distort = 0.325 * Fbm3D(p * riversSin * 0.7);
	distort = 0.65 * Fbm3D(p * riversSin * 0.7) + _colorDistMagn * JordanTurbulence(p * riversSin * 6.0, 0.7, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0) + 0.01 * RidgedMultifractalErodedDetail(p * 0.3 * (canyonsFreq + 1000) * (0.5 * (1 / montesSpiky + 1)) + Randomize, 8.0, erosion, 2);

	vec2 cell = 2.5 * Cell3Noise2(cracksFreq * 10.0 * p + 0.5 * distort);

	cracks = 1.0 - (saturate(0.36 * abs(cell.y - cell.x) * cracksFreq * 10.0));
	cracks = smoothstep(0.0, 1.0, cracks) * damping;
	height = mix(height, seaLevel + 0.03, cracks);
}

//-----------------------------------------------------------------------------
// Modified Rodrigo's rifts

void    _Rifts(vec3 point, float damping, inout float height)
{
    float _seaLevel = seaLevel;
	float riftsBottom = _seaLevel;   //float riftsBottom = _seaLevel;

    noiseOctaves    = 6.6;
    noiseH          = 1.0;
    noiseLacunarity = 4.0;
    noiseOffset     = 0.95;

    // 2 slightly different octaves to make ridges inside rifts
    vec3 p = point * 0.12;
    float rifts = 0.0;
    for (int i=0; i<2; i++)
    {
        vec3  distort = 0.5 * Fbm3D(p * riftsSin)+ 0.1 * Fbm3D(p*3 * riftsSin);;
        vec2  cell = Cell3Noise2(riftsFreq * p + distort);
        float width = 0.8*riftsMagn * abs(cell.y - cell.x);
        rifts = softExpMaxMin(rifts, 1.0 - 2.75 * width, 32.0);
        p *= 1.02;
    }

    float riftsModulate = smoothstep(-0.1, 0.2, Fbm(point * 2.3 + Randomize));
    rifts = smoothstep(0.0,1.0, rifts * riftsModulate) * damping;

    height = mix(height, riftsBottom, rifts);

    // Slope modulation
    if (rifts > 0.0)
    {
        float slope = smoothstep(0.1, 0.9, 1.0 - 2.0 * abs(rifts * 0.35 - 0.5));
        float slopeMod = 0.5*slope * RidgedMultifractalErodedDetail(point * 5.0 * canyonsFreq + Randomize, 8.0, erosion, 8.0);
        slopeMod *= 0.05*riftsModulate;
        height = softExpMaxMin(height - slopeMod, riftsBottom, 75.0);
    }
}

//-----------------------------------------------------------------------------


// Function // Altered Crater Height Formula
	// 19-11-2024 by Sp_ce // Doubled peak height
float   Sp_ceCraterHeightFunc(float lastlastLand, float lastLand, float height, float r)
{
    float distHeight = craterDistortion * height;

    float t = 1.0 - r/radPeak;
    float peak = 2 * heightPeak * craterDistortion * smoothstep(0.0, 1.0, t);

    t = smoothstep(0.0, 1.0, (r - radInner) / (radRim - radInner));
    float inoutMask = t*t*t;
    float innerRim = heightRim * distHeight * smoothstep(0.0, 1.0, inoutMask);

    t = smoothstep(0.0, 1.0, (radOuter - r) / (radOuter - radRim));
    float outerRim = distHeight * mix(0.05, heightRim, t*t);

    t = saturate((1.0 - r) / (1.0 - radOuter));
    float halo = 0.05 * distHeight * t;

    return mix(lastlastLand + height * heightFloor + peak + innerRim, lastLand + outerRim + halo, inoutMask);
}


//-----------------------------------------------------------------------------


// Function // Altered Crater Noise
	// 14-11-2024 by Sp_ce // Changed rad values
	// 19-11-2024 by Sp_ce // Changed lastlastlastLand to lastlastLand
float   Sp_ceCraterNoise(vec3 point, float cratMagn, float cratFreq, float cratSqrtDensity, float cratOctaves)
{
    //craterSphereRadius = cratFreq * cratSqrtDensity;
    //point *= craterSphereRadius;
    point = (point * cratFreq + Randomize) * cratSqrtDensity;

    float  newLand = 0.0;
    float  lastLand = 0.0;
    float  lastlastLand = 0.0;
    float  lastlastlastLand = 0.0;
    float  amplitude = 1.0;
    float  cell;
    float  radFactor = 1.0 / cratSqrtDensity;

    // Craters roundness distortion
    noiseH           = 0.5;
    noiseLacunarity  = 2.218281828459;
    noiseOffset      = 0.8;
    noiseOctaves     = 3;
    craterDistortion = 1.0;
    craterRoundDist  = 0.03;
	
    radPeak  = 0.1;
    radInner = 0.1; //0.1
    radRim   = 0.35;//0.4
    radOuter = 0.7; //0.8
	/*
	radPeak  = 0.03;
    radInner = 0.15;
    radRim   = 0.2;
    radOuter = 0.8;
	*/
    for (int i=0; i<cratOctaves; i++)
    {
        lastlastlastLand = lastlastLand;
        lastlastLand = lastLand;
        lastLand = newLand;

        /*
		vec3 dist = craterRoundDist * Fbm3D(point*2.56);
        //cell = Cell2NoiseSphere(point + dist, craterSphereRadius, dist).w;
        //craterSphereRadius *= 1.83;
		*/
        cell = Cell3Noise(point + craterRoundDist * Fbm3D(point * 2.56));
        newLand = Sp_ceCraterHeightFunc(lastlastLand, lastLand, amplitude, cell * radFactor);

        /*
		//cell = inverseSF(point + 0.2 * craterRoundDist * Fbm3D(point*2.56), fibFreq);
        //rad = hash1(cell.x * 743.1) * 0.9 + 0.1;
        //newLand = CraterHeightFunc(lastlastlastLand, lastLand, amplitude, cell.y * radFactor / rad);
        //fibFreq   *= craterFreqPower;
        //radFactor *= craterRadFactorPower;
		*/

        if (cratOctaves > 1)
        {
            point       *= craterFreqPower;
            amplitude   *= craterAmplPower;
            heightPeak  *= craterPeakPower;
            heightFloor *= craterFloorPower;
            radInner    *= craterRadiusPower;
        }
    }

    return  cratMagn * newLand;
}

//-----------------------------------------------------------------------------

void HeightMapTerra(vec3 point, out vec4 HeightBiomeMap)
{
	float _seaLevel = seaLevel;
	
	float _hillsMagn = hillsMagn;
	if (hillsMagn < 0.1)
	{
		_hillsMagn = 0.1;
	}
	else
	{
		_hillsMagn = hillsMagn;
	}
	
	float _hillsFreq = hillsFreq;
	if (volcanoMagn != 0.0)
	{
		if (riversMagn > 0.0 && cracksOctaves == 0 && texScale > 8200)
		{
			_hillsFreq = hillsFreq * 8;
		}
		else if (riversMagn == 0.0 && cracksOctaves > 0 && oceanType < 0.5)
		{
			_hillsFreq = hillsFreq * (1 - volcanoActivity / 6) * 3;
		}
		else if (riversMagn > 0.0 && cracksOctaves > 0 && texScale > 8200)
		{
			_hillsFreq = hillsFreq * (1 - volcanoActivity / 4);
		}
		else
		{
			_hillsFreq = hillsFreq;
		}
	}
	else
	{
		if (oceanType != 0.0)
		{
			_hillsFreq = hillsFreq * 8;
		}
		else
		{
			_hillsFreq = hillsFreq;
		}
	}
	
	float _montesFreq = montesFreq;
	if (oceanType != 0.0 && texScale < 4200)
	{
		_montesFreq = montesFreq * 10;
	}
	else
	{
		_montesFreq = montesFreq;
	}
	
	float _cracksOctaves = cracksOctaves;
	
	float _colorDistMagn = colorDistMagn;
	float colorDistMin = 0.065;
	if (_cracksOctaves > 0) // Prevent some planets from becoming chaos
	{
		colorDistMin = 0.058;
	}
	if (colorDistMagn <= colorDistMin) // Prevent some planets from becoming chaos
	{
		_colorDistMagn = colorDistMin;
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
	
	if (oceanType == 0.0)
		noiseH = 1.0;
	
	vec3 distort = 0.35 * Fbm3D(p * 0.73);
	float rocks = -0.005 * iqTurbulence(point * 200.0, 1.0) * smoothstep(2.0, 1.0, volcanoActivity);
	// float rocks = -0.013 * iqTurbulence(point * 80 , 1);
	rocks = smoothstep(-0.9, 0.1, rocks);
	if (texScale <= 32000.0)
	{
		distort += 0.005 * (1.0 - abs(smoothstep(0.2, 0.01, JordanTurbulence3D(p * _montesFreq, volcanoFreq / 2, volcanoActivity / 2, montesMagn * 2, hillsMagn * 2, venusMagn, venusFreq, mainFreq))));
	}
	else
	{
		distort += 0.005 * (1.0 - abs(smoothstep(0.2, 0.01, JordanTurbulence3D(p * montesFreq / 10, volcanoFreq / 2, volcanoActivity / 2, montesMagn * 2, hillsMagn * 2, venusMagn, venusFreq, mainFreq))));
		// distort += 0.005 * (1.0 - abs(smoothstep(0.2, 0.01, JordanTurbulence3D(p * 132.3, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0))));
	}
	float global;
	if (volcanoActivity >= 1.5 && venusMagn >= 1.5 && volcanoMagn != 0.0)
	{
		global = 1.0 - smoothstep(0.1, 0.0, JordanTurbulence(p + distort * _hillsMagn + Randomize, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, _colorDistMagn) * mainFreq);
	}
	else if (volcanoActivity >= 1 && volcanoMagn != 0.0)
	{
		global = 1.0 - smoothstep(0.0, 1.0, iqTurbulence(p + distort + Randomize, smoothstep(0.1, 0.0, _colorDistMagn) * mainFreq));
	}
	else
	{
		global = 1.0 - RidgedMultifractal(p + distort + Randomize, 1.0);
	}
	noiseOctaves = 12;

	// Make sea bottom more flat; shallow seas resembles those on Titan;
	// but this shrinks out continents, so value larger than 1.5 is unwanted
	global = softPolyMax(global, 0.0, 0.1);
	global = pow(global, 1.5);

	// Reduce height of land to allow rivers to appear at "higher" altitudes;
	// _seaLevel shouldn't be just a sphere, this is a workaround! Use smoothstep
	// to avoid "islands" where low values that are otherwise oceans become land
	// again, limit it to _seaLevel.
	if (oceanType != 0.0)
	{
		global = mix(global + 0.1, pow(2.71828, global + 0.1) * _hillsMagn, smoothstep(_seaLevel, 1.2, global));
	}

	// Venus-like structure
	float venus = 0.0;
	if (oceanType > 0.0)
	{
		noiseOctaves = 4;
		noiseH = 1.0;
		noiseLacunarity = 2.1;
		// noiseOffset = montesSpiky;
		distort = JordanTurbulence3D(p * _hillsMagn + (point + Randomize) * 0.07, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0) * (1.5 + venusMagn);
		// distort = Fbm3D(point * 0.3) * 1.5;
		venus = Fbm((point + distort + Randomize) * venusFreq) * (venusMagn + 0.3);
	}
	else
	{
		noiseOctaves = 6;
		noiseH = 1.0;
		noiseLacunarity = 2.3;
		distort = JordanTurbulence3D(point * _hillsMagn + (point + Randomize) * 0.07, 0.8, 0.5, 0.6, 0.35, 0.0, 1.8, 1.0) * (1.5 + venusMagn);
		// distort = Fbm3D(point * 0.3) * 1.5;
		venus = Fbm((point + distort + Randomize) * venusFreq) * (venusMagn + 0.3);
	}

	global = (global + venus - _seaLevel) * 0.5 + _seaLevel;
	global = clamp(global, _seaLevel - 0.1, _seaLevel + 0.1);
	float shore = saturate(70.0 * (global - _seaLevel));

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

	float montRange = saturate(DistNoise(p * 22.6 + Randomize, 2.5) + 0.5);
	montRange *= montRange;
	float montBiomeScale = min(pow(2.2 * biomeScale, 3.5), 1.0) * montRange;

	float inv2montesSpiky = 1.0 / (montesSpiky * montesSpiky);
	float heightD  = 0.0;
	float height   = 0.0;
	float landform = 0.0;
	float dist;

	//	RODRIGO
		noiseOctaves = 8;
		noiseH = 1.0;
		noiseLacunarity = 2.3;
		noiseOffset = montesSpiky;
		vec3 pp = (point + Randomize) * (0.0005 * _hillsFreq / (hillsMagn * hillsMagn));
		landform = RidgedMultifractalErodedDetail(pp * Randomize, mainFreq, erosion, global);

	//small terrain elevations
		/*
		float fr = 0.20 * (1.5 - RidgedMultifractal(pp, 2.0)) + 0.05 * (1.5 - RidgedMultifractal(pp * 10.0,  2.0));
		fr *= 1 - smoothstep(0.0, 0.02, _seaLevel-global);
		global = mix(global,global+0.2,fr);
		*/
		float fr = 0.40 * (1.0 - RidgedMultifractal(pp, 2.0)) + 0.85 * (1.0 - RidgedMultifractal(pp * 10.0, 2.0)) + rocks;
		fr *= 1 - smoothstep(-0.005, 0.01, _seaLevel - global);
		global = global + (0.00000001 * (_hillsFreq * _hillsFreq + 900000) * fr);
		
	//Mesas		
		float zr = 1.0 + 2 * Fbm(point + landform) + 7 * (1.5 - RidgedMultifractalEroded(pp * 0.8, 8.0, erosion)) - 6 * (1.5 - RidgedMultifractalEroded(pp * 0.1, 8.0, erosion)) - 0.01 * (1.5 - RidgedMultifractalEroded(pp * 4, 8.0, erosion));
		zr = smoothstep(0.0, 1.0, 0.2 * zr * zr);
		zr *= 1 - smoothstep(0.0, 0.02, _seaLevel - global);
		zr = 0.1 * _hillsFreq * smoothstep(0.0, 1.0, zr);
		global =  mix(global, global + 0.0006, zr);

		float rr  = 0.3 * ((0.15 * iqTurbulence(point * 0.4 * _montesFreq + Randomize, 0.45)) * (RidgedMultifractalDetail(point * _montesFreq * 0.8 + venus + Randomize, 1.0, montBiomeScale)));
		rr *= 1 - smoothstep(0.0, 0.02, _seaLevel - global);
		global += rr;

	// global = saturate(0.99 * global);
	global = global + 0.06 * saturate((fr * zr * rr) * _hillsMagn);
	// global = 0.9 * global + 0.06 * fr;
	/*
	//Eroded terrain & Mesas no rocks
		float t1 = 1.0; 
			t1 *= 1.0 - smoothstep(0.05, 0.105, global-_seaLevel); 
		t1 *= 1.0 - smoothstep(-0.05, -0.025, _seaLevel - global); 
			height = mix(height, height + 0.008, t1);
		float t2 = 1.0; 
			t2 *= 1.0 - smoothstep(0.13, 0.185, global-_seaLevel); 
		t2 *= 1.0 - smoothstep(-0.13, -0.105, _seaLevel - global); 
			height = mix(height, height + 0.010, t2);
		float t4 = 1.0; 
			t4 *= 1.0 - smoothstep(0.21, 0.265, global-_seaLevel); 
		t4*= 1.0 - smoothstep(-0.21, -0.185, _seaLevel - global); 
			height = mix(height, height + 0.010, t4);
		float t6 = 1.0; 
			t6*= 1.0 - smoothstep(-0.29, -0.265, global-_seaLevel); 
		height = mix(height, height + 0.010, t6);
		*/
	//Eroded terrain & Mesas with rocks
		float t1 = 1.0; 
			t1 *= 1.0 - smoothstep(0.03, 0.105, global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel);
		t1 *= 1.0 - smoothstep(-0.03, -0.026, _seaLevel - (global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel));
			height = mix(height, height + 0.008, t1);
		float t2 = 1.0; 
			t2 *= 1.0 - smoothstep(0.11, 0.185, global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel);
		t2 *= 1.0 - smoothstep(-0.11, -0.106, _seaLevel - (global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel));
			height = mix(height, height + 0.008, t2);
		float t4 = 1.0; 
			t4 *= 1.0 - smoothstep(0.19, 0.265, global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel);
		t4*= 1.0 - smoothstep(-0.19, -0.186, _seaLevel - (global- (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel));
			height = mix(height, height + 0.008, t4);
		float t6 = 1.0; 
			t6*= 1.0 - smoothstep(-0.27, -0.266, global - (0.000000008 * (_hillsFreq * _hillsFreq + 900000) * rocks) - _seaLevel);
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
		noiseOctaves = 8.0;
		noiseH	   = 1.0;
		noiseLacunarity = 2.0;
		noiseOffset  = montesSpiky;
		if (oceanType != 0.0)
		{
			
			height = hillsMagn * 2.4 * ((1.25 + iqTurbulence(point * 0.5 * _hillsFreq * inv2montesSpiky * 1.25 + Randomize, 0.55)) * (0.05 * RidgedMultifractalErodedDetail(point * 1.0 * _hillsFreq * inv2montesSpiky * 1.5 + Randomize, 1.0, erosion, montBiomeScale)));
			
			// height = hillsMagn * swissTurbulence(point * hillsFreq, 1.0, 1.0, 1.0);
		}
		else
		{
			height = hillsMagn * 7.5 * ((1.25 + iqTurbulence(point * 0.5 * (_hillsFreq / 2) * inv2montesSpiky * 1.25 + Randomize, 0.55)) * (0.05 * RidgedMultifractalDetail(point * 1.0 * (_hillsFreq / 2) * inv2montesSpiky * 1.5 + Randomize, 1.0, montBiomeScale)));
		}
	}
	else if (biome < hills2Fraction)
	{
		// "Eroded" hills
		if (oceanType != 0.0)
		{
			noiseOctaves = 6.0;
			noiseH	   = 1.0;
			noiseLacunarity = 2.1;
			height = (0.5 + 0.4 * iqTurbulence(point * 0.5 * _hillsFreq + Randomize, 0.55)) * (montBiomeScale * hillsMagn * (0.05 - (0.4 * RidgedMultifractalDetail(point * _hillsFreq + Randomize, 2.0, venus)) + 0.3 * RidgedMultifractalErodedDetail(point * _hillsFreq + Randomize, 2.0, 1.1 * erosion, montBiomeScale)));
		}
		else
		{
			noiseOctaves = 4.0;
			noiseLacunarity = 2.3;
			height = montBiomeScale * hillsMagn * JordanTurbulence(point * _hillsFreq + Randomize, 0.7, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0);
		}
	}
	else if (biome < canyonsFraction)
	{
		if (oceanType != 0.0)
		{
			// TPE Canyons
			noiseOctaves = 9.0;
			noiseH       = 1.0;
			noiseLacunarity = 2.0;
			// noiseLacunarity = 3.0;
			noiseOffset  = montesSpiky;
			// height = -canyonsMagn * 0.015 * (5 + 0.2 * iqTurbulence(point * 0.5 * canyonsFreq + Randomize, 0.55)) * (5 * RidgedMultifractalDetail(point * 0.7 * canyonsFreq + Randomize, 1.0, montBiomeScale));
			height = -canyonsMagn * 5 * (0.5 + 0.8 * iqTurbulence(p * 0.5 * (canyonsFreq * 3) + Randomize, 0.55)) * (_colorDistMagn * RidgedMultifractalErodedDetail(p * 0.7 * (canyonsFreq * 3) + Randomize, 1.0, erosion, montBiomeScale));
			// if (terrace < terraceProb)
			{
				float h = height * terraceLayers * 5.0;
				height = (floor(h) + smoothstep(0.1, 0.9, fract(h))) / terraceLayers;
			}
		}
		else
		{
			// Rodrigo Canyons
			noiseOctaves    = 5.0;
			noiseH          = 0.9;
			noiseLacunarity = 4;
			noiseOffset  = montesSpiky;
			height = -0.5 * canyonsMagn * montRange * RidgedMultifractalErodedDetail(point * 1.2 * canyonsFreq * inv2montesSpiky + Randomize, 2.0, erosion, montBiomeScale);
			float h = height * terraceLayers;
			height = (floor(h) + smoothstep(0.5, 0.6, fract(h))) / terraceLayers;
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
			// height = montesMagn * 5.0 * (0.5 + 0.4 * iqTurbulence(point * 0.5 * montesFreq + Randomize, 0.55))* 0.7* montesMagn * montRange * RidgedMultifractalErodedDetail(point * montesFreq * inv2montesSpiky + Randomize, 2.0, erosion, montBiomeScale)+ 0.6 * biomeScale * hillsMagn * JordanTurbulence(point/4 * _hillsFreq/4 + Randomize, 0.8, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0);
			height = (0.5 + 0.4 * iqTurbulence(point * 0.5 * (montesFreq * 3) + Randomize, 0.55)) * 0.4 * montesMagn * montRange * RidgedMultifractalErodedDetail(point * (montesFreq * 3) * inv2montesSpiky + Randomize, 2.0, erosion, montBiomeScale);
		}
		else
		{
			noiseOctaves = 8.0;
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
	float iceCap = smoothstep(0.0, 1.0, saturate((latitude / latIceCaps - 1.0) * 50.0 * oceaniaFade));  // TPE Version

	// Ice cracks
	float mask = 1.0;
	if (cracksOctaves > 0.0)
	{
		landform = CrackNoise(point, mask) * iceCap;
		height += landform;
	}

	// Mountain glaciers
	if (climate > 0.9)
	{
		noiseOctaves = 4.0; // Reduced for more natural variation
		noiseLacunarity = 2.5; // Adjusted for smoother transitions
		float glacierVary = Fbm(point * 1500.0 + Randomize); // Adjusted scale for more realistic glacier patterns
		float snowLine = (height + 0.2 * glacierVary - snowLevel) / (1.0 - snowLevel); // Subtle variation along the snowline
		height += 0.0003 * smoothstep(0.0, 0.25, snowLine); // Adjusted for gradual buildup of glaciers
	}

	// Craters
	float crater = 0.0;
	if (craterSqrtDensity > 0.05)
	{
		float craterSqrtDensityAltered = max(craterSqrtDensity * (0.2 + 0.8), 10 * (craterSqrtDensity - 0.9));
	
        heightFloor = -0.1;
        heightPeak  =  0.6;
        heightRim   =  1.0;
		float craterFreqNew = max(craterFreq, 3.0);
		crater = saturate(mareSuppress + Fbm(point)) * Sp_ceCraterNoise(point, craterMagn, craterFreq, craterSqrtDensityAltered * (1 - (volcanoActivity / 2.1)), craterOctaves);
		//crater = mareSuppress * Sp_ceCraterNoise(point, craterMagn, craterFreq, craterSqrtDensityAltered * (1 - (volcanoActivity / 2.1))), craterOctaves);
        noiseOctaves    = 10.0;
        noiseLacunarity = 2.0;
        //crater = 0.25 * crater + 0.05 * crater * iqTurbulence(point * montesFreq + Randomize, 0.55);
		crater = 0.25 * crater - 0.1;

		// Suppress Young Craters
        noiseOctaves = 4.0;
        vec3 youngDistort = Fbm3D((point - Randomize) * 0.07) * 1.1;
        noiseOctaves = 8.0;
        float young = 1.0 - Fbm(point + youngDistort);
        young = smoothstep(0.0, 1.0, young * young * young);
        //crater *= young;
	}

	height += mare + crater;

	// Sea bottom
	/*const float seaBottomTranstionStart = 0.0008;
	const float seaBottomTranstionEnd   = 0.0010;
	float depth = height - _seaLevel;*/

	//	RODRIGO - Terrain noise matching albedo noise
	noiseOctaves	= 14.0;
	noiseLacunarity = 2.218281828459;
	noiseH = 0.6 + smoothstep(0.0, 0.1, _colorDistMagn) * 0.5;
	// distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
	distort = Fbm3D((point + Randomize) * 1.0);  // Fbm3D((point + Randomize) * 0.07) * 1.5;  useless terrain elevation imo
	float SmallDistort = 0;
	if (cracksOctaves > 0) 
	{
		noiseH = 0.6 + smoothstep(0.0, 0.1, _colorDistMagn) * 0.7;;
	}
	if (volcanoMagn != 0.0)
	{
		if (cracksOctaves == 0 && volcanoActivity > 1.0)
		{
			distort = (saturate(iqTurbulence(point + Randomize, 0.55) * (2 * (volcanoActivity - 1)))) * (volcanoActivity - 1) + (Fbm3D((point + Randomize) * 0.07) * 0) * (2 - volcanoActivity);  //Io like on atmosphered planets
			SmallDistort = saturate(iqTurbulence(point + Randomize, 0.75) * (2 * (volcanoActivity - 1))) * (volcanoActivity - 1);
		}
		else if (cracksOctaves == 0 && volcanoActivity < 1.0)
		{
			distort = Fbm3D((point + Randomize) * 0.07) * 0;  //Normal non-volcanic (also useless noise but shader breaks if removed
		}
		else if (cracksOctaves > 0) //&& riversMagn == 0)
		{
			distort =Fbm3D((point * 0.26 + Randomize) * (volcanoActivity / 2 + 1)) * (1.5 + venusMagn ) + saturate(iqTurbulence(point + Randomize, 0.15) * volcanoActivity);
		}
	}
	
	float vary = 1.0 - 5 * (Fbm((point + distort + (SmallDistort * 0.015)) * (1.5 - RidgedMultifractal(pp, 8.0) + RidgedMultifractal(pp * 0.999, 8.0))));

	//	RODRIGO - Edited Rivers and Rifts. No more inverse rifts on mare
	float rodrigoDamping;
	rodrigoDamping = global - _seaLevel - rodrigoDamping;
	float damping;
	float _rodrigoDamping = rodrigoDamping;

	// Rifts
	if (riftsMagn > 0.0)
	{
		damping = (smoothstep(1.0, 0.1, height - _seaLevel)) * (smoothstep(-0.1, -0.2, _seaLevel - height));
		_Rifts(point, damping, height);
	}

	// Pseudo rivers
	if (riversMagn > 0.0)
	{
		if (cracksOctaves > 0)
		{
			rodrigoDamping =  - _seaLevel + global / (1.0 + _seaLevel * 10) - rodrigoDamping + height;  //Dampen rivers under extreme elevations
		}
		//	if (cracksOctaves > 0)
		//	{
		//		rodrigoDamping = height * 1.5 - _seaLevel - rodrigoDamping;  //Dampen rivers under extreme elevations
		//	}
		/*
		// TPE Rivers for lifeterras, RMR rivers for lifeless terras.
		if ((climateSteppeMax > -1.0) && (climateForestMax > -1.0) && (climateGrassMax > -1.0))
		{
			noiseOctaves = 14.0;
			noiseH       = 1.0;
			noiseLacunarity = 2.1;
			p = point * 2.0 * riversFreq + Randomize;
			distort = 0.65 * Fbm3D(p * riversSin) + _colorDistMagn * JordanTurbulence(p * riversSin * Randomize, 0.7, 0.5, 0.6, 0.35, 1.0, 0.8, rodrigoDamping) + 0.01 * RidgedMultifractalErodedDetail(p * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky + 1.0)) + Randomize, 8.0, erosion, rodrigoDamping);
			cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
			float pseudoRivers2 = 1.0 - (saturate(0.36 * abs(cell.y - cell.x) * riversMagn));
				pseudoRivers2 = smoothstep(0.25, 0.99, pseudoRivers2); 
				pseudoRivers2 *= 1.0 - smoothstep(0.055, 0.365, global - _seaLevel); // disable rivers inside continents
				pseudoRivers2 *= 1.0 - smoothstep(0.0, 0.0001, _seaLevel - height); // disable rivers inside oceans
				height = mix(height, _seaLevel + 0.001, pseudoRivers2);
			cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
			float pseudoRivers = 1.0 - (saturate(3.2 * abs(cell.y - cell.x) * riversMagn));
				pseudoRivers = smoothstep(0.0, 1.0, pseudoRivers); 
				pseudoRivers *= 1.0 - smoothstep(0.055, 0.257, global - _seaLevel); // disable rivers inside continents
				pseudoRivers *= 1.0 - smoothstep(0.0, 0.05, _seaLevel - height); // disable rivers inside oceans
				height = mix(height, _seaLevel - 0.035, pseudoRivers);
		}
		else
		{
			noiseOctaves = 12.0;
			noiseH = 0.8;
			noiseLacunarity = 2.3;
			p = point * 2.0 * mainFreq + Randomize;
			distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky + 1)) + Randomize, 8.0, erosion, montBiomeScale * 2);
			cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
			
			damping = (smoothstep(0.1, 0.0, _seaLevel - height)) * // disable rivers inside continents
					  (smoothstep(-0.0016, -0.018, _seaLevel - height)); // disable rivers inside oceans
			_PseudoRivers(point, damping, height);
		}
		*/
		/*
		// RMR+TPE Rivers for lifeterras, default RMR rivers for lifeless terras.
		if ((climateSteppeMax > -1.0) && (climateForestMax > -1.0) && (climateGrassMax > -1.0))
		{
			noiseOctaves = 12.0;
			noiseH = 0.8;
			noiseLacunarity = 2.3;
			p = point * 2.0 * mainFreq + Randomize;
			distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky + 1)) + Randomize, 8.0, erosion, montBiomeScale * 2);
			cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);
			
			damping = (smoothstep(0.1, 0.0, _seaLevel - height)) * // disable rivers inside continents
					  (smoothstep(-0.0016, -0.018, _seaLevel - height)); // disable rivers inside oceans
			rmrPseudoRiversTPE(point, damping, height);
		}
		else
		{
			damping = (smoothstep(0.01, 0.0, _seaLevel - height)) * // disable rivers inside continents
					  (smoothstep(-0.0016, -0.018, _seaLevel - height)); // disable rivers inside oceans
			_PseudoRivers(point, damping, height);
		}
		*/
		
		// RDH+TPE Rivers for lifeterras, default RDH rivers for lifeless terras.
		if ((climateSteppeMax > -1.0) && (climateForestMax > -1.0) && (climateGrassMax > -1.0))
		{
			noiseOctaves = 12.0;
			noiseH       = 0.8;
			noiseLacunarity = 2.3;
			//p = point * 2.0* mainFreq + Randomize;
			//distort = 0.65 * Fbm3D(p * riversSin) + 0.03 * Fbm3D(p * riversSin * 5.0) + 0.01 * RidgedMultifractalErodedDetail(point * 0.3 * (canyonsFreq + 1000) * (0.5 * (inv2montesSpiky+1)) + Randomize, 8.0, erosion, montBiomeScale * 2);
			//cell = 2.5 * Cell3Noise2(riversFreq * p + 0.5 * distort);

			damping = (smoothstep(0.185, 0.135, rodrigoDamping)) *  // disable rivers inside continents smoothstep(0.145, 0.135, rodrigoDamping)  smoothstep(0.185, 0.135, rodrigoDamping)
					  (smoothstep(-0.016, -0.018 - pow(0.99, (1 / _seaLevel)) * 0.14, _seaLevel - height));  // disable rivers inside oceans
			rdhPseudoRiversTPE(point, global, damping, height);
		}
		else
		{
			damping = (smoothstep(0.185, 0.135, rodrigoDamping)) *  // disable rivers inside continents smoothstep(0.145, 0.135, rodrigoDamping)  smoothstep(0.185, 0.135, rodrigoDamping)
					  (smoothstep(-0.016, -0.018 - pow(0.99, (1 / _seaLevel)) * 0.14, _seaLevel - height));  // disable rivers inside oceans
			rdhPseudoRivers(point, global, damping, height);
		}
		
		// Cracks
		damping = (smoothstep(cracksMagn * 0.5 + 0.01, cracksMagn * 0.5, rodrigoDamping)) * (smoothstep(-0.0016, -0.018 - pow(0.992, (1 / seaLevel)) * 0.09, seaLevel - height));
		rmrPseudoCracksTPE(point, damping, height);
	}

	// Shield volcano
	if (volcanoOctaves > 0)
		height = _VolcanoNoise(point, global, height);

	// Apply ice caps
	// Suppress everything except ice caps in oceanic planets
	// height = height * oceaniaFade + (_seaLevel + icecapHeight) * iceCap; // old version
	// height = height + (0.3 * _seaLevel + icecapHeight) * iceCap; // donatelo version
	height = height * oceaniaFade + icecapHeight * 5.0 * smoothstep(0.0, snowLevel, iceCap) * ((RidgedMultifractalErodedDetail(point * (venusFreq + dunesFreq) + Randomize, 2.0, (erosion * 1.5), iceCap) * icecapHeight + 9.2) * 0.1);  // TPE Version

	// Ice Belts for High Axial tilt custom planets. ~ TPE
	if(eqridgeMagn > 0.0 && eqridgeWidth > 0.05)
	{
		/*
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
		*/
		float prevHeight = height;
		//noiseOctaves	= 4.0;
		noiseOctaves	= 12.0;
		noiseLacunarity = 2.218281828459;
		noiseH		  = 0.9;
		noiseOffset	 = 0.5;
		float x = (point.y + 0.1 * Fbm(pp + Randomize)) / eqridgeWidth;
		float eqridgeHeight = pow(eqridgeMagn, 1.25);
		float ridgeHeight = exp(-0.75 * pow(abs(x), eqridgeModFreq));
		//height = max(height + (eqridgeMagn * ridgeHeight * iqTurbulence(point * 1.0 * eqridgeModFreq + Randomize, eqridgeModMagn)), height);
		//eqridgeModMagn 0.7 - 1.2
		//eqridgeModFreq 4
		// height = max(height + (eqridgeMagn * ridgeHeight * iqTurbulence(point * 0.4 * eqridgeModFreq + Randomize, 0.2 * eqridgeModMagn)), height);
		height *= eqridgeMagn + ridgeHeight * 5.0 * ((RidgedMultifractalErodedDetail(point * (montesFreq + _hillsFreq) + Randomize, 2.0, (erosion * 1.5), eqridgeModFreq) * eqridgeModMagn + 9.2) * 0.1);
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
	
	if (oceanType > 0.5)  
	{
		height = mix(height, height, vary) - _seaLevel;
	}

	if (cracksOctaves > 0)  
	{
		height = mix(height, height + 0.1, vary) - 0.1;
	}
	else   
	{
		height = mix(height, height + 0.05, vary) - 0.05; // 0.0015;
		// height = mix(height, height + 0.0001, vary);
	}
	
	// ocean basins
	if (oceanType != 0.0)
	{
		if (venusMagn < 0.05 || venusFreq < 0.5)
		{
			height = min(smoothstep(_seaLevel - 0.08, _seaLevel + 0.164, height), height); // reduce ocean depth near shore
			float h = smoothstep(_seaLevel - 1.03, _seaLevel + 0.18, height);
			height = mix(height, max(height, _seaLevel + 0.0595), h);
		}
		else
		{
			height = min(smoothstep(_seaLevel - 0.16, _seaLevel + 0.184, height), height); // reduce ocean depth near shore
			float h = smoothstep(_seaLevel - 1.23, _seaLevel + 0.38, height);
			height = mix(height, max(height, _seaLevel + 0.0595), h);
		}
	}
	if ((cracksOctaves == 0 || volcanoTemp >= 0.75) && lavaCoverage > 0 && oceanType == 0)   //((volcanoTemp > 0.7 || hillsMagn <=0.05) && lavaCoverage > 0 && oceanType == 0)
	{
		height = height - log(0.55 * lavaCoverage + 1);  // log(9 * lavaCoverage + 1)
		if (height < 0.0002)
		{
			height = 0;
		}
	}
	// Centri Super-Oceanic Fix
	if (oceanType > 0.5)  
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
		HeightBiomeMap = vec4(height - 0.06);
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

