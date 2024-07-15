#include "tg_common.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Modified Rodrigo's rifts

void _Rifts(vec3 point, float damping, inout float height) {
    float riftsBottom = seaLevel;

    noiseOctaves = 6.6;
    noiseH = 1.0;
    noiseLacunarity = 4.0;
    noiseOffset = 0.95;

    // 2 slightly different octaves to make ridges inside rifts
    vec3 p = point * 0.12;
    float rifts = 0.0;
    for(int i = 0; i < 2; i++) {
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
    if(rifts > 0.0) {
        float slope = smoothstep(0.1, 0.9, 1.0 - 2.0 * abs(rifts * 0.35 - 0.5));
        float slopeMod = 0.5 * slope * RidgedMultifractalErodedDetail(point * 5.0 * canyonsFreq + Randomize, 8.0, erosion, 8.0);
        slopeMod *= 0.05 * riftsModulate;
        height = softExpMaxMin(height - slopeMod, riftsBottom, 32.0);
    }
}

//-----------------------------------------------------------------------------

float HeightMapSelena(vec3 point) {
    // Biome domains
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

    // Global landscape

//RODRIGO -SMALL TERRAIN ELEVATIONS
    noiseOctaves = 5;
    p = point * mainFreq + Randomize;
    distort = 0.35 * Fbm3D(p * 0.73);
    noiseOctaves = 10.0;
    noiseH = 1.0;
    noiseLacunarity = 2.3;
    noiseOffset = montesSpiky;
    float rocks = iqTurbulence(point * 80, 1);

    noiseOctaves = 4;
    distort += 0.005 * (1.0 - abs(Fbm3D(p * 132.3)));
    vec3 pp = (point + Randomize) * (0.0005 * hillsFreq / (hillsMagn * hillsMagn));
    float fr = 0.20 * (1.5 - RidgedMultifractal(pp, 2.0));
    float global = 1 - Cell3Noise(p + distort);
    fr *= 1.0 - smoothstep(0.04, 0.01, global - seaLevel);

    // Venus-like structure
    float venus = 0.0;

    noiseOctaves = 4;
    distort = Fbm3D(point * 0.3) * 1.5;
    noiseOctaves = 6;
    venus = Fbm((point + distort) * venusFreq + 0.1) * (venusMagn + 0.1);

    noiseOctaves = 8;

    global = (global + 0.8 * venus + (0.000006 * ((hillsFreq + 1500) / hillsMagn)) * fr - seaLevel) * 0.5 + seaLevel;

    float mr = 1.0 + 2 * Fbm(point + distort) + 7 * (1.5 - RidgedMultifractalEroded(pp * 0.8, 8.0, erosion)) -
        6 * (1.5 - RidgedMultifractalEroded(pp * 0.1, 8.0, erosion));

    mr = smoothstep(0.0, 1.0, 0.2 * mr * mr);

    mr *= 1 - smoothstep(-0.01, 0.00, seaLevel - global);
    mr = 0.1 * hillsFreq * smoothstep(0.0, 1.0, mr);
    global = mix(global, global + 0.0003, mr);
    float mask = 1.0;

    // Mare
    float mare = global;
    float mareFloor = global;
    float mareSuppress = 1.0;
    if(mareSqrtDensity > 0.05) {
        noiseOctaves = 2;
        mareFloor = 0.6 * (1.0 - Cell3Noise(0.3 * p));
        craterDistortion = 1.0;
        noiseOctaves = 6;  // Mare roundness distortion
        mare = MareNoise(point, global, mareFloor, mareSuppress);
    }

    // Old craters
    float crater = 0.0;
    if(craterSqrtDensity > 0.05) {
        heightFloor = -0.1;
        heightPeak = 0.6;
        heightRim = 1.0;
        crater = mareSuppress * CraterNoise(point, craterMagn, craterFreq, craterSqrtDensity, craterOctaves);
        noiseOctaves = 10.0;
        noiseLacunarity = 2.0;
        crater = 0.25 * crater + 0.05 * crater * iqTurbulence(point * montesFreq + Randomize, 0.55);

        // Young terrain - suppress craters
        noiseOctaves = 4.0;
        vec3 youngDistort = Fbm3D((point - Randomize) * 0.07) * 1.1;
        noiseOctaves = 8.0;
        float young = 1.0 - Fbm(point + youngDistort);
        young = smoothstep(0.0, 1.0, young * young * young);
        crater *= young;
    }

    float drivenMaterial = 0.0;

    if(abs(drivenDarkening) >= 0.55) {
        noiseOctaves = 3;
        drivenMaterial = -point.z * sign(drivenDarkening);
        drivenMaterial += 0.2 * Fbm(point * 1.63);
        drivenMaterial = saturate(drivenMaterial);
        drivenMaterial *= (1.0 / 0.45 * 0.9 - abs(point.y)) * (drivenDarkening - 0.55);
    }

    float height = mare + crater + drivenMaterial;

    if(biome > hillsFraction) {
        if(biome < hills2Fraction) {
            // "Freckles" (structures like on Europa)
            noiseOctaves = 10.0;
            noiseLacunarity = 2.0;
            height += 0.2 * hillsMagn * mask * biomeScale * JordanTurbulence(point * hillsFreq + Randomize, 0.8, 0.5, 0.6, 0.35, 1.0, 0.8, 1.0);
        } else if(biome < canyonsFraction) {
            // Rimae
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
            // Mountains
            noiseOctaves = 10.0;
            noiseLacunarity = 2.0;
            height += montesMagn * montBiomeScale * iqTurbulence(point * 0.5 * montesFreq + Randomize, 0.45);
        }
    }

// Rifts
    if(riftsSin > 7) {

        float damping;

        damping = (smoothstep(1.0, 0.1, height - seaLevel)) *
            (smoothstep(-0.1, -0.2, seaLevel - height));

        _Rifts(point, damping, height);
    }

// Ice cracks

    if(cracksOctaves > 0.0)
        height += 0.5 * CrackNoise(point, mask);

//ENCELADUS TYPE TERRAINS

    if((cracksOctaves > 0.0) && (canyonsMagn > 0.52) && (mareFreq < 1.7)) {

        if(cracksFreq < 0.6) {
            height = saturate(height * 0.3);
            noiseOctaves = 6.0;
            noiseLacunarity = 2.218281828459;
            noiseH = 0.9;
            noiseOffset = 0.5;
            p = point * 0.5 * mainFreq + Randomize;
            distort = Fbm3D(point * 0.1) * 3.5 + Fbm3D(point * 0.1) * 6.5 + Fbm3D(point * 0.1) * 12.5;
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

// EUROPA-TYPE TERRAIN

        else {

            height = saturate(height * 0.3);
            height += 0.2 * CrackNoise(point * 2, mask) + 0.2 * CrackNoise(point * 4, mask) + 0.1 * CrackNoise(point * 32, mask) + 0.05 * CrackNoise(point * 64, mask);

        }
    }

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

    // Rayed craters
    if(craterSqrtDensity * craterSqrtDensity * craterRayedFactor > 0.05 * 0.05) {
        heightFloor = -0.5;
        heightPeak = 0.6;
        heightRim = 1.0;
        float craterRayedSqrtDensity = craterSqrtDensity * sqrt(craterRayedFactor);
        float craterRayedOctaves = floor(craterOctaves * craterRayedFactor);
        float craterRayedMagn = craterMagn * pow(0.62, craterOctaves - craterRayedOctaves);
        crater = RayedCraterNoise(point, craterRayedMagn, craterFreq, craterRayedSqrtDensity, craterRayedOctaves);
        height += crater;
    }

    // Shield volcano
    if(volcanoOctaves > 0)
        height = VolcanoNoise(point, global, height);

//RODRIGO - TERRAIN NOISE MATCH ALBEDO NOISE

    noiseOctaves = 14.0;
    noiseLacunarity = 2.218281828459;
    distort = Fbm3D((point + Randomize) * 0.07) * 1.5;
    float vary = 1.0 - 5 * (Fbm((point + distort) * (1.5 - RidgedMultifractal(pp, 8.0) + RidgedMultifractal(pp * 0.999, 8.0))));
    height += saturate(0.0001 * vary);

    height = softPolyMin(height, 0.99, 0.3);
    height = softPolyMax(height, 0.01, 0.3);

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