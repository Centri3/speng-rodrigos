#include "tg_common.glh" 

#ifdef _FRAGMENT_ 

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraAli(vec3 point) {
	float minimumStripeTwist = 0.14;
	if(cloudsCoverage > 0.99) {
		minimumStripeTwist = 1.0;
	}

	float zones = cos(stripeZones * point.y * 0.45);
	float ang = zones * pow(max(abs(minimumStripeTwist), 1.0), 0.6);
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 0.5;
	float weight = 0.1;
	noiseH = 0.75;

	float offset = 0.0;

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
			coverage = mix(coverage, 0.9, (dist * 0.9));
		}
		weight *= smoothstep(-0.2, 0.0, point.y);   // surpress clouds on a night side
	} else
		twistedPoint = CycloneNoiseTerra(point, weight, coverage);

	// Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

	// Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 15);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

	// Compute the flow-like distortion
	noiseLacunarity = 6.6;

	if(sign(stripeFluct) != -1.0 || cloudsCoverage < 0.99) {
		noiseOctaves = cloudsOctaves;
	} else {
		noiseOctaves = 0.0;
	}

	vec3 distort = Fbm3D(twistedPoint * 2.8) * 3;
	vec3 p = (0.1 * twistedPoint) * cloudsFreq * 750;
	vec3 q = p + Fbm3D(p);
	vec3 r = p + Fbm3D(q);
	float f = Fbm(r) * 4 + coverage - 0.1;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + 0.5 * (cloudsCoverage * 0.1));

	// Compute turbulence features
	// noiseOctaves = cloudsOctaves;
	// float turbulence = (Fbm(point * 100.0 * cloudsFreq + Randomize) + 1.5);// * smoothstep(0.0, 0.05, global);

	return global;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraAli2(vec3 point) {
	float minimumStripeTwist = 0.14;
	if(cloudsCoverage > 0.99) {
		minimumStripeTwist = 1.0;
	}

	float zones = cos(stripeZones * point.y * 1.75);
	float ang = zones * pow(max(abs(stripeTwist), minimumStripeTwist), 0.6);
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage;
	float weight = 0.1;
	noiseH = 0.75;

	// Compute the cyclons
	if(tidalLock > 0.0) {
		vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
		float r = length(cycloneCenter - point * 0.75);
		float mag = 0;
		if(r < 1.0) {
			float dist = 1.0 - r;
			float fi = mix(log(r), dist * dist * dist, r);
			twistedPoint = Rotate(mag * fi, cycloneCenter, point);
			weight = saturate(r);
			weight = weight * weight;
			coverage = mix(coverage, 5.0, (dist * 0.9));
		}
	}

	// Compute turbulence
	twistedPoint = TurbulenceTerra(twistedPoint);

	// Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 15);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

	float octaves = 0.0;
	if(sign(stripeFluct) != -1.0 || cloudsCoverage < 0.99) {
		octaves = cloudsOctaves;
	}

	// Compute the flow-like distortion
	noiseLacunarity = 6.6 - cloudsFreq;
	noiseOctaves = cloudsOctaves;

	vec3 distort = Fbm3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 6.5;
	vec3 q = p + Fbm3D(p);
	vec3 r = p + Fbm3D(q);
	noiseOctaves = octaves;
	float f = Fbm(r) * 4 + coverage;
	noiseOctaves = cloudsOctaves;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + cloudsCoverage);

	return global;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraAli3(vec3 point) {
	float zones = cos(stripeZones * point.y * 0.35);
	float ang = zones * pow(max(abs(stripeTwist), 1.0), 0.6);
	vec3 twistedPoint = point;
	float coverage = 0.1;
	float weight = 1.0;
	noiseH = 0.75;

	// Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 15);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

	// Compute the flow-like distortion
	noiseLacunarity = 6.6;
	noiseOctaves = cloudsOctaves;

	vec3 distort = Fbm3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 10.0;
	vec3 q = p + Fbm3D(p);
	vec3 r = p + Fbm3D(q);
	float f = Fbm(r) * 4 + coverage;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + min(cloudsCoverage, 0.6));

	return saturate(global - (0.65 + min(cloudsCoverage, 0.0) * 0.6));
}

float HeightMapCloudsTerraAli4(vec3 point) {
	float zones = cos(stripeZones * point.y * 0.35);
	float ang = zones * pow(max(abs(stripeTwist), 1.0), 0.6);
	vec3 twistedPoint = point;
	float coverage = 0.1;
	float weight = 0.1;
	noiseH = 0.75;

	// Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 15);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

	// Compute the flow-like distortion
	noiseLacunarity = 6.6;
	noiseOctaves = cloudsOctaves;

	vec3 distort = Fbm3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 50.0;
	vec3 q = p + Fbm3D(p);
	vec3 r = p + Fbm3D(q);
	float f = Fbm(r) * 4 + coverage;
	float global = saturate(f) * weight * (Fbm(twistedPoint + distort) + min(cloudsCoverage, 0.6));

	return saturate(global - (0.65 + min(cloudsCoverage, 0.6) * 0.6));
}

float HeightMapCloudsTerraAli5(vec3 point) {
	float zones = cos(stripeZones * point.y * 0.35);
	float ang = zones * pow(max(abs(stripeTwist), 1.0), 0.6);
	vec3 twistedPoint = point;
	float coverage = cloudsCoverage * 0.1;
	float weight = 0.079;
	noiseH = 0.75;

	// Compute the Coriolis effect
	float sina = sin(ang);
	float cosa = cos(ang + 15);
	twistedPoint = vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y, sina * twistedPoint.x + cosa * twistedPoint.z);
	twistedPoint = twistedPoint * cloudsFreq + Randomize;

	// Compute the flow-like distortion
	noiseLacunarity = 6.6;
	noiseOctaves = 0.0;

	vec3 distort = FbmClouds3D(twistedPoint) * 2;

	vec3 p = twistedPoint * cloudsFreq * 5.0;
	vec3 q = p + FbmClouds3D(p);
	vec3 r = p + FbmClouds3D(q);
	float f = Fbm(r) * 4 + coverage;
	float global = saturate(f) * weight * (FbmClouds(twistedPoint + distort) + min(cloudsCoverage, 0.2));

	return saturate(pow(global, 1.2)) * 20.0;
}

//-----------------------------------------------------------------------------

void main() {
	vec3 point = GetSurfacePoint();
	float height = 0.0;
	if(cloudsLayer == 0) {
		height = 3.0 * HeightMapCloudsTerraAli(point) + HeightMapCloudsTerraAli2(point);
	} else if(sign(stripeFluct) != -1.0 || cloudsCoverage < 0.99) {
		height = HeightMapCloudsTerraAli3(point) + HeightMapCloudsTerraAli4(point) + HeightMapCloudsTerraAli5(point);
	}
	OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif