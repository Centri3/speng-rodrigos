#include "tg_rmr.glh"

#ifdef _FRAGMENT_

float CycloneColorGasGiantAli(vec3 point) {
  vec3 rotVec = normalize(Randomize);
  vec3 twistedPoint = point;
  vec3 cellCenter = vec3(0.0);
  vec2 cell;
  float r, fi, rnd, dist, dist2, dir;
  float offset = 0.0;
  float offs = 0.5 / (cloudsLayer + 1.0);
  float squeeze = 1.9;
  float strength = 10.0;
  float freq = cycloneFreq * 30.0;
  float dens = cycloneDensity * 0.02;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);

  for (int i = 0; i < cycloneOctaves; i++) {
    cell = inverseSF(vec3(point.x, point.y * squeeze, point.z),
                     freq + cloudsLayer, cellCenter);
    rnd = hash1(cell.x);
    r = size * cell.y;

    if ((rnd < dens)) {
      dir = sign(0.7 * dens - rnd);
      dist = saturate(1.0 - r);
      dist2 = saturate(0.3 - r);
      fi = pow(dist, strength) * (exp(-6.0 * dist2) + 0.5);
      twistedPoint =
          Rotate(cycloneMagn * dir * sign(cellCenter.y + 0.001) * fi * 3.0,
                 cellCenter.xyz, point);
      offset += offs * fi * dir * 16.0;
    }

    freq = min(freq * 2.0, 6400.0);
    dens = min(dens * 3.5, 0.3);
    size = min(size * 1.5, 15.0);
    offs = offs * 0.5;
    squeeze = max(squeeze - 0.3, 1.0);
    strength = max(strength * 1.3, 0.5);
    point = twistedPoint;
  }

  return offset;
}

//-----------------------------------------------------------------------------

void main() {
  float _stripeFluct = 0.3 + stripeFluct * 1.2;

  // GlobalModifier // Convert height to color
  vec3 point = GetSurfacePoint();
  float height = 0.0;
  float slope = 0.0;
  GetSurfaceHeightAndSlope(height, slope);
  // Don't go crazy with stripeFluct on venuslikes.
  float gaseousBuff = volcanoActivity != 0.0 ? 1.0 : 4.0;
  float isMini = smoothstep(0.09, 1.0, cloudsFreq);
  OutColor = _GetGasGiantCloudsColor(height - 0.5 * _stripeFluct * 0.0666666 *
                                                  gaseousBuff);
  OutColor = rgb_to_lch(OutColor);
  vec4 cycloneColor =
      texture(BiomeDataTable, vec2(1.0, 0.0)); // always the first cloud layer
  OutColor.rgb = mix(OutColor.rgb, rgb_to_lch(cycloneColor).rgb,
                     saturate(abs(CycloneColorGasGiantAli(point))));
  OutColor.r = OutColor.r * min(height, 0.5) + 50.0;
  OutColor.g *= 1.25;
  OutColor = lch_to_rgb(OutColor);

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    OutColor.a = 0.0;
  }

  if (volcanoActivity != 0.0) {
    float latitude = abs(point.y);
    // Drown out poles
    OutColor.rgb = mix(GetGasGiantCloudsColor(abs(Randomize.x) * 0.1666667 +
                                              abs(Randomize.y) * 0.1666667 +
                                              abs(Randomize.z) * 0.1666667)
                           .rgb,
                       OutColor.rgb, 1.0 - vec3(saturate(latitude - 0.1)));
  }

  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif