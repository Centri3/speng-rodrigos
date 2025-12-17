#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

// Calculation Function // Fixed hsl2rgb
vec3 hsl2rgb2(vec3 hsl) {
  float h = hsl.x;
  float s = hsl.y;
  float l = hsl.z;

  float c = (1.0 - abs(2.0 * l - 1.0)) * s; // Chroma
  float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
  float m = l - 0.5 * c;

  vec3 rgb;

  if (0.0 <= h && h < 1.0 / 6.0) {
    rgb = vec3(c, x, 0.0);
  } else if (1.0 / 6.0 <= h && h < 2.0 / 6.0) {
    rgb = vec3(x, c, 0.0);
  } else if (2.0 / 6.0 <= h && h < 3.0 / 6.0) {
    rgb = vec3(0.0, c, x);
  } else if (3.0 / 6.0 <= h && h < 4.0 / 6.0) {
    rgb = vec3(0.0, x, c);
  } else if (4.0 / 6.0 <= h && h < 5.0 / 6.0) {
    rgb = vec3(x, 0.0, c);
  } else if (5.0 / 6.0 <= h && h < 1.0) {
    rgb = vec3(c, 0.0, x);
  } else {
    rgb = vec3(1.0, 0.0, 0.0); // Just in case of rounding errors
  }

  return rgb + vec3(m);
}

//-----------------------------------------------------------------------------

// Calculation Function // Cell Noise Center
float CenteredSlope(vec3 point, vec3 center) {
  float pi = atan(1.0) * 4;
  float height = 0.0;
  float slope = 0.0;
  vec3 normal;
  GetSurfaceHeightAndSlopeAndNormal(height, slope, normal);
  float slopeNS = atan(normal.x, normal.z);
  float slopeEW = atan(normal.y, normal.z);

  float deltax = center.x - point.x; // cell.x - point.x;
  float deltay = center.y - point.y; // cell.y - point.y;
  float adjust = 0;
  if (deltay >= 0) {
    adjust = pi;
  }
  float slopeAngle = pi / 4;
  if (deltay != 0) {
    slopeAngle = atan(deltax / deltay) + adjust;
  }
  float slopeFromCenter = slopeNS * cos(slopeAngle) + slopeEW * sin(slopeAngle);
  return (1 - slopeFromCenter);
}

//-----------------------------------------------------------------------------

// Noise Function // Cell Noise Center
vec4 Cell2NoiseCenter(vec3 p) {
  vec3 cell = floor(p);
  vec3 offs = p - cell - vec3(0.5);
  vec3 pos;
  vec3 rnd;
  vec3 center;
  vec3 d;
  float dist;
  float distMin = 1.0e38;
  for (d.z = -1.0; d.z < 1.0; d.z += 1.0) {
    for (d.y = -1.0; d.y < 1.0; d.y += 1.0) {
      for (d.x = -1.0; d.x < 1.0; d.x += 1.0) {
        rnd = NoiseNearestUVec4((cell + d) / NOISE_TEX_3D_SIZE).xyz + d;
        pos = rnd - offs;
        dist = dot(pos, pos);

        if (dist < distMin) {
          distMin = dist;
          center = rnd;
        }
      }
    }
  }
  return vec4(center, sqrt(distMin));
}

//-----------------------------------------------------------------------------

// Function // Polar Slope Ice
float SlopedIceCaps(float slope, float latitude) {
  // This uses `latitude + 0.5` to increase the amount of ice caps on a planet
  return saturate(slope - smoothstep(latIceCaps, 1.0, latitude + 0.5) * 0.03) +
         smoothstep(saturate(latIceCaps - 0.3), 1.0, latitude + 0.5) * 0.4;
}

//-----------------------------------------------------------------------------

// Function // Europa Crack Formula
float EuropaCrackColorFunc(float lastLand, float lastlastLand, float height,
                           float r, vec3 p) {
  p.x += 0.05 * r;
  float inner = smoothstep(0.0, 0.5, r);
  float outer = smoothstep(0.5, 1.0, r);
  float cracks = height * ((0.7 + 0.3 * Noise(p * 625.7)) * (1.0 - inner) +
                           inner * (1.0 - outer * 0.1));
  float land = mix(lastLand, lastlastLand, r);
  return mix(cracks, land, outer);
}

