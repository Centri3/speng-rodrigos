#include "tg_common.glh" 

#ifdef _FRAGMENT_ 

//-----------------------------------------------------------------------------

// Smallest Clouds 

float HeightMapCloudsTerraGmail(vec3 point) {
	if (cloudsCoverage > 0.8) {
		return 0.0;
	}

	float zones = cos(point.y * stripeZones * 0.20);
	float ang = -zones * (stripeTwist + 0.03 / (stripeTwist + 0.08));
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 1.1;
	float weight = 1.0;
	noiseH = 0.75;

    // Compute the cyclons
	if(tidalLock > 0.0) {
		vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
		float r = length(cycloneCenter - point);
		float mag = -tidalLock * cycloneMagn;
		if(r < 1.0) {
			float dist = 1.0 - r;
			float fi = mix(log(r), dist * dist * dist, r);
			twistedPoint = Rotate(mag * fi, cycloneCenter, point);
			weight = saturate(r * 40.0 - 0.05);
			weight = weight * weight;
			coverage = mix(coverage, 1.0, dist);
		}
		weight *= smoothstep(-0.2, 0.0, point.y);   // surpress clouds on a night side
	} else
		twistedPoint = CycloneNoiseTerra(point, weight, coverage);

    // Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

    // Compute the flow-like distortion
	noiseLacunarity = 9.6;
	noiseOctaves = 11;

	vec3 distort = Fbm3D(twistedPoint * 9.8) * 3;

	vec3 p = (0.1 * twistedPoint) * cloudsFreq * 8;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	float f = FbmClouds(r) * 4 + coverage - 1.75;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + 0.5 * coverage);

    // Compute turb//ulence features
    //noiseOctaves = cloudsOctaves;
    //float turbulence = (Fbm(point * 900.0 * cloudsFreq + Randomize) + 1.5);// * smoothstep(3.0, 0.05, global);

	return global;
}
//-----------------------------------------------------------------------------

// Big Clouds (main clouds)

float HeightMapCloudsTerraGmail2(vec3 point) {
	if (cloudsCoverage > 0.8) {
		return 0.0;
	}

	float zones = cos(point.y * 1.75);
	float ang = zones * 2;
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 2.2;
	float weight = 0.09;
	noiseH = 0.7;

    // Compute the cyclons
	if(tidalLock > 0.0) {
		vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
		float r = length(cycloneCenter - point);
		float mag = -tidalLock * cycloneMagn;
		if(r < 1.0) {
			float dist = 1.0 - r;
			float fi = mix(log(r), dist * dist * dist, r);
			twistedPoint = Rotate(mag * fi, cycloneCenter, point);
			weight = saturate(r * 40.0 - 0.05);
			weight = weight * weight;
			coverage = mix(coverage, 1.0, dist);
		}
		weight *= smoothstep(-0.2, 0.0, point.y);   // surpress clouds on a night side
	} else
		twistedPoint = CycloneNoiseTerra(point, weight, coverage);

    // Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 11.7);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

    // Compute the flow-like distortion
	noiseLacunarity = 9.9;
	noiseOctaves = 13;
	vec3 distort = Fbm3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 6.5;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	twistedPoint.x *= 4.0;
	float f = FbmClouds(r * 0.2) * 4 + coverage - 1.045;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + coverage);

	return global;
}

//-----------------------------------------------------------------------------

// Medium Clouds
float HeightMapCloudsTerraGmail3(vec3 point) {
	if (cloudsCoverage > 0.8) {
		return 0.0;
	}

	float zones = cos(point.y * stripeZones * 0.20);
	float ang = -zones * (stripeTwist + 0.03 / (stripeTwist + 0.08));

	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 9.3;
	float weight = 0.03;
	noiseH = 0.75;

    // Compute the cyclons
	if(tidalLock > 0.0) {
		vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
		float r = length(cycloneCenter - point);
		float mag = -tidalLock * cycloneMagn;
		if(r < 1.0) {
			float dist = 1.0 - r;
			float fi = mix(log(r), dist * dist * dist, r);
			twistedPoint = Rotate(mag * fi, cycloneCenter, point);
			weight = saturate(r * 40.0 - 0.05);
			weight = weight * weight;
			coverage = mix(coverage, 1.0, dist);
		}
		weight *= smoothstep(-0.2, 0.0, point.y);   // surpress clouds on a night side
	} else
		twistedPoint = CycloneNoiseTerra(point, weight, coverage);

    // Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 12);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize * 2.0;

    // Compute the flow-like distortion
	noiseLacunarity = 8.6;
	noiseOctaves = 12;

	vec3 distort = Fbm3D(twistedPoint * 2.8) * 3;

	vec3 p = (0.1 * twistedPoint) * cloudsFreq * 74;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	twistedPoint.x *= 4.0;
	float f = FbmClouds(r) * 4 + coverage - 1.4;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + 0.9 * coverage);

    // Compute turb//ulence features
    //noiseOctaves = cloudsOctaves;
    //float turbulence = (Fbm(point * 400.0 * cloudsFreq + Randomize) + 1.5);// * smoothstep(3.0, 0.05, global);

	return global;
}
//-----------------------------------------------------------------------------

// Thunderstorms
float HeightMapCloudsTerraGmail4(vec3 point) {
	if (cloudsCoverage > 0.8) {
		return 0.0;
	}

	float zones = cos(point.y * stripeZones * 0.000);
	float ang = -zones * (stripeTwist + 0.000 / (stripeTwist + 0.00));

	vec3 twistedPoint = point;
	float coverage = cloudsCoverage;
	float weight = 1.9;
	noiseH = 0.75;

    // Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

    // Compute the flow-like distortion
	noiseLacunarity = 0.3;
	noiseOctaves = 3;

	vec3 distort = Fbm3D(twistedPoint * 16.8) * 1;

	vec3 p = (0.1 * twistedPoint) * cloudsFreq * 100;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	float f = FbmClouds(r) * 6.3 + coverage - 3.3;
	float global = 0.1 * saturate(f) * weight;

    // Compute turb//ulence features
    //noiseOctaves = 0.1;
    //float turbulence = (Fbm(point * 41.0 * cloudsFreq + Randomize) + 0.3);// * smoothstep(2.0, 0.35, global);

	return global;
}
//-----------------------------------------------------------------------------

// Fog clouds

float HeightMapCloudsTerraGmail5(vec3 point) {
	if (cloudsCoverage > 0.8) {
		return 0.0;
	}

	float zones = cos(point.y * 0.65);
	float ang = zones * 2;
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 3.1;
	float weight = 0.01;
	noiseH = 0.1;

    // Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

    // Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

    // Compute the flow-like distortion
	noiseLacunarity = 20.9;
	noiseOctaves = 13;
	vec3 distort = Fbm3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 1.6;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	float f = FbmClouds(r) * 4 + coverage - 0.02;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + coverage);

	return global;
}


vec3    TurbulenceVenus(vec3 point)
{
    const float scale = 0.7;

    vec3  twistedPoint = point;
    vec3  cellCenter = vec3(0.0);
    vec2  cell;
    float r, fi, rnd, dist, dist2, dir;
    float strength = 500.5;
    float freq = 20.0 * scale;
    float size = 4.0 * scale;
    float dens = 10.3;

    for (int i = 0; i<2; i++)
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
            twistedPoint = Rotate(dir * 15.0 * sign(cellCenter.y + 0.001) * fi, cellCenter.xyz, point);
        }

        freq = min(freq * 8.0, 1600.0);
        size = min(size * 1.2, 30.0);
        strength = strength * 1.5;
        point = twistedPoint;
    }

	twistedPoint.xz *= 2.0;
    return twistedPoint * 2.0;
}

float HeightMapCloudsVenus(vec3 point) {
	if (cloudsCoverage < 0.8) {
		return 0.0;
	}

    vec3  twistedPoint = point;

    // Compute zones
    float zones = Noise(vec3(0.0, twistedPoint.y * stripeZones * 0.6, 0.35)) * 0.8 + 0.20;
    float offset = 0.0;

    // Compute turbulence
    twistedPoint = TurbulenceVenus(twistedPoint);

    // Compute stripes
    noiseOctaves = cloudsOctaves;
    float turbulence = Fbm(twistedPoint * 0.8);
    twistedPoint = twistedPoint * (0.33 * cloudsFreq) + Randomize;
	twistedPoint.x *= twistedPoint.y * twistedPoint.y;
    twistedPoint.y *= 15.0 + turbulence;
    float height = 0.2 * (Fbm(twistedPoint) * 1.8);

    return zones + height + offset;
}


void main() {
	vec3 point = GetSurfacePoint();
	float height = 3 * (HeightMapCloudsTerraGmail(point) + HeightMapCloudsTerraGmail2(point) + HeightMapCloudsTerraGmail3(point) + HeightMapCloudsTerraGmail4(point) + HeightMapCloudsTerraGmail5(point) + HeightMapCloudsVenus(point));
	OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif