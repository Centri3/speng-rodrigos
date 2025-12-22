#include "tg_rmr.glh"

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

// Function // Modified Rodrigo's rifts
void _RiftsNoise(vec3 point, float damping, inout float height) {
  float riftsBottom = seaLevel;

  noiseOctaves = 6.6;
  noiseH = 1.0;
  noiseLacunarity = 4.0;
  noiseOffset = 0.95;

  // 2 slightly different octaves to make ridges inside rifts
  vec3 p = point * 0.12;
  float rifts = 0.0;
  for (int i = 0; i < 2; i++) {
    vec3 distort = 0.5 * Fbm3D(p * riftsSin) + 0.1 * Fbm3D(p * 3 * riftsSin);
    ;
    vec2 cell = Cell3Noise2(riftsFreq * p + distort);
    float width = 0.8 * riftsMagn * abs(cell.y - cell.x);
    rifts = softExpMaxMin(rifts, 1.0 - 2.75 * width, 32.0);
    p *= 1.02;
  }

  float riftsModulate = smoothstep(-0.1, 0.2, Fbm(point * 2.3 + Randomize));
  rifts = smoothstep(0.0, 1.0, rifts * riftsModulate) * damping;

  height = mix(height, riftsBottom, rifts);

  // Slope modulation
  if (rifts > 0.0) {
    float slope = smoothstep(0.1, 0.9, 1.0 - 2.0 * abs(rifts * 0.35 - 0.5));
    float slopeMod =
        0.5 * slope *
        RidgedMultifractalErodedDetail(point * 5.0 * canyonsFreq + Randomize,
                                       8.0, erosion, 8.0);
    slopeMod *= 0.05 * riftsModulate;
    height = softExpMaxMin(height - slopeMod, riftsBottom, 32.0);
  }
}

//-----------------------------------------------------------------------------

// Function // Altered Mare Height Formula
float _MareHeightFunc(vec3 point, float lastLand, float lastlastLand,
                      float height, float r, inout float mareFloor) {
  float t;

  if (r < radInner) { // crater bottom
    mareFloor = 1.0;

    noiseOctaves = 6.0;
    // noiseLacunarity  = 2.218281828459;       //Caused offset
    // noiseH           = 0.9;                 // Also caused offset
    noiseOffset = 0.5;
    vec3 p = point * mainFreq + Randomize;
    vec3 distort = 3.5 * Fbm3D(point * 0.1) + 6.5 * Fbm3D(point * 0.1) +
                   12.5 * Fbm3D(point * 0.1);
    vec2 cell = Cell3Noise2(0.05 * canyonsFreq * p + distort);
    float rimaBottom = 2 - 20.0 * saturate(abs(cell.y - cell.x) * canyonsMagn);
    rimaBottom = smoothstep(0.0, 1.0, 0.2 * rimaBottom);

    float newHeight = lastlastLand + height * heightFloor;
    return newHeight;
    // return mix(newHeight, newHeight - 0.08, rimaBottom * (1 - pow(r, 4) /
    // pow(radInner, 4)));
  } else if (r < radRim) { // inner rim
    t = (r - radInner) / (radRim - radInner);
    t = smoothstep(0.0, 1.0, t);
    mareFloor = 1.0 - t;
    return mix(lastlastLand + height * heightFloor,
               lastLand + height * heightRim * craterDistortion, t);
  } else if (r < radOuter) { // outer rim
    t = 1.0 - (r - radRim) / (radOuter - radRim);
    mareFloor = 0.0;
    return mix(lastLand, lastLand + height * heightRim * craterDistortion,
               smoothstep(0.0, 1.0, t * t));
  } else {
    mareFloor = 0.0;
    return lastLand;
  }
}

//-----------------------------------------------------------------------------

// Function // Altered Mare Noise
float _MareNoise(vec3 point, float globalLand, float bottomLand,
                 inout float mareFloor) {
  point = (point * mareFreq + Randomize) * mareSqrtDensity;

  float amplitude = 0.7;
  float newLand = globalLand;
  float lastLand;
  float cell;
  float radFactor = 1.0 / mareSqrtDensity;

  radPeak = 0.0;
  radInner = 0.5;
  radRim = 0.6;
  radOuter = 1.0;
  heightFloor = 0.0;
  heightRim = 0.2;

  for (int i = 0; i < 3; i++) {
    cell = Cell2Noise(point + 0.07 * Fbm3D(point) + 0.04 * Fbm3D(point * 10));
    lastLand = newLand;
    newLand = _MareHeightFunc(10 * point, lastLand, bottomLand, amplitude,
                              cell * radFactor, mareFloor);
    point = point * 1.3 + Randomize;
    amplitude *= 0.62;
    radFactor *= 1.2;
  }

  mareFloor = 1.0 - mareFloor;
  // mareFloor = 1.0 - 0.7 * mareFloor;
  return newLand;
}

