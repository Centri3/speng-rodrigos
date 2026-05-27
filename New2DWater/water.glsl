#auto_version

//===========================================================================//
//                                                                           //
//              SpaceEngine water surface rendering shader                   //
//                                                                           //
//===========================================================================//

// Defines passed from SpaceEngine. Possible defines:
// Effects:           	RINGS, ECL, ATMO, VSDBL, PLANEMO
// Debug:               SQT
// Vendor-specific:     INTEL, LOGVS, LOGFS
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

//===========================================================================//
//                                                                           //
//                            Texture samplers                               //
//                                                                           //
//===========================================================================//

#ifdef ATMO
/*  0 */ uniform sampler2D irradianceSampler;    // precomputed skylight irradiance (E table)
/*  1 */ uniform sampler2D transmittanceSampler; // precomputed transmittance (T table)
/*  2 */ uniform sampler3D inscatterSampler;     // precomputed inscattered light (S table)
#endif

#ifdef RINGS
/*  3 */ uniform sampler2D RingsMap;
#endif

/*  4 */ uniform sampler2D NoiseMap;

//===========================================================================//
//                                                                           //
//                                Uniforms                                   //
//                                                                           //
//===========================================================================//

//#ifdef ATMO
//uniform vec4    AtmoParams1;    // density, scattering bright, skylight bright, exposure
//uniform vec4    AtmoParams2;    // MieG, MieFade, HR, HM
//uniform vec4    AtmoParams3;    // planet_radius^2, atmoH^2, atmoH, mieG^2
//uniform vec3    AtmoRayleigh;   // betaR
//uniform vec3    AtmoMieExt;     // betaMExt
//uniform vec2    AtmoColAdjust;  // hsl color adjust
//#endif
//
//uniform vec4    Radiuses;       // atmosphere bottom radius, atmosphere top radius, atmosphere height, surface radius
//uniform vec4    NodeCenter;     // node center offset, heightmap scale
//uniform ivec4   VSFetchParams;  // uIndex, vIndex, nTiles, mode
//uniform mat3x3  FaceRotation;   // terrain cube face oreintation
//uniform mat4x4  ModelViewProj;  // modelview * projection matrix
//
//uniform int     NLights;                 // lights count
//uniform vec3    LightPos   [MAX_LIGHTS]; // Object-space light position
//uniform vec3    LightColor [MAX_LIGHTS]; // Light color
//uniform vec3    LightParams[MAX_LIGHTS]; // Light radius, light luminosity, light specular power
//
//#ifdef ECL  
//uniform vec4    EclipseCasters[MAX_LIGHTS * MAX_ECLIPSES];
//#endif
//
//uniform vec4    AmbientColor;   // Ambient color, eclipse shadow intensity
//uniform vec4    GlowColor;      // Glow color, glow mode
//uniform vec4    WaterSurfColor; // Water surface diffuse color, water on/off animation
//uniform vec4    WaterFogColor;  // Underwater absorption RGB, underwater absorption global
//uniform vec4    EyePos;         // Object-space camera position, minEyeMu
//uniform vec4    EyePosLocal;    // Object-space camera position relative to the node center, surface radius
//uniform vec4    SpecParams;     // ice specular bright, water specular bright, ice specular power, water specular power
//uniform vec4    SurfParams1;    // eclipse shadow mask, horizon fake fresnel raise, Hapke to Lambert coefficient, isEarthSpecMap
//uniform vec4    SurfParams2;    // heightmap scale, day ambient coefficient, subsurface scattering brightness, subsurface scattering power
//uniform vec4    SurfParams3;    // face, detail texture frequency x/y, animation time
//uniform vec4    SurfParams4;    // city lights cutoff brightness, night light brightness, perm light brightness, ---
//uniform vec4    SurfParams5;    // surface brightness calibration, water brightness calibration, ambient brightness calibration, ---
//uniform vec4    RingsParams;    // rings inner radius, rings outer radius, rings density, rings inv width
//uniform vec4    WaterParams;    // water depth, water layer radius, inv water fade height, water horizon opacity
//uniform vec4    EllipsGrav;     // planet ellipsoid oblateness, ellipsoid gravity coefficient
//
//#ifdef SQT
//uniform vec4   NodeColor;       // grid color for octree node visualization
//#endif
//
//#if (defined(LOGFS) || defined(LOGVS))
//uniform float  LogZParams;      // logFactor
//#endif

#uniform_block

//===========================================================================//
//                                                                           //
//           Variables, shared with the atmospheric scattering code          //
//                                                                           //
//===========================================================================//

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
const vec3  FaceBitangent = vec3(0.0, 0.01, 0.0); // step vector mask to compute tangents

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

//===========================================================================//
//                                                                           //
//                             Vertex shader                                 //
//                                                                           //
//===========================================================================//

#ifdef _VERTEX_

// Vertex shader input
layout(location = 0) in  vec3  vTexCoord;

// Vertex shader output
out vec4 fPosition;
out vec3 fPositionLocal;
out vec3 fTangent;
out vec2 fWavesTexCoord;
out float fWaveHeight;

//-----------------------------------------------------------------------------

void    SphereVertexCoordF(out vec3 pos, out vec3 tangent)
{
    vec2 uv = vec2(pi05) - vec2(pi2, pi) * vTexCoord.xy;

    // compute position
    float sinu = sin(uv.x);
    float cosu = cos(uv.x);
    float sinv = sin(uv.y);
    float cosv = cos(uv.y);
    pos.x = cosv * cosu;
    pos.y = sinv;
    pos.z = cosv * sinu;

    // compute tangent vector
    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

//-----------------------------------------------------------------------------

void    SphereSegmentVertexCoordF(out vec3 pos, out vec3 tangent)
{
    float size2 = 2.0 / float(VSFetchParams.z);
    vec2  uv = vec2(vTexCoord.x, 1.0 - vTexCoord.y);

    // compute node offset with high precision
    vec2  offs  = vec2(VSFetchParams.xy) * size2 - 1.0;

    // compute position
    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    // compute tangent vector
    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    pos       = normalize(pos);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

//-----------------------------------------------------------------------------

void    SphereSegmentVertexCoordD(out dvec3 pos, out dvec3 tangent)
{
    double size2 = 2.0 / double(VSFetchParams.z);
    dvec2  uv = dvec2(vTexCoord.x, 1.0 - vTexCoord.y);

    // compute node offset with high precision
    dvec2  offs  = dvec2(VSFetchParams.xy) * size2 - 1.0;

    // compute position
    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    // compute tangent vector
    dvec3 pos0 = normalize(pos - FaceBitangent);
    dvec3 pos1 = normalize(pos + FaceBitangent);
    pos        = normalize(pos);
    tangent    = pos0 - pos1;
    tangent    = tangent - dot(tangent, pos) * pos;

    if (dot(tangent, pos) != 0)
        tangent = normalize(tangent);
}

//=============================================================================
// Vertex shader entry point

void main()
{
    // Transfer the detail texture coordinates
    fWavesTexCoord = vTexCoord.xy;

    // Perform calcultations in double precision only for fine levels
    #ifdef VSDBL

        // Calculate the vertex position on the planet sphere and tangent space vector
        dvec3 dvPosition, dvTangent;
        SphereSegmentVertexCoordD(dvPosition, dvTangent);
        dvec3 dvPosLocal = dvPosition - dvec3(NodeCenter.xyz);
        fPosition.xyz    = vec3(dvPosition);
        fPositionLocal   = vec3(dvPosLocal * double(EyePosLocal.w));
        fTangent         = vec3(dvTangent);

        // Calculate the output position
        gl_Position = ModelViewProj * vec4(dvPosLocal, 1.0);

    #else

        // Calculate the vertex position on the planet sphere and tangent space vector
        if (VSFetchParams.w < 0.0)
            SphereVertexCoordF(fPosition.xyz, fTangent);        // base level (sphere)
        else
            SphereSegmentVertexCoordF(fPosition.xyz, fTangent); // other levels (spherical quadreee patch)
        vec3 fvPosLocal = fPosition.xyz - NodeCenter.xyz;
        fPositionLocal  = vec3(fvPosLocal * EyePosLocal.w);

        // Calculate the output position
        gl_Position = ModelViewProj * vec4(fvPosLocal, 1.0);

    #endif


    // Logarithmic depth buffer:
    // calculate the per-vertex logarithmic depth value in vertex shader (LOGVS mode),
    // or transfer it to the fragment shader for further per-fragment calculation (LOGFS mode)
	#ifdef LOGVS
        gl_Position.z = (log2(max(1.0e-6, 1.0 + gl_Position.w)) * LogZParams - 1.0) * gl_Position.w;
    #endif
	#ifdef LOGFS
        fPosition.w = gl_Position.z;
    #endif
}

#endif // _VERTEX_

//===========================================================================//
//                                                                           //
//                            Fragment shader                                //
//                                                                           //
//===========================================================================//

#ifdef _FRAGMENT_

in vec4 fPosition;
in vec3 fPositionLocal;
in vec3 fTangent;
in vec2 fWavesTexCoord;

#ifdef INTEL
out vec4 FragColor;
#else
layout(location = 0) out vec4 FragColor;
#endif

#ifdef LOGFS
layout(depth_less) out float gl_FragDepth;
#endif

// --- PURE MATH PROCEDURAL OCEAN ---
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx); 
}

float getProceduralOcean(vec2 position, int iterations, float phase) {
    float frequency = 1.0;
    float weight = 1.0;
    float sumOfValues = 0.0;
    float sumOfWeights = 0.0;
    
    // We will track the low-frequency "swell" shape to use as a mask
    float macroSwell = 0.0; 
    
    vec2 p = position;
    vec2 dir = vec2(0.7071, 0.7071); 
    mat2 rot = mat2(0.2756, -0.9612, 0.9612, 0.2756);
    
    for (int i = 0; i < iterations; i++) {
        float speed = 2.0 + float(i); 
        float timeshift = phase * pi2 * speed; 
        
        vec2 res = wavedx(p, dir, frequency, timeshift);
        
        // --- Modulation Layering ---
        float modulation = 1.0;
        
        // Once we pass the big waves (first 3 octaves), we start modulating
        if (i > 2) {
            // Remap the macroSwell height to a 0.2 to 1.0 range.
            // This ensures troughs stay glassy (0.2x intensity) and crests get choppy (1.0x intensity).
            modulation = clamp(macroSwell * 0.5 + 0.5, 0.2, 1.0); 
        }
        
        p += dir * res.y * weight * 0.25; 
        
        // Apply the modulation mask to the current octave's weight
        float currentWeight = weight * modulation;
        
        sumOfValues += res.x * currentWeight;
        sumOfWeights += currentWeight;
        
        // Build the macro shape mask using only the first 3 dominant octaves
        if (i < 3) {
            macroSwell += res.x * weight;
        }
        
        weight *= 0.8;
        frequency *= 1.35; 
        dir = rot * dir;
    }
    
    return sumOfValues / sumOfWeights;
}

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

    float wavesFade = clamp(2.0 - eyeVecLength * 0.1, 0.0, 1.0);
    wavesFade *= wavesFade;

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

    // --- PROCEDURAL NORMAL GENERATION ---
    float phase = 8*SurfParams3.w; // SpaceEngine's cyclic animation time [0, 1]
    float waveScale = 200.0; 
    vec2 baseUV = fWavesTexCoord * SurfParams3.yz * waveScale;

    // We calculate 12 octaves of pure math micro-detail directly at the base UV.
    // By eliminating the raymarching loop, we permanently solve the camera perspective warping.
    float e = 0.05; 
    float h  = getProceduralOcean(baseUV, 12, phase);
    float hX = getProceduralOcean(baseUV + vec2(e, 0.0), 12, phase);
    float hY = getProceduralOcean(baseUV + vec2(0.0, e), 12, phase);

    // Calculate tangent space normal from the height derivatives.
    vec3 wavesNormal = normalize(vec3(h - hX, h - hY, e * 2.5));

    // Apply the normal back to the Space Engine lighting pipeline
    vec3 normVec = normalize(wavesNormal * wavesFade + vec3(0.0, 0.0, 1.0));
    
    #if (defined(ATMO) && !defined(PLANEMO))
        float sqrtFragH = sqrt(FragH);
    #endif

    vec3 waterFogAccum = AmbientColor.rgb;
    float metallic  = 0.0;
    float specSea   = SpecParams.y;
    float roughSea  = SpecParams.w;
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
        float VdotL = clamp(-dot(lightVec, eyeVec), -0.999, 1.0);

        vec3 sunLightN = sunLightHorShadow * NdotL;
        vec3 sunLightW = sunLightHorShadow * NdotLSC;
        vec3 ambSeaTerm = LightColor[i].rgb * (NdotLSC * Shadow * SurfParams2.y);
        #ifdef ATMO
            vec3 skyIrrad = irradiance(FragH, NdotLS) * sunLight * Shadow * AtmoParams1.z;
            sunLightW  += skyIrrad;			  
            ambSeaTerm += skyIrrad;
        #endif

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
        float fresAlpha = clamp(0.02 + WaterParams.w * 0.98 * pow(1.0 - abs(dot(eyeVecTS, normVec)), 4), 0.0, 1.0);
        opacity = clamp(waterOpacity + fresAlpha, 0.0, 1.0);
        alpha = opacity * WaterSurfColor.a * waterFade3D;
        surfaceColor += (diffSeaAccum + ambSeaAccum) * alpha;
    #endif

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

#endif // _FRAGMENT_

//=============================================================================