//-----------------------------------------------------------------------------

// Function // Europa Cracks Noise
// 8-10-2024 by Sp_ce // Stretch cell x, doubled octaves
// 26-10-2024 by Sp_ce // Quadrupled octaves from doubled
// 26-10-2024 by Sp_ce // Reverted quadrupling back to doubling
float EuropaCrackNoise(vec3 point, float europaCracksOctaves, out float mask) {
  point = (point + Randomize) * cracksFreq;
  point.x *= 0.3;

  float newLand = 0.0;
  float lastLand = 0.0;
  float lastlastLand = 0.0;
  vec2 cell;
  float r;
  float ampl = 0.4 * cracksMagn;
  mask = 1.0;

  // Rim shape and height distortion
  noiseH = 0.5;
  noiseLacunarity = 2.218281828459;
  noiseOffset = 0.8;
  noiseOctaves = 5.0;

  for (int i = 0; i < europaCracksOctaves; i++) {
    for (int j = 0; j < 2; j++) {
      cell = Cell2Noise2(point + 0.02 * Fbm3D(1.8 * point));
      r = smoothstep(0.0, 1.0, 250.0 * abs(cell.y - cell.x));
      lastlastLand = lastLand;
      lastLand = newLand;
      newLand = CrackHeightFunc(lastlastLand, lastLand, ampl, r, point);
      point += Randomize;
      mask *= smoothstep(0.6, 1.0, r);
    }
    point = point * 1.2 + Randomize;
    ampl *= 0.8333;
  }

  return newLand;
}

//-----------------------------------------------------------------------------

// Function // Europa Cracks Color Noise
// 8-10-2024 by Sp_ce // Stretch cell x, doubled octaves
// 26-10-2024 by Sp_ce // Quadrupled octaves from doubled
// 26-10-2024 by Sp_ce // Reverted quadrupling back to doubling
float EuropaCrackColorNoise(vec3 point, float europaCracksOctaves,
                            out float mask) {
  point = (point + Randomize) * cracksFreq;
  point.x *= 0.3;

  float newLand = 0.0;
  float lastLand = 0.0;
  float lastlastLand = 0.0;
  vec2 cell;
  float r;

  // Rim height and shape distortion
  noiseH = 0.5;
  noiseLacunarity = 2.218281828459;
  noiseOffset = 0.8;
  noiseOctaves = 5.0;
  mask = 1.0;

  for (int i = 0; i < europaCracksOctaves; i++) {
    for (int j = 0; j < 2; j++) {
      cell = Cell2Noise2(point + 0.02 * Fbm3D(1.8 * point));
      r = smoothstep(0.0, 1.0, 250.0 * abs(cell.y - cell.x));
      lastlastLand = lastLand;
      lastLand = newLand;
      newLand = EuropaCrackColorFunc(lastlastLand, lastLand, 1.0, r, point);
      point += Randomize;
      mask *= smoothstep(0.6, 1.0, r);
    }
    point = point * 1.2 + Randomize;
  }

  return pow(saturate(1.0 - newLand), 2.0);
}

//-----------------------------------------------------------------------------

// Function // Tholin Patch Formula
// 19-10-2024 by Sp_ce // Reworked color slopes
// 20-10-2024 by Sp_ce // Added height mod
float TholinPatchColorFunc(float r, float slopeFromCenter, float height) {
  float t;
  float central = 0.1;
  float rim = 0.3; // 0.4;
  float outer = 1.0 - central - rim;

  if (r < radInner) {
    t = central * (r / radInner);
    return t - 0.5 * (0.5 - height);
    // return t;
    // return 1.0;
  } else if (r < radRim) {
    t = rim * ((r - radInner) / (radRim - radInner)) + central;
    return t - 0.5 * (0.5 - height);
    // return t;
    // return 1.0;
  } else if (r < radOuter) {
    t = outer * ((r - radRim) / (radOuter - radRim)) + central + rim;
    float heightFade = (r - radRim) / (radOuter - radRim);
    return (1 - heightFade) * (t - 0.5 * (0.5 - height)) + heightFade * t;
    // return t;
    // return 1.0;
  } else {
    return 1.0;
  }
}

