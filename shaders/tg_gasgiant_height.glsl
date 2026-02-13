#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

vec3 TurbulenceGasGiantGmail(vec3 point) {
	const float scale = 1.7;

	vec3 twistedPoint = point;
	vec3 cellCenter = vec3(0.0);
	vec2 cell;
	float r, fi, rnd, dist, dist2, dir;
	float strength = 5.5;
	float freq = 900 * scale;
	float size = 14.0 * scale;
	float dens = 0.8;

	for(int i = 0; i < 5; i++) {
		vec2 cell = inverseSF(point, freq, cellCenter);
		rnd = hash1(cell.x);
		r = size * cell.y;

		if((rnd < dens) && (r < 1.0)) {
			dir = sign(0.5 * dens - rnd);
			dist = saturate(1.0 - r);
			dist2 = saturate(0.5 - r);
			fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.25);
			twistedPoint = Rotate(dir * stripeTwist * sign(cellCenter.y) * fi, cellCenter.xyz, point);
		}

		freq = min(freq * 2.0, 1600.0);
		size = min(size * 1.2, 30.0);
		strength = strength * 1.5;
		point = twistedPoint;
	}

	return twistedPoint;
}

//-----------------------------------------------------------------------------

vec3 CycloneNoiseGasGiantGmail(vec3 point, inout float offset) {
	vec3 rotVec = normalize(Randomize);
	vec3 twistedPoint = point;
	vec3 cellCenter = vec3(0.0);
	vec2 cell;
	float r, fi, rnd, dist, dist2, dir;
	float offs = 0.5 / (cloudsLayer + 1.0);
	float squeeze = 1.9;
	float strength = 10.0;
	float freq = cycloneFreq * 30.0;
	float dens = cycloneDensity * 0.02;
	float size = 1.3 * pow(cloudsLayer + 1.0, 5.0);

	for(int i = 0; i < cycloneOctaves; i++) {
		cell = inverseSF(vec3(point.x, point.y * squeeze, point.z), freq + cloudsLayer, cellCenter);
		rnd = hash1(cell.x);
		r = size * cell.y;

		if((rnd < dens) && (r < 1.0)) {
			dir = sign(0.7 * dens - rnd);
			dist = saturate(1.0 - r);
			dist2 = saturate(0.3 - r);
			fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.5);
			twistedPoint = Rotate(cycloneMagn * dir * sign(cellCenter.y + 0.001) * fi, cellCenter.xyz, point);
			offset += offs * fi * dir;
		}

		freq = min(freq * 2.0, 6400.0);
		dens = min(dens * 3.5, 0.3);
		size = min(size * 1.5, 15.0);
		offs = offs * 0.85;
		squeeze = max(squeeze - 0.3, 1.0);
		strength = max(strength * 1.3, 0.5);
		point = twistedPoint;
	}

	return twistedPoint;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail(vec3 point, bool cyclones, float _stripeZones) {
	vec3 twistedPoint = point;

	// Compute zones
	float zones = Noise(vec3(0.0, twistedPoint.y * _stripeZones * 0.6 + cloudsLayer, 0.35)) * 0.8 + 0.20;
	float offset = 0.0;

	// Compute cyclons
	if(cycloneOctaves > 0.0 && cyclones)
		twistedPoint = CycloneNoiseGasGiantGmail(twistedPoint, offset);

	// Compute turbulence
	twistedPoint = TurbulenceGasGiantGmail(twistedPoint);

	// Compute stripes
	noiseOctaves = cloudsOctaves;
	float turbulence = Fbm(twistedPoint * 0.03);
	twistedPoint = twistedPoint * (0.43 * cloudsFreq) + Randomize + cloudsLayer;
	twistedPoint.y *= 9.0 + turbulence;
	float height = unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.8 + 0.1);

	return zones + height + offset;
}
//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail2(vec3 point) {
	vec3 twistedPoint = point;

	// Compute zones
	float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.5 + cloudsLayer, 0.3)) * 0.5 + 0.10;
	float offset = 0.1;

	// Compute cyclons
	if(cycloneOctaves > 0.0)
		twistedPoint = CycloneNoiseGasGiantGmail(twistedPoint, offset);

	// Compute turbulence
	twistedPoint = TurbulenceGasGiantGmail(twistedPoint);

	// Compute stripes
	noiseOctaves = cloudsOctaves;
	float turbulence = Fbm(twistedPoint * 0.01);
	twistedPoint = twistedPoint * (0.32 * cloudsFreq) + Randomize + cloudsLayer;
	twistedPoint.y *= 30.0 + turbulence;
	float height = unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.5 + 0.4);

	return zones + height + offset;
}
//-----------------------------------------------------------------------------

float HeightMapCloudsGasGiantGmail3(vec3 point) {
	vec3 twistedPoint = point;

	// Compute zones
	float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.9 + cloudsLayer, 0.3)) * 0.4 + 0.08865;
	float offset = 0.0;

	// Compute cyclons
	if(cycloneOctaves > 0.0)
		twistedPoint = CycloneNoiseGasGiantGmail(twistedPoint, offset);

	// Compute turbulence
	twistedPoint = TurbulenceGasGiantGmail(twistedPoint);

	// Compute stripes
	noiseOctaves = cloudsOctaves;
	float turbulence = Fbm(twistedPoint * 8.86);
	twistedPoint = twistedPoint * (1.12 * cloudsFreq) + Randomize + cloudsLayer;
	twistedPoint.y *= 80.0 + turbulence;
	float height = unwrap_or(stripeFluct, 0.0) * 0.5 * (Fbm(twistedPoint) * 0.25 + 0.4);

	return zones + height + offset;
}

//-----------------------------------------------------------------------------

vec3	TurbulenceGasGiantTPE(vec3 point)
{
	const float scale = 0.7;

	vec3  twistedPoint = point;
	vec3  cellCenter;
	vec2  cell;
	float r, fi, rnd, dist, dist2, dir;
	float strength = 5.5;
	float freq = 800 * scale;
	float size = 15.0 * scale;
	float dens = 0.8;

	for (int i = 0; i<5; i++)
	{
		vec2  cell = inverseSF(point, freq, cellCenter);
		rnd = hash1(cell.x);
		r = size * cell.y;

		if ((rnd < dens) && (r < 1.0))
		{
			dir = sign(0.5 * dens - rnd);
			dist = saturate(1.0 - r);
			dist2 = saturate(0.5 - r);
			fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.25);
			twistedPoint = Rotate(dir * stripeTwist * sign(cellCenter.y) * fi, cellCenter.xyz, point);
		}

		freq = min(freq * 2.0, 1600.0);
		size = min(size * 1.2, 30.0);
		strength = strength * 1.5;
		point = twistedPoint;
	}

	return twistedPoint;
}

//-----------------------------------------------------------------------------

vec3	CycloneNoiseGasGiantTPE(vec3 point, inout float offset)
{
	vec3  rotVec = normalize(Randomize);
	vec3  twistedPoint = point;
	vec3  cellCenter;
	vec2  cell;
	float r, fi, rnd, dist, dist2, dir;
	float offs = 0.6;
	float squeeze = 1.7;
	float strength = 2.5;
	float freq = cycloneFreq * 50.0;
	float dens = cycloneDensity * 0.02;
	float size = 6.0;

	for (int i = 0; i<cycloneOctaves; i++)
	{
		cell = inverseSF(vec3(point.x, point.y * squeeze, point.z), freq, cellCenter);
		rnd = hash1(cell.x);
		r = size * cell.y;

		if ((rnd < dens) && (r < 1.0))
		{
			dir = sign(0.7 * dens - rnd);
			dist = saturate(1.0 - r);
			dist2 = saturate(0.5 - r);
			fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.5);
			twistedPoint = Rotate(cycloneMagn * dir * sign(cellCenter.y + 0.001) * fi, cellCenter.xyz, point);
			offset += offs * fi * dir;
		}

		freq = min(freq * 2.0, 6400.0);
		dens = min(dens * 3.5, 0.3);
		size = min(size * 1.5, 15.0);
		offs = offs * 0.85;
		squeeze = max(squeeze - 0.3, 1.0);
		strength = max(strength * 1.3, 0.5);
		point = twistedPoint;
	}

	return twistedPoint;
}

//-----------------------------------------------------------------------------

float   HeightMapCloudsGasGiantTPE(vec3 point)
{
	vec3  twistedPoint = point;

float coverage = cloudsCoverage;

	// Compute zones
	float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.5, 0.0)) * 0.6 + 0.25;
	float offset = 0.0;

	// Compute cyclons
	if (cycloneOctaves > 0.0)
		twistedPoint = CycloneNoiseGasGiantGmail(twistedPoint, offset);

	// Compute turbulence
	twistedPoint = TurbulenceGasGiantTPE(twistedPoint);

	// Compute stripes
	noiseOctaves = cloudsOctaves;
	float turbulence = Fbm(twistedPoint * 2.2);
	twistedPoint = twistedPoint * (0.05 * cloudsFreq) + Randomize;
	twistedPoint.y *= 100.0 + turbulence;
	float height = unwrap_or(stripeFluct * (Fbm(twistedPoint) * 0.7 + 0.5), pow(abs(point.y), stripeZones) * (stripeFluct * 0.55));

	return zones+ height + offset;
}

//-----------------------------------------------------------------------------

vec4	CycloneNoiseRM974(vec3 point)
{
	vec3  twistedPoint = point;
	vec3  p = point;
	vec3  v;
	vec4  cell;
	float radius, dist, dist2, fi;
	float freq   = cycloneFreq;
	float dens   = 1.0 / cycloneDensity;
	float offset = 0.0;
	float offs   = 1.0;

	for (int i=0; i<cycloneOctaves; i++)
	{
		cell = Cell3NoiseVec(p * freq, 0.6);
		v = cell.xyz - p;
		v.y *= 1.6;
		radius = length(v) * dens;

		if (radius < 1.0)
		{
			dist  = 1.0 - radius;
			dist2 = 0.5 - radius;
			fi	= pow(dist, 2.5) * (exp(-60.0 * dist2 * dist2) + 0.5);
			twistedPoint = Rotate(cycloneMagn * sign(cell.y) * fi, cell.xyz, point);
			offset += offs * fi;
		}

		freq *= 4.3;
		dens *= 2.9;
		offs *= 0.2;
		point = twistedPoint;
	}

	return vec4(twistedPoint, offset);
}

//-----------------------------------------------------------------------------

float   HeightMapCloudsGasGiantRM974(vec3 point)
{
	vec3  twistedPoint = point;

	if (stripeFluct == 0.0)
	{
		//noiseOctaves = 10.0;
		//twistedPoint *= vec3(1.0) + 0.337 * Fbm3D(point * 0.193);
		noiseOctaves = 10.0;
		twistedPoint *= vec3(1.0) + 0.337 * Fbm3D(point * 0.193);
	}

	float offset = 0.0;
	float zone = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.5, 0.0)) * 2.0;
	noiseOctaves = 10.0;
	// noiseH	   = 0.4;

	// Compute cyclons
	if (cycloneOctaves > 0.0)
	{
		vec4 cyclone = CycloneNoiseRM974(twistedPoint);
		twistedPoint = cyclone.xyz;
		offset = cyclone.w;
	}

	// Compute stripes
	float turbulence, height;
	if (stripeFluct == 0.0)
	{
		float ang = zone * stripeTwist;
		float sina = sin(ang);
		float cosa = cos(ang);
		twistedPoint = vec3(cosa*twistedPoint.x-sina*twistedPoint.z, twistedPoint.y, sina*twistedPoint.x+cosa*twistedPoint.z);
		twistedPoint = twistedPoint * mainFreq + Randomize;
		turbulence = Fbm(colorDistFreq * twistedPoint);
		twistedPoint *= 500.0 + 5.0 * turbulence;
		height = (Fbm(twistedPoint) + 0.7) * 0.7;
	}
	else
	{
		turbulence = Fbm(twistedPoint * 0.2);
		twistedPoint = twistedPoint * mainFreq + Randomize;
		twistedPoint.y *= 100.0 + turbulence * stripeTwist;
		height = (Fbm(twistedPoint) + 0.7) * 0.7;
	}

	height = 0.5*(0.5+0.6*zone) + colorDistMagn * height + offset;

	return height;

	//height = 0.5*(0.5+0.6*zone) + colorDistMagn * height + offset;
	//float alpha = abs(min(height, 1.0) - cloudsLayer) * cloudsNLayers;
	//return height * alpha;
}

//-----------------------------------------------------------------------------

void main()
{
	if (cloudsLayer != 0.0)
	{
		vec3 point = GetSurfacePoint();
		float height;
		if (volcanoActivity != 0.0) // volcanoActivity != 0.0 && colorDistFreq < 200000000
		{
			height = 3.0 * stripeFluct * HeightMapCloudsTerraAli(point) + HeightMapCloudsTerraAli2(point);
		}
		else
		{
			height = 0.95 * (HeightMapCloudsGasGiantGmail(point, true, stripeZones) + 0.5 * HeightMapCloudsGasGiantGmail2(point) + 0.5 * HeightMapCloudsGasGiantGmail3(point));
		}
		OutColor = vec4(height);
	}
	else
	{
		vec3  point = GetSurfacePoint();
		// float height = HeightMapCloudsGasGiant(point);
		float height = HeightMapCloudsGasGiantTPE(point);
		OutColor = vec4(height);
	}
}

//-----------------------------------------------------------------------------

#endif