//-----------------------------------------------------------------------------

// Function // Altered Crater Height Formula
float _CraterHeightFunc(float lastlastLand, float lastLand, float height,
                        float r, float cratOctaves, float i,
                        float mareSuppress) {
  float distHeight = 0.0;

  float t = 1.0 - r / radPeak;
  float peak = heightPeak * craterDistortion * smoothstep(0.0, 1.0, t);

  t = smoothstep(0.0, 1.0, (r - radInner) / (radRim - radInner));
  float inoutMask = t * t * t;
  float innerRim = heightRim * distHeight * smoothstep(0.0, 1.0, inoutMask);

  t = smoothstep(0.0, 1.0, (radOuter - r) / (radOuter - radRim));
  float outerRim = distHeight * mix(0.05, heightRim, t * t);

  t = saturate((1.0 - r) / (1.0 - radOuter));
  float halo = 0.05 * distHeight * t;

  return mix(lastlastLand + height * heightFloor + peak + innerRim,
             lastLand + outerRim + halo, inoutMask);
}

//-----------------------------------------------------------------------------

// Function // Altered Crater Noise
float _CraterNoise(vec3 point, float cratMagn, float cratFreq,
                   float cratSqrtDensity, float cratOctaves,
                   float mareSuppress) {
  // craterSphereRadius = cratFreq * cratSqrtDensity;
  // point *= craterSphereRadius;
  point = (point * cratFreq + Randomize) * cratSqrtDensity;

  float newLand = 0.0;
  float lastLand = 0.0;
  float lastlastLand = 0.0;
  float lastlastlastLand = 0.0;
  float amplitude = 1.0;
  float cell;
  float radFactor = 1.0 / cratSqrtDensity;

  // Craters roundness distortion
  noiseH = 0.1 + smoothstep(0.0, 0.1, colorDistMagn) * 0.9;
  noiseLacunarity = 2.218281828459;
  noiseOffset = 0.8;
  noiseOctaves = 3;
  craterDistortion = 1.0;
  craterRoundDist = 0.03;

  radPeak = 0.03;
  radInner = 0.15;
  radRim = 0.2;
  radOuter = 0.8;

  for (int i = 0; i < cratOctaves; i++) {
    lastlastlastLand = lastlastLand;
    lastlastLand = lastLand;
    lastLand = newLand;

    // vec3 dist = craterRoundDist * Fbm3D(point*2.56);
    // cell = Cell2NoiseSphere(point + dist, craterSphereRadius, dist).w;
    // craterSphereRadius *= 1.83;
    cell = Cell3Noise(point + craterRoundDist * Fbm3D(point * 2.56));
    newLand = _CraterHeightFunc(lastlastlastLand, lastLand, amplitude,
                                cell * radFactor, cratOctaves, i, mareSuppress);

    // cell = inverseSF(point + 0.2 * craterRoundDist * Fbm3D(point*2.56),
    // fibFreq); rad = hash1(cell.x * 743.1) * 0.9 + 0.1; newLand =
    // CraterHeightFunc(lastlastlastLand, lastLand, amplitude, cell.y *
    // radFactor / rad); fibFreq   *= craterFreqPower; radFactor *=
    // craterRadFactorPower;

    if (cratOctaves > 1) {
      point *= craterFreqPower;
      amplitude *= craterAmplPower;
      heightPeak *= craterPeakPower;
      heightFloor *= craterFloorPower;
      radInner *= craterRadiusPower;
    }
  }

  return cratMagn * newLand;
}

//-----------------------------------------------------------------------------

// Function // Construct Height Map
float HeightMapSelena(vec3 point) {
  float _hillsMagn = hillsMagn;
  if (hillsMagn < 0.05) {
    _hillsMagn = 0.05;
  }
  float _hillsFreq =
      hillsFreq * (pow(0.99, (1 / (1 + volcanoActivity * 2) * hillsFreq)) * 5 +
                   1); // crinkle the surface for volcanic worlds 11/21/2025....
                       // scale down for large planets

  // Fetch variables // Colors
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
  // bool europaLike = ((cracksOctaves > 0.0) && (canyonsMagn > 0.52) &&
  // (mareFreq < 1.7) && (cracksFreq >= 0.6) && !enceladusLike);
  float europaLikeness;
  if ((riftsSin > 8.0) || !europaLike) {
    europaLikeness = 0.0;
  } else if (riftsSin < 6.0) {
    europaLikeness = 1.0;
  } else {
    europaLikeness = -(1.0 / 2.0) * riftsSin + 8.0 / 2.0;
  }

  // GlobalModifier // Biome domains
  vec3 p = point * mainFreq + Randomize;
  vec4 col;
  noiseOctaves = 6;
  vec3 distort = p * 2.3 + 13.5 * Fbm3D(p * 0.06);
  vec2 cell = Cell3Noise2Color(distort, col);
  float biome = col.r;
  float biomeScale = saturate(2.0 * (pow(abs(cell.y - cell.x), 0.7) - 0.05));

  float montRage = saturate(DistNoise(point * 22.6 + Randomize, 2.5) + 0.5);
  montRage *= montRage;
  float montBiomeScale = min(pow(2.2 * biomeScale, 2.5), 1.0) * montRage;
  float inv2montesSpiky = 1.0 / (montesSpiky * montesSpiky);

  // GlobalModifier // Global landscape
  noiseOctaves = 5;
  p = point * mainFreq + Randomize;
  distort = 0.35 * Fbm3D(p * 0.73);
  noiseOctaves = 10.0;
  noiseH = 1.0;
  // noiseLacunarity = 2.3; // Caused offset
  noiseOffset = montesSpiky;
  float rocks = iqTurbulence(point * 80, 1);

  noiseOctaves = 4;
  distort += 0.005 * (1.0 - abs(Fbm3D(p * 132.3)));
  vec3 pp =
      (point + Randomize) * (0.0005 * _hillsFreq / (_hillsMagn * _hillsMagn));
  float fr = 0.20 * (1.5 - RidgedMultifractal(pp, 2.0));
  float global = 1 - Cell3Noise(p + distort);
  fr *= 1.0 - smoothstep(0.04, 0.01, global - seaLevel);

  // GlobalModifier // Venus
  float venus = 0.0;
  noiseOctaves = 4;
  distort = Fbm3D(point * 0.3) * 1.5;
  noiseOctaves = 6;
  venus = Fbm((point + distort) * venusFreq + 0.1) * (venusMagn + 0.1);

  noiseOctaves = 8;
  global = (global + 0.8 * venus +
            (0.000006 * ((_hillsFreq + 1500) / _hillsMagn)) * fr - seaLevel) *
               0.5 +
           seaLevel;

  float mr = 1.0 + 2 * Fbm(point + distort) +
             7 * (1.5 - RidgedMultifractalEroded(pp * 0.8, 8.0, erosion)) -
             6 * (1.5 - RidgedMultifractalEroded(pp * 0.1, 8.0, erosion));

  mr = smoothstep(0.0, 1.0, 0.2 * mr * mr);

  mr *= 1 - smoothstep(-0.01, 0.00, seaLevel - global);
  mr = 0.1 * _hillsFreq * smoothstep(0.0, 1.0, mr);
  global = mix(global, global + 0.0003, mr);
  float mask = 1.0;

  // GlobalModifier // Set global height
  float height = global;

  // TerrainFeature // Rifts
  if (riftsSin > 7) {
    float damping;
    damping = (smoothstep(1.0, 0.1, height - seaLevel)) *
              (smoothstep(-0.1, -0.2, seaLevel - height));
    _RiftsNoise(point, damping, height);
  }

  // TerrainFeature // Mares
  float mare = height;
  float mareFloor = height;
  float mareSuppress = 1.0;
  if (mareSqrtDensity > 0.05) {
    noiseOctaves = 2;
    mareFloor = 0.6 * (1.0 - Cell3Noise(0.3 * p));
    craterDistortion = 1.0;
    noiseOctaves = 6; // Mare roundness distortion
    mare = _MareNoise(point, height, mareFloor, mareSuppress);
  }

  // TerrainFeature // Craters (old)
  // 25-10-2024 by Sp_ce // Crater density is reduced for high europaLikeness
  // 25-10-2024 by Sp_ce // Altered crater density function, high densities can
  // now appear on high europaLikeness, but rarely
  float crater = 0.0;
  if (craterSqrtDensity > 0.05) {
    float craterSqrtDensityAltered =
        max(craterSqrtDensity * (0.2 + 0.8 * (1.0 - europaLikeness)),
            10 * (craterSqrtDensity - 0.9));

    heightFloor = -0.1;
    heightPeak = 0.6;
    heightRim = 1.0;
    // crater = _CraterNoise(point, craterMagn, craterFreq, craterSqrtDensity,
    // craterOctaves, mareSuppress); // NEW SUPPRESS
    crater =
        saturate(mareSuppress + Fbm(10 * point)) *
        CraterNoise(point, craterMagn, craterFreq,
                    (craterSqrtDensityAltered * (1 - (volcanoActivity / 2.5))),
                    craterOctaves); // Supress craters on volcanic worlds
    noiseOctaves = 10.0;
    noiseLacunarity = 2.0;
    crater = 0.25 * crater +
             0.05 * crater * iqTurbulence(point * montesFreq + Randomize, 0.55);

    // Suppress Young Craters
    noiseOctaves = 4.0;
    vec3 youngDistort = Fbm3D((point - Randomize) * 0.07) * 1.1;
    noiseOctaves = 8.0;
    float young = 1.0 - Fbm(point + youngDistort);
    young = smoothstep(0.0, 1.0, young * young * young);
    crater *= young;
  }

  // TerrainFeature // Driven darkening material buildup
  float drivenMaterial = 0.0;
  if (abs(drivenDarkening) >= 0.55) {
    noiseOctaves = 3;
    drivenMaterial = -point.z * sign(drivenDarkening);
    drivenMaterial += 0.2 * Fbm(point * 1.63);
    drivenMaterial = saturate(drivenMaterial);
    drivenMaterial *= (1 / 0.45) * (abs(drivenDarkening) - 0.55);
  }

  // GlobalModifier // Construct features
  height = mare + crater + drivenMaterial;

  // TerrainFeature // Apply hills & mountains
  if (biome > hillsFraction) {
    if (biome < hills2Fraction) {
      // TerrainFeature // Europa freckles
      noiseOctaves = 10.0;
      noiseLacunarity = 2.0;
      height += 0.2 * _hillsMagn * mask * biomeScale *
                JordanTurbulence(point * _hillsFreq + Randomize, 0.8, 0.5, 0.6,
                                 0.35, 1.0, 0.8, 1.0);
    } else if (biome < canyonsFraction) {
      // TerrainFeature // Rimae
      noiseOctaves = 3.0;
      noiseLacunarity = 2.218281828459;
      noiseH = 0.9;
      noiseOffset = 0.5;
      p = point * mainFreq + Randomize;
      distort = 0.035 * Fbm3D(p * riversSin * 5.0);
      distort += 0.350 * Fbm3D(p * riversSin);
      cell = Cell3Noise2(canyonsFreq * 0.05 * p + distort);
      float rima = 1.0 - saturate(abs(cell.y - cell.x) * 250.0 * canyonsMagn);
      rima = biomeScale * smoothstep(0.0, 1.0, rima);
      height = mix(height, height - 0.02, rima);
    } else {
      // TerrainFeature // Mountains
      noiseOctaves = 10.0;
      noiseLacunarity = 2.0;
      height += mareSuppress * montesMagn * montBiomeScale *
                iqTurbulence(point * 0.5 * montesFreq + Randomize, 0.45);
    }
  }

  // TerrainFeature // Shield volcano
  if (volcanoOctaves > 0) {
    height = VolcanoNoise(point, global, height);
  }

  // PlanetTypes // Plutolike terrain
  if (canyonsMagn == 0.51) {
    vec3 pp = (point + Randomize) * 220.25;
    float fr = 0.20 * (1.5 - RidgedMultifractal(0.3 * pp, 2.0));
    global += (0.00002 * (_hillsFreq + 1500) / _hillsMagn) * fr;
    crater *= 1.0 - smoothstep(0.1, 0.05, global - seaLevel);
    height *= saturate(mare + crater);
    p = point * 20 + Randomize;
    distort = Fbm3D(point * 0.1) * 3.5 + Fbm3D(point * 0.1) * 6.5 +
              Fbm3D(point * 0.1) * 12.5;
    cell = Cell3Noise2(canyonsFreq * 0.05 * p + distort);
    float flows = 1.0 - saturate(abs(cell.y - cell.x) * riversMagn) +
                  0.05 * iqTurbulence(point * 5000, 0.55);
    flows *= 1.0 - smoothstep(0.05, -0.05, seaLevel - height);
    height = mix(height, height - 0.01, flows);
  }

  // PlanetTypes // Enceladuslike terrain
  if (enceladusLike) {
    height = saturate(height * 0.3);
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
    height = mix(height, height - 0.08, -rima2);

    noiseOctaves = 1;
    height -= 0.5 * CrackNoise(point, mask);
    distort = Fbm3D(point * 0.1) * 3.5;
    float venus2 = (Fbm(point + distort) * 1.5) * 0.5;
    height = mix(height, height - 0.2, venus2);
  }

  // TerrainFeature // Equatorial ridge
  /*
if (eqridgeMagn > 0.0)
{
  noiseOctaves = 2.5;
  float x = point.y / eqridgeWidth;
  float ridgeHeight = exp(-0.75 * pow(abs(x), 1.5));
  float ridgeModulate = saturate(1.0 - eqridgeModMagn * (Fbm(point *
eqridgeModFreq - Randomize) * 0.5 + 0.5)); height += eqridgeMagn * ridgeHeight *
ridgeModulate;
}
  */

  // TerrainFeature // Equatorial ridge
  // 18-7-2024 by Sp_ce // Attempting improvement to bring inline with iapetus
  if (eqridgeMagn > 0.0) {
    // noiseOctaves    = 4.0;
    noiseOctaves = 10.0;
    noiseLacunarity = 2.0;
    noiseH = 0.9;
    noiseOffset = 0.5;
    float x = (point.y + 0.1 * Fbm(point)) / eqridgeWidth;
    float ridgeHeight = exp(-0.75 * pow(abs(x), 1.5));
    // height = max(height + (eqridgeMagn * ridgeHeight * iqTurbulence(point
    // * 1.0 * eqridgeModFreq + Randomize, eqridgeModMagn)), height);
    // eqridgeModMagn 0.7 - 1.2
    // eqridgeModFreq 4
    float eqridgeHeight = pow(eqridgeMagn, 1.25);
    height =
        max(height + (eqridgeMagn * ridgeHeight *
                      iqTurbulence(point * 0.4 * eqridgeModFreq + Randomize,
                                   0.2 * eqridgeModMagn)),
            height);
  }

  // TerrainFeature // Rayed craters
  if (craterSqrtDensity * craterSqrtDensity * craterRayedFactor > 0.05 * 0.05) {
    heightFloor = -1.5;
    heightPeak = 0.15;
    heightRim = 1.0;
    float craterRayedDensity = craterSqrtDensity * sqrt(craterRayedFactor);
    float craterRayedOctaves =
        floor(craterOctaves + smoothstep(0.0, 0.5, craterRayedFactor) * 60.0);
    float craterRayedMagn =
        craterMagn *
        0.25; // removed * pow(1.0, craterOctaves - craterRayedOctaves),  toned
              // down rayed crater depth donatelo200 12/07/2025
    crater = _RayedCraterNoise(point, craterRayedMagn, craterFreq,
                               craterRayedDensity, craterRayedOctaves);
    height +=
        crater *
        (height + 0.2); // toned down rayed crater depth donatelo200 12/07/2025
                        // (mostly works but some edge cases still break
  }

  // GlobalModifier // Terrain noise match colorvary
  noiseOctaves = 14.0;
  noiseLacunarity = 2.218281828459;
  noiseH = 0.5 + smoothstep(0.0, 0.1, colorDistMagn) * 0.5;
  if (cracksOctaves > 0) {
    noiseH += 0.3;
  }
  distort = Fbm3D((point + Randomize) * 0.07) *
            1.5; // Fbm3D((point + Randomize) * 0.07) * 1.5;

  if (cracksOctaves == 0 && volcanoActivity >= 1.0) {
    distort =
        (saturate(iqTurbulence(point, 0.55) * (2 * (volcanoActivity - 1))) +
         saturate(iqTurbulence(point, 0.75) * (2 * (volcanoActivity - 1)))) *
            (volcanoActivity - 1) +
        (Fbm3D((point + Randomize) * 0.07) * 1.5) *
            (2 - volcanoActivity); // Io like on atmosphered planets
  } else if (cracksOctaves == 0 && volcanoActivity < 1.0) {
    distort = Fbm3D((point + Randomize) * 0.07) *
              1.5; // Io like on airless planets donatelo200 12/09/2025
  }

  else if (cracksOctaves > 0) {

    distort = Fbm3D((point * 0.26 + Randomize) * (volcanoActivity / 2 + 1)) *
                  (1.5 + venusMagn) +
              saturate(iqTurbulence(point, 0.15) * volcanoActivity);
  }

  float vary =
      1.0 -
      5 * (Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) +
                                    RidgedMultifractal(pp * 0.999, 8.0))));
  if (cracksOctaves > 0) {
  height = mix(height, height + 0.1, vary);
  } else {
  height = mix(height, height + 0.0017, vary);
    
  }

  // GlobalModifier // Soften max/min height
  height = softPolyMin(height, 0.99, 0.3);
  height = softPolyMax(height, 0.01, 0.3);

  // Return height
  return height;
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height = HeightMapSelena(point);
  OutColor = vec4(height);
}

//-----------------------------------------------------------------------------

#endif