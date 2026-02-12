#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraR(vec3 point) {
  float zones = cos(point.y * stripeZones * 0.25);
  float ang =
      zones * (stripeTwist + 0.03 / (stripeTwist + 0.1)) * -stripeTwist / 3;
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage;
  float weight = 0.3;
  noiseH = 0.75;

  // Compute the cyclons
  if (tidalLock > 0.0) {
    vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
    float r = length(cycloneCenter - point);
    float mag = -tidalLock * cycloneMagn;
    if (r < 1.0) {
      float dist = 1.0 - r;
      float fi = mix(log(r), dist * dist * dist, r);
      twistedPoint = Rotate(mag * fi, cycloneCenter, point);
      weight = saturate(r * 40.0 - 0.05);
      weight = weight * weight;
      coverage = mix(coverage, 1.0, dist);
    }
    weight *= smoothstep(-0.2, 0.0, point.y); // surpress clouds on a night side
  } else
    twistedPoint = CycloneNoiseTerra(point, weight, coverage);

  // Compute turbulence
  twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 2.2;
  noiseOctaves = 12;

  vec3 distort = Fbm3D(twistedPoint * 2.8) * 1.5;

  vec3 p = (0.01 * twistedPoint) * cloudsFreq * 400.37;
  vec3 q = p + FbmClouds3D(p);
  vec3 r = p + FbmClouds3D(q);
  float f = FbmClouds(r) * 2 + coverage - 0.1;
  float global = saturate(f) * weight *
                 (Fbm(twistedPoint + distort) + 0.7 * cloudsCoverage);

  // Compute turbulence features
  // noiseOctaves = cloudsOctaves;
  // float turbulence = (Fbm(point * 100.0 * cloudsFreq + Randomize) + 1.5);// *
  // smoothstep(0.0, 0.05, global);

  return global;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraTPE(vec3 point) {
  float zones = -cos(point.y * 1.75 * (pow(abs(stripeTwist + 0.2), 0.3) + 0.2) *
                     stripeZones * 0.3);
  float ang = zones * 2;
  // -0.2 because of the + 0.2
  if(stripeTwist < -0.2) {
    ang *= -1.0;
  }
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage * 0.1;
  float weight = 0.3;
  noiseH = 0.75;
  ;
  float offset = 0.0;

  // Compute the cyclons
  if (tidalLock > 0.0) {
    vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
    float r = length(cycloneCenter - point);
    float mag = -tidalLock * cycloneMagn;
    if (r < 5.0) {
      float dist = 1.0 - r;
      float fi = mix(log(r), dist * dist * dist, r);
      twistedPoint = Rotate(mag * fi, cycloneCenter, point);
      weight = saturate(r * 40.0 - 0.05);
      weight = weight * weight;
      coverage = mix(coverage, 0.9, (dist * 0.9));
    }
    weight *= smoothstep(-0.2, 0.0, point.y); // surpress clouds on a night side
  } else
    twistedPoint = CycloneNoiseTerra(point, weight, coverage);

  // Compute turbulence
  // twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 6.6;
  noiseOctaves = 12;
  vec3 distort = Fbm3D(twistedPoint * 2.8) * 3;
  vec3 p = (0.1 * twistedPoint) * cloudsFreq * 750;
  vec3 q = p + FbmClouds3D(p);
  vec3 r = p + FbmClouds3D(q);
  float f = FbmClouds(r) * 4 + coverage - 0.1;
  if (cloudsCoverage == 1.0) {
    f = coverage - 0.1;
  }
  float global = saturate(f) * weight *
                 (Fbm(twistedPoint + distort) + 0.5 * (cloudsCoverage * 0.1));

  // Compute turbulence features
  // noiseOctaves = cloudsOctaves;
  // float turbulence = (Fbm(point * 100.0 * cloudsFreq + Randomize) + 1.5);// *
  // smoothstep(0.0, 0.05, global);

  return global;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraTPE2(vec3 point) {
  float zones =
      -cos(point.y * 1.75 * pow(abs(stripeTwist + 0.2), 0.3) * stripeZones * 0.3);
  float ang = zones * 2;
  // -0.2 because of the + 0.2
  if(stripeTwist < -0.2) {
    ang *= -1.0;
  }
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage;
  float weight = 0.3;
  if (cloudsOctaves == 0) {
    noiseH = 1.0;
  } else {
    noiseH = 0.75;
  }

  // Compute the cyclons
  if (tidalLock > 0.0) {
    vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
    float r = length(cycloneCenter - point * 0.75);
    float mag = 0;
    if (r < 5.0) {
      float dist = 1.0 - r;
      float fi = mix(log(r), dist * dist * dist, r);
      twistedPoint = Rotate(mag * fi, cycloneCenter, point);
      weight = saturate(r);
      weight = weight * weight;
      coverage = mix(coverage, 5.0, (dist * 0.9));
    }
  }

  // Compute turbulence
  // twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 9.9;
  noiseOctaves = 12;
  vec3 distort = Fbm3D(twistedPoint) * 2;
  vec3 p = twistedPoint * cloudsFreq * 6.5;
  vec3 q = p + FbmClouds3D(p);
  vec3 r = p + FbmClouds3D(q);
  float f = FbmClouds(r) * 4 + coverage;
  if (cloudsCoverage == 1.0) {
    f = coverage - 0.1;
  }
  float global =
      saturate(f) * weight * (Fbm(twistedPoint + distort) + cloudsCoverage);

  return global;
}

float HeightMapCloudsTerraA(vec3 point) {
  float zones = -cos(point.y * 1.75 * pow(abs(stripeTwist + 0.3), 0.3) *
                     stripeZones * 0.3);
  float ang = zones * 2;
  // -0.3 because of the + 0.3
  if(stripeTwist < -0.3) {
    ang *= -1.0;
  }
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage * 0.6;
  if (cloudsOctaves == 0) {
    coverage = 0.0;
  }
  float weight = 0.8;
  noiseH = 0.75;

  // Compute turbulence
  // twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 9.9;
  noiseOctaves = 12;
  vec3 distort = Fbm3D(twistedPoint) * 1;
  vec3 p = twistedPoint * cloudsFreq * 6.5;
  noiseOctaves = 0;
  vec3 q = p + Fbm3D(p);
  vec3 r = p + Fbm3D(q);
  float f = Fbm(r) * 4 + coverage;
  noiseOctaves = 12;
  if (cloudsCoverage == 1.0) {
    f = coverage - 0.1;
  }
  float _distort = Fbm(twistedPoint + distort);
  noiseH = 1.0;
  float global = saturate(f) * weight * (_distort + cloudsCoverage * 0.1);

  return global;
}

//-----------------------------------------------------------------------------

// Leaving Kham's code in for those who want to experiment.

float HeightMapCloudsTerraKham1(vec3 point) {
  float zones = cos(point.y * stripeZones * 0.45);
  float ang = -zones * (stripeTwist + 0.03 / (stripeTwist + 0.1));
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage;
  float weight = 0.3;
  noiseH = 0.75;

  // Compute the cyclons
  if (tidalLock > 0.0) {
    vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
    float r = length(cycloneCenter - point);
    float mag = tidalLock * cycloneMagn * 0.25;
    if (r < 1.0) {
      float dist = 1.0 - r;
      float fi = mix(log(r), dist * dist * dist, r);
      twistedPoint = Rotate(mag * fi, cycloneCenter, point);
      weight = saturate(r * 40.0);
      weight = weight * weight;
      coverage = mix(coverage, 5.0, dist);
    }
  } else
    twistedPoint = CycloneNoiseTerra(point, weight, coverage);

  // Compute turbulence
  twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 6.6;
  noiseOctaves = 12;

  vec3 distort = Fbm3D(twistedPoint * 2.8) * 3;

  vec3 p = (0.1 * twistedPoint) * cloudsFreq * 750;
  vec3 q = p + FbmClouds3D(p);
  vec3 r = p + FbmClouds3D(q);
  float f = FbmClouds(r) * 4 + coverage - 0.1;
  float global = saturate(f) * weight *
                 (Fbm(twistedPoint + distort) + 0.5 * cloudsCoverage);

  // Compute turb//ulence features
  // noiseOctaves = cloudsOctaves;
  // float turbulence = (Fbm(point * 100.0 * cloudsFreq + Randomize) + 1.5);// *
  // smoothstep(0.0, 0.05, global);

  return global;
}

//-----------------------------------------------------------------------------

float HeightMapCloudsTerraKham2(vec3 point) {
  float zones = cos(point.y * 1.75);
  float ang = zones * 2;
  vec3 twistedPoint = point;
  float coverage = cloudsCoverage * 3;
  float weight = 0.3;
  noiseH = 1;

  // Compute the cyclons
  if (tidalLock > 0.0) {
    vec3 cycloneCenter = vec3(0.0, 1.0, 0.0);
    float r = length(cycloneCenter - point * 0.75);
    float mag = 0;
    if (r < 1.0) {
      float dist = 1.0 - r;
      float fi = mix(log(r), dist * dist * dist, r);
      twistedPoint = Rotate(mag * fi, cycloneCenter, point);
      weight = saturate(r);
      weight = weight * weight;
      coverage = mix(coverage, 5.0, dist);
    }
  }

  // Compute turbulence
  twistedPoint = TurbulenceTerra(twistedPoint);

  // Compute the Coriolis effect
  float sina = sin(ang);
  float cosa = cos(ang + 15);
  twistedPoint =
      vec3(cosa * twistedPoint.x - sina * twistedPoint.z, twistedPoint.y,
           sina * twistedPoint.x + cosa * twistedPoint.z);
  twistedPoint = twistedPoint * cloudsFreq + Randomize;

  // Compute the flow-like distortion
  noiseLacunarity = 9.9;
  noiseOctaves = 12;
  vec3 distort = Fbm3D(twistedPoint) * 2;

  vec3 p = twistedPoint * cloudsFreq * 6.5;
  vec3 q = p + FbmClouds3D(p);
  vec3 r = p + FbmClouds3D(q);
  float f = FbmClouds(r) * 4 + coverage;
  float global =
      saturate(f) * weight * (Fbm(twistedPoint + distort) + cloudsCoverage);

  return global;
}

//-----------------------------------------------------------------------------

void main() {

  vec3 point = GetSurfacePoint();
  float height;
  if (cloudsCoverage == 1.0) {
    height = 3.0 * HeightMapCloudsTerraAli(point) +
             HeightMapCloudsTerraAli2(point);
  } else {
    height = 2.0 *
             max(HeightMapCloudsTerraTPE(point) +
                     HeightMapCloudsTerraTPE2(point),
                 pow(HeightMapCloudsTerraA(point), 2.0) * 50.0);
  }
  height *= unwrap_or(stripeFluct, 1.0) * 0.33333;
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif
