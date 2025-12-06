#include "tg_common.glh"

#ifdef _FRAGMENT_

 // -----------------------------------------------------------------------------

vec4 GlowMapTerra(vec3 point, float height, float slope) {
     // Assign a climate type
    noiseOctaves = (oceanType = = 1.0) ? 5.0 : 12.0; // Reduce terrain octaves on oceanic planets (oceanType == 0.1)
    noiseH = 0.5;
    noiseLacunarity = 2.218281828459;
    noiseOffset = 0.8;
    float climate, latitude, dist;
    if(tidalLock < = 0.0) {
        latitude = abs(point.y);
        latitude + = 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        latitude = saturate(latitude);
        if(latitude < latTropic - tropicWidth)
        climate = mix(climateTropic, climateEquator, (latTropic - tropicWidth - latitude) / latTropic);
        else if(latitude > latTropic + tropicWidth)
        climate = mix(climateTropic, climatePole, (latitude - latTropic - tropicWidth) / (1.0 - latTropic));
        else
        climate = climateTropic;
    }else {
        latitude = 1.0 - point.x;
        latitude + = 0.15 * (Fbm(point * 0.7 + Randomize) - 1.0);
        climate = mix(climateTropic, climatePole, saturate(latitude));
    }

     // Litosphere cells
     // float lithoCells = LithoCellsNoise(point, climate, 1.5);

     // Change climate with elevation
    float montHeight = saturate((height - seaLevel) / (snowLevel - seaLevel));
    climate = min(climate + heightTempGrad * montHeight, climatePole);

     // Ice caps
    float iceCap = saturate((latitude / latIceCaps - 1.0) * 50.0);
    climate = mix(climate, climatePole, iceCap);

     // Thermal emission temperature (in thousand Kelvins)
    vec3 p = point * 6.0 + Randomize;
    noiseOctaves = 5;
    noiseH = 0.3;
    dist = 10.0 * colorDistMagn * Fbm(p * 0.2);
     // float varyTemp = 0.5 * smoothstep(0.0, 0.4, cell.y - cell.x);
     // float varyTemp = 0.5 * sqrt(abs(cell.y - cell.x));
    float varyTemp = 1.0 - 5.0 * RidgedMultifractal(p, 16.0);
    noiseOctaves = 3;
    float globTemp = 0.95 - abs(Fbm((p + dist) * 0.01)) * 0.08;
    noiseOctaves = 8;
     // float varyTemp = abs(Fbm(p + dist));
     // globTemp *= 1.0 - lithoCells;

     // Copied from height shader, for extra detail
    float venus = 0.0;

    noiseOctaves = 4;
    noiseH = 0.9;
    vec3 distort = Fbm3D(point * 0.3) * 1.5;
    noiseOctaves = 6;
    venus = Fbm((point + distort) * 1.0) * (0.3);


    float surfTemp = surfTemperature * 
    (globTemp + venus * varyTemp * 0.04) * 
    saturate(2.0 * (lavaCoverage * 0.4 + 0.4 - 0.8 * height)) * 
    saturate((lavaCoverage - 0.01) * 25.0) * 
    saturate((0.875 - climate) * 50.0);

     // Shield volcano lava
    if(volcanoOctaves > 0 & & height > seaLevel + 0.1 & & iceCap = = 0.0) {
         // Global volcano activity mask
        noiseOctaves = 3;
        float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + volcanoActivity) * 5.0);
         // float volcActivity = saturate((Fbm(point * 1.37 + Randomize) - 1.0 + 0.5) * 5.0);
         // Lava in the volcano caldera and lava flows
        vec2 volcMask = VolcanoGlowNoise(point);
        volcMask.x * = (0.75 + 0.25 * varyTemp) * volcActivity * volcanoTemp;
        surfTemp = max(surfTemp, volcMask.x);
    }

     // Io-like volcanoes
     // float volcIo = saturate(abs(Fbm(point * 6.3 + Randomize) * 1.4)); // * 1.4 * lavaCoverage));

     // float r = log(surfTemp) * 0.188 + 0.1316;
     // return vec4(r, 0.0, 0.0, 1.0);

    surfTemp = EncodeTemperature(surfTemp); // encode to [0...1] range
    return vec4(surfTemp);
}

 // -----------------------------------------------------------------------------

void main() {
    vec3 point = GetSurfacePoint();
    float height = 0, slope = 0;
    GetSurfaceHeightAndSlope(height, slope);
    OutColor = GlowMapTerra(point, height, slope);
}

 // -----------------------------------------------------------------------------

#endif