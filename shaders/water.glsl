#auto_version

// Lujo water shader

#auto_defines

#ifdef LOGFS
#extension GL_ARB_conservative_depth : enable
#endif

// Standard defines
#define MAX_LIGHTS   4
#define MAX_ECLIPSES 8

// Settings
#define ANALYTIC_TRANSM
#define HORIZON_FIX

#define SHADOW (defined(RINGS) || defined(ECL) || !defined(ATMO))

// Texture 

#ifdef ATMO
 uniform sampler2D irradianceSampler;
 uniform sampler2D transmittanceSampler;
 uniform sampler3D inscatterSampler;
#endif

#ifdef RINGS
 uniform sampler2D RingsMap;
#endif


// Uniforms

#uniform_block

// Variables, shared with the atmospheric scattering code

vec3  FragPos       = vec3(0.0,0.0,0.0);
float FragR         = 0.0;
float FragH         = 0.0;
float FragMu        = 0.0;
vec3  EyePosM       = vec3(0.0,0.0,0.0);
float EyeR          = 0.0;
float EyeH          = 0.0;
float EyeMu         = 0.0;
float EyeMuS        = 0.0;
float MieHorFade    = 0.0;
vec3  eyeVec        = vec3(0.0,0.0,0.0);
float eyeVecLength  = 0.0;
float HorizonMu     = 0.0;
float HorizonFixEps = 0.0;
vec3  Attenuation   = vec3(1.0,1.0,1.0);

const float pi   = 3.14159265359;
const float pi2  = pi * 2.0;
const float pi05 = pi * 0.5;
const vec3  FaceBitangent = vec3(0.0, 0.01, 0.0);

#include "hsl.glh"
#include "terrain_pbr.glh"

#ifdef RINGS
#define RINGS_SHADOW_CODE
#include "rings_common.glh"
#endif

#ifdef ATMO
#include "atmo_common.glh"
#endif

#ifdef ECL
#include "eclipse_common.glh"
#endif

// Wave model

#define OCEAN_DRAG_MULT             0.42

#define OCEAN_SPEED                 1.0       // DO NOT CHANGE THIS. NEVER EVER. IT WILL BREAK SEAM FIX. YOU CAN CHANGE OCEAN SPEED IN OCEAN_TIME_DIVISOR. ALWAYS BY FACOR OF 2.(8,16,32..)
#define OCEAN_PHASE_WRAP      1048576.0

#define OCEAN_TIME_DIVISOR         32.0

#define OCEAN_VERTEX_ITERATIONS     24
#define OCEAN_NORMAL_ITERATIONS     48
#define OCEAN_GEOM_COORD_SCALE      96.0
#define OCEAN_NORMAL_COORD_SCALE    40.0
#define OCEAN_DISPLACEMENT_KM       0.014
#define OCEAN_HEIGHT_CENTER         0.500
#define OCEAN_NORMAL_STRENGTH       3.00
#define OCEAN_NORMAL_EPS_KM         0.002
#define OCEAN_NORMAL_FADE_START_KM  60.0
#define OCEAN_NORMAL_FADE_END_KM    180.0

// FoAm

#define OCEAN_FOAM_ENABLE_CREST       1
#define OCEAN_FOAM_ENABLE_TRAILS      0

#define OCEAN_FOAM_CREST_START        0.54
#define OCEAN_FOAM_CREST_END          0.70
#define OCEAN_FOAM_SLOPE_START        0.08
#define OCEAN_FOAM_SLOPE_END          0.42
#define OCEAN_FOAM_CREST_AMOUNT       0.90

#define OCEAN_FOAM_HISTORY_ITERATIONS 5
#define OCEAN_FOAM_TRAIL_DELAY_1      0.0065
#define OCEAN_FOAM_TRAIL_DELAY_2      0.0135
#define OCEAN_FOAM_TRAIL_DELAY_3      0.0225
#define OCEAN_FOAM_TRAIL_DELAY_4      0.0340
#define OCEAN_FOAM_TRAIL_WEIGHT_1     0.82
#define OCEAN_FOAM_TRAIL_WEIGHT_2     0.62
#define OCEAN_FOAM_TRAIL_WEIGHT_3     0.42
#define OCEAN_FOAM_TRAIL_WEIGHT_4     0.24
#define OCEAN_FOAM_TRAIL_CREST_BIAS   0.065
#define OCEAN_FOAM_TRAIL_AMOUNT       0.80

#define OCEAN_FOAM_DETAIL_MIN         0.22
#define OCEAN_FOAM_DETAIL_MAX         0.72
#define OCEAN_FOAM_DISTANCE_START     15.0
#define OCEAN_FOAM_DISTANCE_END       90.0

#define OCEAN_FOAM_SPARSE_CREST_POWER   3.60

#define OCEAN_FOAM_SPARSE_SLOPE_POWER   1.60

#define OCEAN_FOAM_SPARSE_DETAIL_START  0.58
#define OCEAN_FOAM_SPARSE_DETAIL_END    0.86

#define OCEAN_FOAM_CREST_TIP_MIN        0.14

#define OCEAN_FOAM_BRIGHTNESS         0.72
#define OCEAN_FOAM_DARK_BRIGHTNESS    0.035
#define OCEAN_FOAM_LIGHT_COLOR_MIX    0.30
const vec3 OCEAN_FOAM_COLOR = vec3(0.78, 0.83, 0.86);

vec2 OceanWaveDx3D(vec3 position, vec3 direction, float frequency, float timeshift)
{
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

vec3 OceanMacroWarp3D(vec3 p)
{
    vec3 q = p * 0.0043;

    float wx = sin(dot(q, vec3( 0.91,  1.37, -0.73)) + 1.41)
             + sin(dot(q, vec3(-1.17,  0.61,  1.09)) - 2.13);
    float wy = sin(dot(q, vec3(-0.67,  1.11,  1.43)) + 2.71)
             + sin(dot(q, vec3( 1.29, -0.83,  0.57)) + 0.37);
    float wz = sin(dot(q, vec3( 1.41,  0.53,  0.89)) - 1.07)
             + sin(dot(q, vec3(-0.79, -1.31,  0.71)) + 2.29);

    return vec3(wx, wy, wz) * 11.0;
}

float GetFastOceanWaves3D(vec3 position, int iterations, float cyclicTime)
{
    position += OceanMacroWarp3D(position);

    float wavePhaseShift = length(position) * 0.073
                         + dot(position, vec3(0.0137, 0.0211, -0.0173));
    float iter = 0.0;
    float frequency = 1.0;
    float weight = 1.0;
    float sumOfValues = 0.0;
    float sumOfWeights = 0.0;
    float loopPhase = cyclicTime * pi2 * 24.0;

    for (int i = 0; i < iterations; i++)
    {
        float fi = float(i);

        vec3 dir = normalize(vec3(
            sin(iter + fi * 0.37),
            cos(iter * 0.971 + fi * 0.19),
            sin(iter * 0.731 + 1.337 + fi * 0.53)
        ));

        float octavePhase = fract(sin(fi * 91.345 + 17.17) * 47453.5453) * pi2;

        float timeMultiplier = 2.0 + float(i / 3);
        vec2 res = OceanWaveDx3D(position, dir, frequency,
                                 loopPhase * timeMultiplier
                               + wavePhaseShift + octavePhase);

        position += dir * res.y * weight * OCEAN_DRAG_MULT;

        sumOfValues += res.x * weight;
        sumOfWeights += weight;

        weight *= 0.8;

        frequency *= 1.16 + 0.035 * fract(sin(fi * 37.11 + 4.7) * 15731.743);
        iter += 1232.399963;
    }

    return sumOfValues / max(sumOfWeights, 1.0e-6);
}

float GetOceanDisplacementKm(vec3 sphereDir, float radiusKm, float cyclicTime)
{

    vec3 wavePos = sphereDir * radiusKm * OCEAN_GEOM_COORD_SCALE;
    float h = GetFastOceanWaves3D(wavePos, OCEAN_VERTEX_ITERATIONS, cyclicTime);
    return (h - OCEAN_HEIGHT_CENTER) * OCEAN_DISPLACEMENT_KM;
}

// seam fix (please god let this one work)

vec3 OceanPlanetDirFromTexCoord(vec2 texCoord)
{
    float nTiles = max(float(VSFetchParams.z), 1.0);
    float size2  = 2.0 / nTiles;
    vec2 uv      = vec2(texCoord.x, 1.0 - texCoord.y);
    vec2 offs    = vec2(VSFetchParams.xy) * size2 - 1.0;
    vec3 cube    = vec3(offs + uv * size2, 1.0);
    return normalize(FaceRotation * normalize(cube));
}

float OceanGlobalPhase()
{
    float nTiles = max(float(VSFetchParams.z), 1.0);
    float cycles = max(floor(OCEAN_PHASE_WRAP / nTiles + 0.5), 1.0);

    float commonClock = SurfParams3.w * cycles * OCEAN_SPEED;

    return fract(commonClock / OCEAN_TIME_DIVISOR);
}

// Vertex shader

#ifdef _VERTEX_

layout(location = 0) in  vec3  vTexCoord;

out vec4 fPosition;
out vec3 fPositionLocal;
out vec3 fTangent;
out vec2 fWavesTexCoord;
out float fWaveHeight;

void    SphereVertexCoordF(out vec3 pos, out vec3 tangent)
{
    vec2 uv = vec2(pi05) - vec2(pi2, pi) * vTexCoord.xy;

    float sinu = sin(uv.x);
    float cosu = cos(uv.x);
    float sinv = sin(uv.y);
    float cosv = cos(uv.y);
    pos.x = cosv * cosu;
    pos.y = sinv;
    pos.z = cosv * sinu;

    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

void    SphereSegmentVertexCoordF(out vec3 pos, out vec3 tangent)
{
    float size2 = 2.0 / float(VSFetchParams.z);
    vec2  uv = vec2(vTexCoord.x, 1.0 - vTexCoord.y);

    vec2  offs  = vec2(VSFetchParams.xy) * size2 - 1.0;

    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    pos       = normalize(pos);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

void    SphereSegmentVertexCoordD(out dvec3 pos, out dvec3 tangent)
{
    double size2 = 2.0 / double(VSFetchParams.z);
    dvec2  uv = dvec2(vTexCoord.x, 1.0 - vTexCoord.y);

    dvec2  offs  = dvec2(VSFetchParams.xy) * size2 - 1.0;

    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    dvec3 pos0 = normalize(pos - FaceBitangent);
    dvec3 pos1 = normalize(pos + FaceBitangent);
    pos        = normalize(pos);
    tangent    = pos0 - pos1;
    tangent    = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

void main()
{

    fWavesTexCoord = vTexCoord.xy;
    fWaveHeight = 0.0;

    float oceanPhase = OceanGlobalPhase();

    #ifdef VSDBL

        dvec3 dvPosition, dvTangent;
        SphereSegmentVertexCoordD(dvPosition, dvTangent);

        vec3 waveSphereDir = OceanPlanetDirFromTexCoord(vTexCoord.xy);
        float displacementKm = GetOceanDisplacementKm(waveSphereDir,
                                                       EyePosLocal.w,
                                                       oceanPhase);
        double radialScale = 1.0 + double(displacementKm / max(EyePosLocal.w, 1.0e-6));
        dvPosition *= radialScale;

        dvec3 dvPosLocal = dvPosition - dvec3(NodeCenter.xyz);
        fPosition.xyz  = vec3(dvPosition);
        fPositionLocal = vec3(dvPosLocal * double(EyePosLocal.w));
        fTangent       = vec3(dvTangent);
        fWaveHeight    = displacementKm;

        gl_Position = ModelViewProj * vec4(dvPosLocal, 1.0);

    #else

        if (VSFetchParams.w < 0.0)
            SphereVertexCoordF(fPosition.xyz, fTangent);
        else
            SphereSegmentVertexCoordF(fPosition.xyz, fTangent);

        vec3 baseSphereDir = normalize(fPosition.xyz);

        vec3 waveSphereDir = (VSFetchParams.w >= 0.0)
            ? OceanPlanetDirFromTexCoord(vTexCoord.xy)
            : normalize(FaceRotation * baseSphereDir);

        float displacementKm = GetOceanDisplacementKm(waveSphereDir,
                                                       EyePosLocal.w,
                                                       oceanPhase);
        fPosition.xyz = baseSphereDir
                      * (1.0 + displacementKm / max(EyePosLocal.w, 1.0e-6));

        vec3 fvPosLocal = fPosition.xyz - NodeCenter.xyz;
        fPositionLocal = fvPosLocal * EyePosLocal.w;
        fWaveHeight = displacementKm;

        gl_Position = ModelViewProj * vec4(fvPosLocal, 1.0);

    #endif

    #ifdef LOGVS
        gl_Position.z = (log2(max(1.0e-6, 1.0 + gl_Position.w)) * LogZParams - 1.0) * gl_Position.w;
    #endif
    #ifdef LOGFS
        fPosition.w = gl_Position.z;
    #endif
}
#endif

// Fragment shader

#ifdef _FRAGMENT_

in vec4 fPosition;
in vec3 fPositionLocal;
in vec3 fTangent;
in vec2 fWavesTexCoord;
in float fWaveHeight;

#ifdef INTEL
out vec4 FragColor;
#else
layout(location = 0) out vec4 FragColor;
#endif

#ifdef LOGFS
layout(depth_less) out float gl_FragDepth;
#endif

void main()
{
    #ifdef LOGFS
        gl_FragDepth = log2(1.0 + fPosition.w) * LogZParams;
    #endif

    vec3  Normal  = normalize(fPosition.xyz);
    FragR   = Radiuses.w;
    FragPos = Normal * FragR;
    eyeVec  = FragPos - EyePos.xyz;
    eyeVecLength = length(eyeVec);

    if (eyeVecLength < 50.0)
    {
        float t = smoothstep(2.0, 50.0, eyeVecLength);
        vec3  FragPosP = fPositionLocal + NodeCenter.xyz * EyePosLocal.w;
        vec3  eyeVecP  = fPositionLocal - EyePosLocal.xyz;
        float FragRP   = length(FragPosP);
        FragPos = mix(FragPosP, FragPos, t);
        eyeVec  = mix(eyeVecP,  eyeVec,  t);
        FragR   = mix(FragRP,   FragR,   t);
        eyeVecLength = length(eyeVec);
    }

    float waterFade3D = eyeVecLength * WaterParams.z - 1.0;
    if (waterFade3D > 1.0) discard;
    waterFade3D = clamp(waterFade3D, 0.0, 1.0);
    #ifdef WATER_HARD_TRANSITION
        waterFade3D = step(1.0, waterFade3D);
    #endif
    waterFade3D = 1.0 - waterFade3D;

    vec3  Tangent = normalize(fTangent);
    mat3x3 Rotation = mat3x3(Tangent, cross(Tangent, Normal), Normal);
    #ifdef ECL
        vec3  FragPosS = FragPos * EllipsGrav.xyz;
    #endif

    eyeVec /= eyeVecLength;

    #ifdef ATMO
        FragH  = 0.0;
        FragMu = dot(FragPos, eyeVec) / FragR;
        EyeR   = length(EyePos.xyz);
        EyeH   = (EyeR - Radiuses.x) / Radiuses.z;
        EyeMu  = dot(EyePos.xyz, eyeVec) / EyeR;
        EyePosM = EyePos.xyz;
        float d = -EyeR * EyeMu - sqrt(max(EyeR * EyeR * (EyeMu * EyeMu - 1.0) + Radiuses.y * Radiuses.y, 0.0));
        if (d > 0.0)
        {
            EyePosM += d * eyeVec;
            eyeVecLength -= d;
            EyeMu = (EyeR * EyeMu + d) / Radiuses.y;
            EyeR = Radiuses.y;
            EyeH = 1.0;
        }
    #else
        EyeR = length(EyePos.xyz);
    #endif

    bool  isAboveWater = (EyeR > WaterParams.y);
    float underWaterDist = isAboveWater ? 0.0f : eyeVecLength;
    vec4  waterAttenuation = clamp(exp(-underWaterDist * WaterFogColor), 0.0, 1.0);
    float waterOpacity     = 1 - waterAttenuation.a;

    vec3 eyeVecTS = eyeVec * Rotation;

// proc ocean nrmals

    float oceanNormalFade = 1.0 - smoothstep(OCEAN_NORMAL_FADE_START_KM,
                                              OCEAN_NORMAL_FADE_END_KM,
                                              eyeVecLength);
    oceanNormalFade *= oceanNormalFade;

    vec3 normVec = vec3(0.0, 0.0, 1.0);
    float oceanDetailHeight = OCEAN_HEIGHT_CENTER;
    float oceanSlopeMagnitude = 0.0;

    float oceanPhase = OceanGlobalPhase();

    if (oceanNormalFade > 1.0e-4)
    {
        vec3 Bitangent = normalize(cross(Tangent, Normal));

        vec3 waveNormal = (VSFetchParams.w >= 0.0)
            ? OceanPlanetDirFromTexCoord(fWavesTexCoord)
            : normalize(FaceRotation * Normal);
        vec3 waveTangent   = normalize(FaceRotation * Tangent);
        vec3 waveBitangent = normalize(FaceRotation * Bitangent);
        vec3 wavePos = waveNormal * FragR * OCEAN_NORMAL_COORD_SCALE;
        float sampleStep = OCEAN_NORMAL_EPS_KM * OCEAN_NORMAL_COORD_SCALE;

        float h0 = GetFastOceanWaves3D(wavePos,
                                       OCEAN_NORMAL_ITERATIONS,
                                       oceanPhase);
        float hT = GetFastOceanWaves3D(wavePos + waveTangent * sampleStep,
                                       OCEAN_NORMAL_ITERATIONS,
                                       oceanPhase);
        float hB = GetFastOceanWaves3D(wavePos + waveBitangent * sampleStep,
                                       OCEAN_NORMAL_ITERATIONS,
                                       oceanPhase);

        float slopeT = (hT - h0) * OCEAN_DISPLACEMENT_KM
                     / OCEAN_NORMAL_EPS_KM;
        float slopeB = (hB - h0) * OCEAN_DISPLACEMENT_KM
                     / OCEAN_NORMAL_EPS_KM;

        oceanDetailHeight = h0;
        oceanSlopeMagnitude = length(vec2(slopeT, slopeB));

        vec3 oceanNormalTS = normalize(vec3(-slopeT * OCEAN_NORMAL_STRENGTH,
                                             -slopeB * OCEAN_NORMAL_STRENGTH,
                                              1.0));
        normVec = normalize(mix(vec3(0.0, 0.0, 1.0),
                                oceanNormalTS,
                                oceanNormalFade));
    }

    #if (defined(ATMO) && !defined(PLANEMO))
        float sqrtFragH = sqrt(FragH);
    #endif

    vec3 waterFogAccum = AmbientColor.rgb;
    float metallic  = 0.0;
    float specSea   = max(SpecParams.y, 1.0);

    float roughSea  = clamp(SpecParams.w * 0.30, 0.020, 0.070);
    float aoSea     = 1.0;
    #ifdef ATMO
        #ifdef ANALYTIC_TRANSM
            Attenuation = transmittanceAnalytic(EyeR, max(EyeMu, EyePos.w), eyeVecLength);
        #else
            Attenuation = transmittance(sqrt(EyeH), EyeMu, sqrtFragH, FragMu);
        #endif

        #ifndef PLANEMO
            bool atmoHorFix = false;
            #ifdef HORIZON_FIX
                float invR = Radiuses.x / EyeR;
                HorizonMu = -sqrt(1.0 - invR * invR);
                HorizonFixEps = AtmoParams1.w;
                atmoHorFix = abs(EyeMu - HorizonMu) < HorizonFixEps;
            #endif
            vec3 Inscatter = vec3(0.0);
        #endif
    #endif

    float NdotV = clamp(-dot(normVec, eyeVecTS), 0.0, 1.0);
    vec3  diffSeaAccum = vec3(0.0);
    vec3  specSeaAccum = vec3(0.0);
    vec3  ambSeaAccum  = AmbientColor.rgb * WaterSurfColor.rgb;
    vec3  foamLightAccum = AmbientColor.rgb * 0.30;
    float EclipseMask  = 1.0;
    for (int i=0; i<NLights; i++)
    {
        vec3 lightPos = LightPos[i] - FragPos;
        vec3 lightVec = normalize(lightPos);
        vec3 lightVecTS = lightVec * Rotation;
        float NdotLS  = dot(Normal, lightVec);
        float NdotLSC = clamp(NdotLS, 0.0, 1.0);

	    #ifdef ECL
			vec3  lightPosEll = lightPos * EllipsGrav.xyz;
            float invLightDist = inversesqrt(dot(lightPosEll, lightPosEll));
        #endif

        #ifdef ATMO
            EyeMuS = dot(EyePosM, lightVec) / EyeR;
            MieHorFade = smoothstep(0.0, AtmoParams2.y, EyeMuS);
        #endif

        float Shadow = 1.0;
        #if (SHADOW && !defined(PLANEMO))
            #ifdef RINGS
                vec2  shadowProj;
                float cosPhi;
                if (SurfParams3.x == 0.0)
                {
                    shadowProj = (fPosition.xz - lightPos.xz * min(fPosition.y / lightPos.y, 0.0)) * EllipsGrav.xz;
                    cosPhi = abs(lightVec.y);
                }
                else
                {
                    shadowProj = (fPosition.xy - lightPos.xy * min(fPosition.z / lightPos.z, 0.0)) * EllipsGrav.xy;
                    cosPhi = abs(lightVec.z);
                }
                float texU = (length(shadowProj) * EyePosLocal.w - RingsParams.x) * RingsParams.w;
                Shadow *= RingsShadow(texU, cosPhi);
            #endif
            #ifdef ECL
				float lightAngularRadius = asin(clamp(LightParams[i].x * invLightDist, 0.0, 1.0));
                float eclipse = EclipseShadowFar(i, MAX_ECLIPSES, FragPosS, lightPosEll * invLightDist, lightAngularRadius);
                Shadow *= 1.0 - AmbientColor.a * eclipse;
                eclipse *= step(0.0, dot(lightPosEll, FragPosS));
                EclipseMask *= 1.0 - eclipse;
            #endif
        #endif

        float HorShadow = clamp(NdotLS * 500.0, 0.0, 1.0);
        vec3  sunLight = LightColor[i].rgb * Shadow;
        vec3 sunLightHorShadow = sunLight * HorShadow;
        #ifdef ATMO
            sunLightHorShadow *= transmittanceDens(sqrtFragH, NdotLS);
        #endif

        float NdotL = clamp(dot(normVec, lightVecTS), 0.0, 1.0);
        vec3 sunLightN = sunLightHorShadow * NdotL;
        vec3 sunLightW = sunLightHorShadow * NdotLSC;
        vec3 ambSeaTerm = LightColor[i].rgb * (NdotLSC * Shadow * SurfParams2.y);
        #ifdef ATMO
            vec3 skyIrrad = irradiance(FragH, NdotLS) * sunLight * Shadow * AtmoParams1.z;
            sunLightW  += skyIrrad;
            ambSeaTerm += skyIrrad;
        #endif

        foamLightAccum += sunLightW * (0.25 + 0.75 * NdotL);

        waterFogAccum += sunLightW;
        vec3  diffSeaTerm = vec3(0.0);
        vec3  specSeaTerm = vec3(0.0);
        CookTorranceBRDF(normVec, eyeVecTS, lightVecTS, NdotV, NdotL,
            WaterSurfColor.rgb, roughSea, aoSea, metallic,
            diffSeaTerm, specSeaTerm);
        ambSeaAccum  += ambSeaTerm;
        diffSeaAccum += diffSeaTerm * sunLightN;
        specSeaAccum += specSeaTerm * sunLightN;
        #ifdef ATMO
            if (atmoHorFix)
                Inscatter += inscatterGroundFix(lightVec) * sunLight;
            else
                Inscatter += inscatterGround(lightVec) * sunLight;
        #endif
    }

    ambSeaAccum *= WaterSurfColor.rgb;
    diffSeaAccum *= SurfParams5.x;
    specSeaAccum *= SurfParams5.x * specSea;
    ambSeaAccum  *= SurfParams5.z;

    waterFogAccum *= WaterSurfColor.rgb * SurfParams5.y;
    diffSeaAccum = mix(diffSeaAccum * waterAttenuation.rgb, waterFogAccum, waterOpacity);
    specSeaAccum = mix(specSeaAccum * waterAttenuation.rgb, vec3(0.0),     waterOpacity);
    ambSeaAccum  = mix(ambSeaAccum  * waterAttenuation.rgb, vec3(0.0),     waterOpacity);

    vec3  surfaceColor = specSeaAccum * waterFade3D;
    float opacity = 0.0;
    float alpha = 0.0;
    #ifndef WATER_SPECULAR_ONLY
        float fresAlpha = clamp(0.02 + WaterParams.w * 0.98
                              * pow(1.0 - abs(dot(eyeVecTS, normVec)), 5.0),
                                0.0, 1.0);
        opacity = clamp(waterOpacity + fresAlpha, 0.0, 1.0);
        alpha = clamp(opacity * WaterSurfColor.a * waterFade3D + 0.12, 0.0, 1.0);
        surfaceColor += (diffSeaAccum + ambSeaAccum) * alpha;

        vec3 targetScatter = vec3(0.0293, 0.0698, 0.1717);
        vec3 scatterColor = mix(WaterSurfColor.rgb, targetScatter, 0.45);
        float scatterAmount = (1.0 - fresAlpha) * 0.10
                            * (isAboveWater ? 1.0 : 0.0) * waterFade3D;
        surfaceColor += scatterColor * scatterAmount;
    #endif

// Proc foam setting

    float broadWaveHeight = clamp(fWaveHeight / max(OCEAN_DISPLACEMENT_KM, 1.0e-6)
                                  + OCEAN_HEIGHT_CENTER, 0.0, 1.0);
    float foamCrest = smoothstep(OCEAN_FOAM_CREST_START,
                                 OCEAN_FOAM_CREST_END,
                                 broadWaveHeight);

    float foamSlope = smoothstep(OCEAN_FOAM_SLOPE_START,
                                 OCEAN_FOAM_SLOPE_END,
                                 oceanSlopeMagnitude);

    float sparseCrest = pow(clamp(foamCrest, 0.0, 1.0),
                            OCEAN_FOAM_SPARSE_CREST_POWER);

    float breakingGate = pow(clamp(foamSlope, 0.0, 1.0),
                             OCEAN_FOAM_SPARSE_SLOPE_POWER);
    breakingGate = OCEAN_FOAM_CREST_TIP_MIN
                 + (1.0 - OCEAN_FOAM_CREST_TIP_MIN) * breakingGate;

    float freshFoam = sparseCrest * breakingGate
                    * OCEAN_FOAM_CREST_AMOUNT;

    float foamDetail = smoothstep(OCEAN_FOAM_DETAIL_MIN,
                                  OCEAN_FOAM_DETAIL_MAX,
                                  oceanDetailHeight);
    foamDetail = smoothstep(OCEAN_FOAM_SPARSE_DETAIL_START,
                            OCEAN_FOAM_SPARSE_DETAIL_END,
                            foamDetail);

    float trailFoam = 0.0;
    #if OCEAN_FOAM_ENABLE_TRAILS
        vec3 foamWaveNormal = (VSFetchParams.w >= 0.0)
            ? OceanPlanetDirFromTexCoord(fWavesTexCoord)
            : normalize(FaceRotation * Normal);
        vec3 foamWavePos = foamWaveNormal * FragR * OCEAN_GEOM_COORD_SCALE;

        float t1 = fract(oceanPhase - OCEAN_FOAM_TRAIL_DELAY_1 + 1.0);
        float t2 = fract(oceanPhase - OCEAN_FOAM_TRAIL_DELAY_2 + 1.0);
        float t3 = fract(oceanPhase - OCEAN_FOAM_TRAIL_DELAY_3 + 1.0);
        float t4 = fract(oceanPhase - OCEAN_FOAM_TRAIL_DELAY_4 + 1.0);

        float oldH1 = GetFastOceanWaves3D(foamWavePos, OCEAN_FOAM_HISTORY_ITERATIONS, t1);
        float oldH2 = GetFastOceanWaves3D(foamWavePos, OCEAN_FOAM_HISTORY_ITERATIONS, t2);
        float oldH3 = GetFastOceanWaves3D(foamWavePos, OCEAN_FOAM_HISTORY_ITERATIONS, t3);
        float oldH4 = GetFastOceanWaves3D(foamWavePos, OCEAN_FOAM_HISTORY_ITERATIONS, t4);

        float histStart = OCEAN_FOAM_CREST_START - OCEAN_FOAM_TRAIL_CREST_BIAS;
        float histEnd   = OCEAN_FOAM_CREST_END   - OCEAN_FOAM_TRAIL_CREST_BIAS;
        float trail1 = smoothstep(histStart, histEnd, oldH1) * OCEAN_FOAM_TRAIL_WEIGHT_1;
        float trail2 = smoothstep(histStart, histEnd, oldH2) * OCEAN_FOAM_TRAIL_WEIGHT_2;
        float trail3 = smoothstep(histStart, histEnd, oldH3) * OCEAN_FOAM_TRAIL_WEIGHT_3;
        float trail4 = smoothstep(histStart, histEnd, oldH4) * OCEAN_FOAM_TRAIL_WEIGHT_4;

        trailFoam = max(max(trail1, trail2), max(trail3, trail4));

        trailFoam *= (1.0 - 0.35 * foamCrest) * OCEAN_FOAM_TRAIL_AMOUNT;
    #endif

    float crestLayer = 0.0;
    #if OCEAN_FOAM_ENABLE_CREST
        crestLayer = freshFoam;
    #endif


    float foamDistanceFade = 1.0 - smoothstep(OCEAN_FOAM_DISTANCE_START,
                                               OCEAN_FOAM_DISTANCE_END,
                                               eyeVecLength);

    float foamMask = max(crestLayer, trailFoam);
    foamMask *= foamDetail * foamDistanceFade * waterFade3D
              * (isAboveWater ? 1.0 : 0.0);
    foamMask = clamp(foamMask, 0.0, 1.0);

    vec3 foamHDR = max(foamLightAccum, vec3(0.0));
    float foamHDRMax = max(foamHDR.r, max(foamHDR.g, foamHDR.b));

    float foamLightCompressed = foamHDRMax / (1.0 + foamHDRMax);

    vec3 foamLightTint = (foamHDRMax > 1.0e-6)
                       ? foamHDR / foamHDRMax
                       : vec3(1.0);
    foamLightTint = mix(vec3(1.0), foamLightTint, OCEAN_FOAM_LIGHT_COLOR_MIX);

    float foamBrightness = mix(OCEAN_FOAM_DARK_BRIGHTNESS,
                               OCEAN_FOAM_BRIGHTNESS,
                               foamLightCompressed);
    vec3 foamLitColor = OCEAN_FOAM_COLOR * foamLightTint * foamBrightness;

    surfaceColor = mix(surfaceColor, foamLitColor, foamMask);

    alpha = mix(alpha, WaterSurfColor.a * waterFade3D, foamMask);

    #ifdef ATMO
        surfaceColor *= Attenuation;
        #ifndef PLANEMO
            surfaceColor += Inscatter;
            surfaceColor -= Inscatter * (1.0 - alpha);
        #endif
    #endif

    FragColor.rgb = surfaceColor;
    FragColor.a = alpha;

    #if (SHADOW && !defined(PLANEMO))
        FragColor.b += SurfParams1.x * step(EclipseMask, 0.0);
    #endif

    float luma = max(FragColor.r, max(FragColor.g, FragColor.b));
    FragColor.rgb *= clamp(65000.0 / (luma + 1.0e-10), 0.0, 1.0);
    #ifdef SQT
        float tileEdge = 1.0 - smoothstep(0.5, 0.48, abs(0.5 - fWavesTexCoord.x)) * smoothstep(0.5, 0.48, abs(0.5 - fWavesTexCoord.y));
        FragColor.rgb = mix(FragColor.rgb, NodeColor.rgb, tileEdge);
    #endif
}

#endif
