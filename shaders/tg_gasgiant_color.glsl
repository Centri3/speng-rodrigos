#include "tg_rmr.glh"

#ifdef _FRAGMENT_

//-----------------------------------------------------------------------------

float CycloneColorGasGiantAli(vec3 point) {
  vec3 rotVec = normalize(Randomize);
  vec4 cell;
  vec3 v;
  float r, fi, rnd, dist, dist2, dir;
  float offset = 0.0;
  float offs = 0.5 / (cloudsLayer + 1.0);
  float strength = 10.0;
  float freq = cycloneFreq;
  float dens = cycloneDensity;
  float size = 1.5 * pow(cloudsLayer + 1.0, 5.0);

  for (int i = 0; i < cycloneOctaves; i++) {
    cell = _Cell2NoiseVec((point * freq), 0.6);
    v = cell.xyz - point;
    v.y *= 1.9;
    rnd = hash1(cell.x);

    if (rnd < dens) {
      dir = sign(0.5 * dens - rnd);
      dist = saturate(1.0 - length(v));
      dist2 = saturate(0.5 - length(v));
      fi = pow(dist, 20.0 * size) * (exp(-60.0 * dist2 * dist2) + 0.5);
      offset += offs * fi * dir * 0.7 * cycloneMagn;
    }

    freq = min(freq * 2.0, 6400.0);
    dens = min(dens * 3.5, 0.3);
    size = min(size * 1.5, 15.0);
    offs = offs * 0.5;
    strength = max(strength * 1.3, 0.5);
  }

  return offset;
}

float HeightMapFogGasGiant(vec3 point) {
  return 0.75 + 0.3 * Noise(point * vec3(0.2, stripeZones * 0.5, 0.2));
}

//-----------------------------------------------------------------------------

void main() {
  vec3 point = GetSurfacePoint();
  float height = GetSurfaceHeight();
  OutColor = _GetGasGiantCloudsColor(height);

  if (volcanoActivity != 0.0) {
    height = height / 3;
  }

  OutColor.rgb = (pow(OutColor.rgb, vec3(height * 3)));
  OutColor = rgb_to_lch(OutColor);
  vec4 cycloneColor =
      texture(BiomeDataTable, vec2(1.0, 0.0)); // always the first cloud layer
  OutColor.rgb = mix(OutColor.rgb, rgb_to_lch(cycloneColor).rgb,
                     saturate(abs(CycloneColorGasGiantAli(point))));
  OutColor = lch_to_rgb(OutColor);

  // GlobalModifier // Change cloud alpha channel
  // Changed lowest cloud layer to be full alpha // by Sp_ce
  if (cloudsLayer == 0) {
    // OutColor = GetGasGiantCloudsColor(height);
    OutColor.a = 1.0;
  } else {
    float height = HeightMapFogGasGiant(GetSurfacePoint());
    OutColor.rgb = height * _GetGasGiantCloudsColor(1.0).rgb;
    OutColor = rgb_to_lch(OutColor);
    OutColor.r *= height;
    OutColor.b += height * 20.0;
    OutColor = lch_to_rgb(OutColor);
    OutColor.a = 1.0;
  }
  /*
  if (volcanoActivity != 0.0) {   //polar suppression  uncomment for full Centri
  Venus-likes float latitude = abs(GetSurfacePoint().y);
      // Drown out poles
      OutColor.rgb = mix(GetGasGiantCloudsColor(0.0).rgb, OutColor.rgb,
                         1.0 - vec3(saturate(latitude - 0.3)));
    }
  */
  // GlobalModifier // Output color
  OutColor.rgb *= pow(OutColor.rgb, colorGamma);
}

//-----------------------------------------------------------------------------

#endif