//-----------------------------------------------------------------------------

// Function // Tholin Patch Noise
// 19-10-2024 by Sp_ce // Standardized freq and density
// 20-10-2024 by Sp_ce // Added height mod
float TholinPatchNoise(vec3 point, float height) {
  float patchFreq = 1.0;           // mareFreq;
  float patchDensity = sqrt(0.05); // mareSqrtDensity;
  point = (point * patchFreq + Randomize) * patchDensity;

  vec4 cellCenter;
  float cell;
  vec3 center;
  float radFactor = 1.0 / patchDensity;

  radPeak = 0.0;
  radInner = 0.20; // 0.20; //0.15; //0.15;
  radRim = 0.30;   // 0.30; //0.35; //0.25;
  radOuter = 0.70; // 0.70; //0.70; //0.50;

  // cellCenter = Cell2NoiseCenter(point);
  cellCenter = Cell2NoiseCenter(point * (1 + 0.1 * Fbm3D(point * 5)));
  cell = cellCenter.w;
  center = cellCenter.xyz;
  float slopeFromCenter = CenteredSlope(point, center);
  float patches =
      TholinPatchColorFunc(cell * radFactor, slopeFromCenter, height);

  return pow(saturate(1.0 - patches), 2.0);
}

//-----------------------------------------------------------------------------

// Function // Modified rayed craters to have random brightness
float _RayedCraterColorNoise(vec3 point, float cratFreq, float cratSqrtDensity,
                             float cratOctaves) {
  vec3 binormal = normalize(vec3(
      -point.z, 0.0, point.x)); // = normalize(cross(point, vec3(0, 1, 0)));
  vec3 rotVec = normalize(Randomize);

  // Craters roundness distortion
  noiseH = 0.5;
  noiseLacunarity = 2.218281828459;
  noiseOffset = 0.8;
  noiseOctaves = 3;
  craterDistortion = 1.0;
  craterRoundDist = 0.03;
  float shapeDist = 1.0 + 2.5 * craterRoundDist * Fbm(point * 419.54);
  float colorDist = 1.0 - 0.3 * Fbm(point * 315.16);

  float color = 0.0;
  float fi;
  vec2 cell;
  vec3 cellCenter = vec3(0.0);
  float rad;
  float radFactor = shapeDist / cratSqrtDensity;
  float fibFreq = 10.0 * cratFreq + Randomize.x + Randomize.y + Randomize.z;

  heightFloor = -0.5;
  heightPeak = 0.6;
  heightRim = 1.0;
  radPeak = 0.004;
  radInner = 0.015;
  radRim = 0.03;
  radOuter = 1.3;

  for (int i = 0; i < cratOctaves; i++) {
    // cell = Cell2NoiseSphere(point, craterSphereRadius);
    ////cell = Cell2NoiseVec(point * craterSphereRadius, 1.0);
    // fi = acos(dot(binormal, normalize(cell.xyz - point))) / pi2;
    // color += vary * RayedCraterColorFunc(cell.w * radFactor, fi, 48.3 *
    // dot(cell.xyz, Randomize)); radInner  *= 0.6;

    cell = inverseSF(point, fibFreq, cellCenter);
    rad = hash1(cell.x * 743.1) * 1.4 + 0.1;
    fi = acos(dot(binormal, normalize(cellCenter - point))) / pi2;

    float brightness = pow(Fbm(cellCenter * 1000.0), 2.0) * 2.0;
    color += RayedCraterColorFunc(cell.y * radFactor / rad, fi,
                                  48.3 * dot(cellCenter, Randomize)) *
             brightness;

    if (cratOctaves > 1) {
      point = Rotate(pi2 * hash1(float(i)), rotVec, point);
      fibFreq *= 1.125;
      radFactor *= sqrt(1.125);
      radInner *= 0.9;
    }
  }

  return min(color, 1.0) * colorDist;
}

//-----------------------------------------------------------------------------

// Function // Construct Color Map
vec4 ColorMapSelena(vec3 point, in BiomeData biomeData) {
  Surface surf;

  float _hillsMagn = hillsMagn;
  if (hillsMagn < 0.05) {
    _hillsMagn = 0.05;
  }

  // Fetch variables // Colors
  vec4 iceColorHSL = texelFetch(BiomeDataTable, ivec2(0, BIOME_ICE), 0);
  vec3 iceColor = hsl2rgb2(iceColorHSL.xyz);

  vec4 snowColorHSL = texelFetch(BiomeDataTable, ivec2(0, BIOME_SNOW), 0);
  vec3 snowColor = hsl2rgb2(snowColorHSL.xyz);

  vec4 bottomColorHSL = texelFetch(BiomeDataTable, ivec2(0, BIOME_BOTTOM), 0);
  vec3 bottomColor = hsl2rgb2(bottomColorHSL.xyz);
  float bottomAlpha = bottomColorHSL.w;
  bool aquaria = (bottomAlpha == 0.001);

  // Fetch variables // Planet types
  // 21-10-2024 by Sp_ce // Added europaLikeness
  bool enceladusLike = ((cracksOctaves > 0.0) && (canyonsMagn > 0.52) &&
                        (mareFreq < 1.7) && (cracksFreq < 0.6));
  bool europaLike = ((cracksOctaves > 0.0) && (canyonsMagn > 0.52) &&
                     (mareFreq < 1.7) && (cracksFreq >= 0.6));

  // bool enceladusLike = (cracksMagn > 0.077);
  // bool enceladusLike = ((volcanoActivity > 0.004) && (volcanoActivity <
  // 0.01)); bool europaLike = ((cracksOctaves > 0.0) && (canyonsMagn > 0.52) &&
  // (mareFreq < 1.7) && (cracksFreq >= 0.6) && !enceladusLike);
  float europaLikeness;
  if (riftsSin < 6.0) {
    europaLikeness = 1.0;
  } else if (riftsSin > 8.0) {
    europaLikeness = 0.0;
  } else {
    europaLikeness = -(1.0 / 2.0) * riftsSin + 8.0 / 2.0;
  }

  // GlobalModifier // Assign climate
  noiseOctaves = 6.0;
  noiseH = 0.5;
  noiseLacunarity = 2.218281828459;
  noiseOffset = 0.8;
  float climate, latitude, dist;
  if (tidalLock <= 0.0) {
    latitude = abs(point.y);
    latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
    latitude = saturate(latitude);
    /*
            if (latitude < latTropic - tropicWidth)
        climate = mix(climateTropic, climateEquator, saturate((latTropic -
    latitude - tropicWidth) / latTropic)); else if (latitude > latTropic +
    tropicWidth) climate = mix(climateTropic, climatePole, saturate((latitude -
    latTropic - tropicWidth) / (1.0 - latTropic))); else climate =
    climateTropic;
            */
    climate = biomeData.height;
  } else {
    latitude = 1.0 - point.x;
    latitude += 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
    climate = mix(climateTropic, climatePole, saturate(latitude));
  }

  /*
      // Change climate with elevation
  noiseOctaves    = 5.0;
  noiseLacunarity = 3.5;
  float vary = Fbm(point * 1700.0 + Randomize);
  float snowLine   = biomeData.height + 0.25 * vary * biomeData.slope;
  float montHeight = saturate((biomeData.height - seaLevel) / (snowLevel -
  seaLevel)); climate = min(climate + heightTempGrad * montHeight, climatePole -
  0.125); climate = mix(climate, climatePole, saturate((snowLine - snowLevel) *
  100.0));

  // Ice caps
  float iceCap = saturate((latitude / latIceCaps - 1.0) * 50.0);
  climate = mix(climate, climatePole, iceCap);

  // Flatland climate distortion
  noiseOctaves    = 4.0;
  noiseLacunarity = 2.218281828459;
      vec3  pp = (point + Randomize) * (0.0005 * hillsFreq / (_hillsMagn *
  _hillsMagn)); float fr = 0.20 * (1.5 - RidgedMultifractal(pp,         2.0)) +
             0.05 * (1.5 - RidgedMultifractal(pp * 10.0,  2.0)) +
             0.02 * (1.5 - RidgedMultifractal(pp * 100.0, 2.0));
  vec3  p = point * (colorDistFreq * 0.005) + vec3(fr);
  p += Fbm3D(p * 0.38) * 1.2;
  vary = Fbm(p) * 0.35 + 0.245;
      //RODRIGO - MODIFIED VALUES
  climate += 2.3*vary * saturate(1.0 - 3.0 * biomeData.slope) * saturate(1.0
  - 1.333 * climate);
      */

  // GlobalModifier // Flatland climate distortion
  noiseOctaves = 15.0;
  dist = 1.5 * floor(2.0 * DistFbm(point * 0.002 * colorDistFreq, 2.0));
  climate += colorDistMagn * dist;

  // GlobalModifier // Biome domains
  vec3 p = point * mainFreq + Randomize;
  vec4 col;
  noiseOctaves = 6;
  vec3 distort = p * 2.3 + 13.5 * Fbm3D(p * 0.06);
  vec2 cell = Cell3Noise2Color(distort, col);
  float biome = col.r;
  float biomeScale = saturate(2.0 * (pow(abs(cell.y - cell.x), 0.7) - 0.05));

  // Non-functional? // Color texture variation
  noiseOctaves = 5;
  p = point * colorDistFreq * 2.3;
  p += Fbm3D(p * 0.5) * 1.2;
  float vary = saturate((Fbm(p) + 0.7) * 0.7);

  // TerrainFeature // Shield volcano lava
  if (volcanoOctaves > 0) {
    // Global volcano activity mask
    noiseOctaves = 3;
    float volcActivity =
        saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
    // Lava in volcano caldera and flows
    vec2 volcMask = VolcanoGlowNoise(point);
    volcMask.x *= volcActivity;
    // Model lava as rocks texture
    climate = mix(climate, 0.0, volcMask.x);
    biomeData.slope = mix(biomeData.slope, 0.0, volcMask.x);
  }

  // GlobalModifier // Scale detail texture UV and add a small distortion to it
  // to fix pixelization
  vec2 detUV = (TexCoord.xy * faceParams.z + faceParams.xy) * texScale;
  noiseOctaves = 4.0;
  vec2 shatterUV = Fbm2D2(detUV * 16.0) * (16.0 / 512.0);
  detUV += shatterUV;

  surf = GetBaseSurface(biomeData.height, detUV);

  // GlobalModifier // ColorVary setup
  vec3 zz =
      (point + Randomize) * (0.0005 * hillsFreq / (_hillsMagn * _hillsMagn));
  noiseOctaves = 14.0;
  noiseH = 0.5 + smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
  noiseOctaves = 14.0;
  vec3 albedoVaryDistort =
      Fbm3D((point * 1 + Randomize) * .07) *
      (1.5 + venusMagn); // Fbm3D((point + Randomize) * 0.07) * 1.5;

  if (cracksOctaves == 0 && volcanoActivity >= 1.0) {
    albedoVaryDistort =
        (saturate(iqTurbulence(point, 0.55) * (2 * (volcanoActivity - 1))) +
         saturate(iqTurbulence(point, 0.75) * (2 * (volcanoActivity - 1)))) *
            (volcanoActivity - 1) +
        (Fbm3D((point + Randomize) * 0.07) * 1.5) * (2 - volcanoActivity);
  } else if (cracksOctaves == 0 && volcanoActivity < 1.0) {
    albedoVaryDistort = Fbm3D((point + Randomize) * 0.07) * 1.5;
  }

  else if (cracksOctaves > 0) {

    albedoVaryDistort =
        Fbm3D((point * 0.26 + Randomize) * (volcanoActivity / 2 + 1)) *
            (1.5 + venusMagn) +
        saturate(iqTurbulence(point, 0.15) *
                 volcanoActivity); // albedoVaryDistort =Fbm3D((point *
                                   // volcanoActivity + Randomize) *
                                   // volcanoActivity) * (1.5 + venusMagn );
  }

  if (europaLike) {
    vary = 1.0 - Fbm(0.5 * (point + albedoVaryDistort) *
                     (1.5 - RidgedMultifractal(zz, 8.0) +
                      RidgedMultifractal(zz * 0.999, 8.0)));
  } else {
    vary = 1.0 - Fbm((point + albedoVaryDistort) *
                     (1.5 - RidgedMultifractal(zz, 8.0) +
                      RidgedMultifractal(zz * 0.999, 8.0)));
  }
  vary *= 0.5 * vary * vary;

  // TerrainModifier // Suppress Young Craters
  if (craterSqrtDensity > 0.05) {
    noiseOctaves = 4.0;
    vec3 youngDistort = Fbm3D((point - Randomize) * 0.07) * 1.1;
    noiseOctaves = 8.0;
    float young = 1.0 - Fbm(point + youngDistort);
    young = smoothstep(0.0, 1.0, young * young * young);
    vary = mix(0.0, vary, young);
  }

  // TerrainFeature // Ice cracks
  // 26-10-2024 by Sp_ce // Removed europaLike cracks and added them into
  // europaLike section
  float mask = 1.0;
  // FIXME: Update cracks on non-europalikes to look better. For now, just
  // remove them.

  // if (cracksOctaves > 0.0 && !europaLike) {
  //   vary *= CrackColorNoise(point, mask);
  // }

  // PlanetTypes // Enceladuslike terrain
  if (enceladusLike) {
    vary /= CrackColorNoise(point, mask);
    noiseOctaves = 6.0;
    noiseLacunarity = 2.218281828459;
    noiseH = 0.9;
    noiseOffset = 0.5;
    p = point * 0.5 * mainFreq + Randomize;
    distort = Fbm3D(point * 0.1) * 3.5 + Fbm3D(point * 0.1) * 6.5 +
              Fbm3D(point * 0.1) * 12.5;
    cell = Cell3Noise2(canyonsFreq * 0.05 * p + distort);
    float rima2 = 2 - saturate(abs(cell.y - cell.x) * 250.0 * canyonsMagn);
    rima2 = biomeScale * smoothstep(0.0, 1.0, rima2);
    vary -= 1 - rima2;
    surf.color = mix(vec4(0.75, 0.9, 1.0, 0.00), vec4(1.0), vary);
  }

  // PlanetTypes // Europalike terrain
  // 8-10-2024 by Sp_ce // Changed cracksOctaves to +2 instead of +3
  // 21-10-2024 by Sp_ce // Low europaLikeness decreases white down to minimum
  // 50% 22-10-2024 by Sp_ce // Reverted europaLikeness, added white cracks
  // 23-10-2024 by Sp_ce // Changed vec3(1.0) to iceColor
  // 26-10-2024 by Sp_ce // Added ice cracks section cracks here
  else if (europaLike) {
    float europaCracksOctaves = cracksOctaves + 2;
    vary *= EuropaCrackColorNoise(point, europaCracksOctaves + 1, mask);
    vary *= (0.2 * EuropaCrackColorNoise(point * 2, europaCracksOctaves, mask) +
             0.2 * EuropaCrackColorNoise(point * 4, europaCracksOctaves, mask) +
             0.1 * EuropaCrackNoise(point * 32, europaCracksOctaves, mask) +
             0.05 * EuropaCrackNoise(point * 64, europaCracksOctaves, mask));
    surf.color.rgb = mix(surf.color.rgb, iceColor, pow(vary, 0.4));

    float whiteCracks =
        0.3 * EuropaCrackColorNoise(point * 2, cracksOctaves, mask);
    surf.color.rgb = mix(surf.color.rgb, vec3(1.0), 0.3 - whiteCracks);
  }

  // TerrainFeature // Europa freckles
  if ((biome > hillsFraction) && (biome < hills2Fraction)) {
    noiseOctaves = 10.0;
    noiseLacunarity = 2.0;
    vary *= 1.0 - saturate(2.0 * mask * biomeScale *
                           JordanTurbulence(point * hillsFreq + Randomize, 0.8,
                                            0.5, 0.6, 0.35, 1.0, 0.8, 1.0));
  }

  // GlobalModifier // ColorVary apply
  surf.color.rgb *= mix(colorVary, vec3(1.0), vary);

  // TerrainFeature // Vegetation
  if (plantsBiomeOffset > 0.0) {
    noiseH = 0.5;
    noiseLacunarity = 2.218281828459;
    noiseOffset = 0.8;
    noiseOctaves = 2.0;
    float plantsTransFractal =
        abs(0.125 * Fbm(point * 3.0e5) + 0.125 * Fbm(point * 1.0e3));

    // Modulate by humidity
    noiseOctaves = 8.0;
    float humidityMod =
        Fbm((point + albedoVaryDistort) * 1.73) - 1.0 + humidity * 2.0;

    float plantsFade =
        smoothstep(beachWidth, beachWidth * 2.0, biomeData.height - seaLevel) *
        smoothstep(0.750, 0.650, biomeData.slope) *
        smoothstep(-0.5, 0.5, humidityMod);

    // Interpolate previous surface to the vegetation surface
    ModifySurfaceByPlants(surf, detUV, climate, plantsFade, plantsTransFractal);
  }

  // TerrainFeature // Rayed craters
  if (craterSqrtDensity * craterSqrtDensity * craterRayedFactor > 0.05 * 0.05) {
    float craterRayedDensity = craterSqrtDensity * sqrt(craterRayedFactor);
    float craterRayedOctaves = floor(craterOctaves + min(craterRayedFactor * 240.0, 60.0));
    float crater = _RayedCraterColorNoise(point, craterFreq, craterRayedDensity,
                                          craterRayedOctaves);
    surf.color.rgb = mix(surf.color.rgb, vec3(1.0), crater);
  }

  // Fetch variables // Get height slope normal
  float height = 0.0;
  float slope = 0.0;
  vec3 normal;
  GetSurfaceHeightAndSlopeAndNormal(height, slope, normal);

  // TerrainFeature // Tholin patches
  // 8-10-2024 by Sp_ce // Disabled at 0.5, 0.15
  // 19-10-2024 by Sp_ce // Complete revamp and changing to *= mix color
  // 20-10-2024 by Sp_ce // Added height mod
  // 21-10-2024 by Sp_ce // Added aquaria requirement for altered tholinColor
  float tholinPatch = saturate(TholinPatchNoise(point + Randomize, height));
  vec3 tholinColor = vec3(0.513, 0.498, 0.363);
  if (aquaria) {
    tholinColor = bottomColor;
    surf.color.rgb *=
        mix(vec3(0.25) + tholinColor * 0.75, vec3(1.0), 1 - tholinPatch);
  }

  // TerrainFeature // Driven darkening
  // 8-10-2024 by Sp_ce // Changed to take Bottom color
  if (drivenDarkening != 0.0) {
    noiseOctaves = 3;
    float z = -point.z * sign(drivenDarkening);

    z += 0.2 * Fbm(point * 1.63);
    z = saturate(1.0 - z);
    z *= z;

    if (abs(drivenDarkening) < 0.55) {
      surf.color.rgb *= mix(vec3(1.0 - abs(drivenDarkening)) +
                                tholinColor.rgb * abs(drivenDarkening),
                            vec3(1.0), z);
    } else {
      surf.color.rgb *= mix(vec3(0.45) + tholinColor * 0.55, vec3(1.0), z);
    }
  }

  // TerrainFeature // Polar slope ice
  // 22-10-2024 by Sp_ce // Changed vec3(1.0) to snowColor
  float slopedFactor = SlopedIceCaps(slope, latitude);
  float iceCap = saturate((latitude - latIceCaps + 0.3) * 2.0 * slopedFactor);
  // BUG: negative snowLevel results in black snow. But it looks too cool to not
  // keep.
  float snow = float(slope / snowLevel);
  if (snowLevel == 2.0) {
    snow = 0.0;
  }

  surf.color.rgb = mix(surf.color.rgb, snowColor, 0.8 * iceCap + snow);

  // GlobalModifier // Slope contrast
  surf.color.rgb *= 0.9 + biomeData.slope * 0.5;

  // Return surface color
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
