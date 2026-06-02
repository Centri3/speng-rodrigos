#auto_version

//===========================================================================//
//                                                                           //
//            SpaceEngine planetary surface rendering shader                 //
//                                                                           //
//===========================================================================//

// Defines passed from SpaceEngine. Possible defines:
// Texture maps:          EMIS, THERM, DET, ACLOUDS, AWATER, AICE, COMPR
// Effects:               RINGS, ECL, ATMO, VSDBL, DISP
// Debug:               SQT
// Vendor-specific:     INTEL, LOGVS, LOGFS
#auto_defines

#extension GL_EXT_texture_array : enable

#ifdef LOGFS
#extension GL_ARB_conservative_depth : enable
#endif

// Standard defines
#define MAX_LIGHTS   4
#define MAX_ECLIPSES 8

// Settings
#define PLANCK_TEXTURE
#define ANALYTIC_TRANSM
#define HORIZON_FIX

// Texture tiling fix method:
// 0 - no tiling fix
// 1 - sampling texture several times at different scales
// 2 - voronoi random offset
// 3 - voronoi random offset and rotation
// 4 - iq's 2 lookup shuffle
#define TILING_FIX_MODE 4

// Normal maps blending methods:
// 0 - linear
// 1 - partial derivatives
// 2 - whiteout
// 3 - Unreal development network
// 4 - reoriented normal mapping
#define NORMALS_BLEND_METHOD 3

#define TILE_RES     256.0
#define HALF_TEXEL  (0.5 / TILE_RES)

// debug options
//#define SAMPLE_NEAREST
//#define PIXEL_GRID

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

/*  4 */ uniform sampler2D NoiseMapShuffle;

#ifdef THERM
/*  5 */ uniform sampler1D PlanckFunction;
#endif

//                                               // Compressed textures     Uncompressed textures
/*  6 */ uniform sampler2DArray HeightMapArray;  // height (R)              height (R)
/*  7 */ uniform sampler2DArray NormMapArray;    // normal (RG)             normal (RG)
/*  8 */ uniform sampler2DArray DiffMapArray;    // YCoCg color (RGB)       color (RGB), roughness (A)
/*  9 */ uniform sampler2DArray RoughMapArray;   // roughness  (R)          ---
/* 10 */ uniform sampler2DArray TempMapArray;    // temperatue (R)          temperatue (R)
/* 11 */ uniform sampler2DArray GlowMapArray;    // YCoCg emis color (RGB)  emis color (RGB)

#ifdef DET
/* 12 */ uniform sampler2DArray DetNormMapArray; // normal (RG)             normal (RG), roughness (B), ao (A)
/* 13 */ uniform sampler2DArray DetDiffMapArray; // YCoCg color (RGB)       color (RGB), height (A)
/* 14 */ uniform sampler2DArray DetRAOMapArray;  // roughness (R), ao (G)   ---
/* 15 */ uniform sampler2DArray DetBumpMapArray; // height (R)              ---
#endif

//===========================================================================//
//                                                                           //
//                                Uniforms                                   //
//                                                                           //
//===========================================================================//

#ifdef ATMO
//uniform vec4    AtmoParams1;    // density, scattering bright, skylight bright, HorizonFixEps
//uniform vec4    AtmoParams2;    // MieG, MieFade, HR, HM
//uniform vec4    AtmoParams3;    // planet_radius^2, atmoH^2, atmoH, mieG^2
//uniform vec3    AtmoRayleigh;   // betaR
//uniform vec3    AtmoMieExt;     // betaMExt
//uniform vec2    AtmoColAdjust;  // hsl color adjust
#endif

//uniform vec4    Radiuses;       // atmosphere bottom radius, atmosphere top radius, atmosphere height, surface radius
//uniform vec4    NodeCenter;     // node center offset, heightmap offset
//uniform ivec4   VSFetchParams;  // uIndex, vIndex, nTiles, mode
//uniform mat3x3  FaceRotation;   // terrain cube face oreintation
//uniform mat4x4  ModelViewProj;  // modelview * projection matrix

//uniform vec4    TexArrayIndices1;   // normal,    diffuse,    roughness, height
//uniform vec4    TexArrayIndices2;   // detNormal, detDiffuse, detRAO,    detBump
//uniform vec4    TexArrayIndices3;   // thermal,   emissive,   ---,       ---

//uniform int     NLights;                 // lights count
//uniform vec3    LightPos   [MAX_LIGHTS]; // Object-space light position
//uniform vec3    LightColor [MAX_LIGHTS]; // Light color
//uniform vec3    LightParams[MAX_LIGHTS]; // Light radius, light luminosity, light specular power

#ifdef ECL
//uniform vec4    EclipseCasters[MAX_LIGHTS * MAX_ECLIPSES];
#endif

//uniform vec4    AmbientColor;   // Ambient color, eclipse shadow intensity
//uniform vec4    ModulateColor;  // Modulate color, opacity
//uniform vec4    GlowColor;      // Glow color, glow mode
//uniform vec4    GlowColorAtmo;  // Glow color of the atmosphere, rings winter amount * shadow center radius
//uniform vec4    WaterSurfColor; // Water surface diffuse color, water on/off animation
//uniform vec4    WaterFogColor;  // Underwater absorption RGB, underwater absorption global
//uniform vec4    EyePos;         // Object-space camera position, minEyeMu
//uniform vec4    EyePosLocal;    // Object-space camera position relative to the node center, surface radius
//uniform vec4    SpecParams;     // ice specular bright, water specular bright, roughness bias, roughness scale
//uniform vec4    SurfParams1;    // eclipse shadow mask, star limb darkening, Hapke to Lambert lerp, isEarthSpecMap
//uniform vec4    SurfParams2;    // heightmap scale, day ambient coefficient, subsurface scattering brightness, subsurface scattering power
//uniform vec4    SurfParams3;    // face, lava temp shift, displacement magnitude, thermal map max temp
//uniform vec4    SurfParams4;    // city lights cutoff brightness, night light brightness, perm light brightness, thermal emission brightness
//uniform vec4    SurfParams5;    // surface brightness calibration, water brightness calibration, ambient brightness calibration, limit bright
//uniform vec4    HapkeParams;    // Hapke spot bright, 1 / Hapke spot width, Hapke CB spot bright, 1 / Hapke CB spot width
//uniform vec4    NoiseTexTransf; // UV noise shuffle texture transform
//uniform vec4    DiffTexTransf;  // Diffuse texture transform
//uniform vec4    BumpTexTransf;  // Height texture transform
//uniform vec4    NormTexTransf;  // Normal texture transform
//uniform vec4    GlowTexTransf;  // Glow texture transform
//uniform vec4    TempTexTransf;  // Temperature texture transform
//uniform vec4    DetTexTransf;   // Detail textures transform
//uniform vec4    RingsParams;    // rings inner radius, rings thickness, rings density, rings inv width
//uniform vec4    WaterParams;    // water depth, water layer radius, inv water fade height, water horizon opacity
//uniform vec4    EllipsGrav;     // planet ellipsoid oblateness, ellipsoid gravity coefficient

#ifdef SQT
//uniform vec4   NodeColor;       // grid color for quadtree node visualization
#endif

#if (defined(LOGFS) || defined(LOGVS))
//uniform float  LogZParams;      // logFactor
#endif

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
vec3  Attenuation   = vec3(0.0,0.0,0.0);

const float pi   = 3.14159265359;
const float pi2  = pi * 2.0;
const float pi05 = pi * 0.5;
const vec3  FaceBitangent = vec3(0.0, 0.01, 0.0); // step vector mask to compute tangents

#include "hsl.glh"
#include "texture_mix.glh"
#include "terrain_noise.glh"
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
out vec4 fPositionLocal;
out vec3 fTangent;
out vec4 fTexCoord0;
out vec4 fTexCoord1;
out vec4 fTexCoord2;

#if defined(EMIS) || defined(THERM)
out vec4 fTexCoord3;
#endif

//-----------------------------------------------------------------------------
// Hermite interpolation

float   interpolate(vec4 row, float t)
{
    float t2 = t * t;
    vec3  m = vec3(t*t2, t2, t);
    vec3  a = vec3(
        dot(row, vec4(-0.5,  1.5, -1.5,  0.5)),
        dot(row, vec4( 1.0, -2.5,  2.0, -0.5)),
        dot(row, vec4(-0.5,  0.0,  0.5,  0.0)));
    return dot(a, m) + row.y;
}

//-----------------------------------------------------------------------------
// Texture fetchng in vertex shader does not support linear interpolation, so
// we can't use mid-texel sampling for optimizing bicubic funciton to 4 samples

float   heightmapBicubicI(ivec3 uvi, vec2 uvf)
{
    const ivec4 offs = ivec4(-1, 0, 1, 2);
    vec4  col;

    col.x = interpolate(vec4(
        texelFetchOffset(HeightMapArray, uvi, 0, offs.xx).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.yx).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.zx).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.wx).r), uvf.x);

    col.y = interpolate(vec4(
        texelFetchOffset(HeightMapArray, uvi, 0, offs.xy).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.yy).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.zy).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.wy).r), uvf.x);

    col.z = interpolate(vec4(
        texelFetchOffset(HeightMapArray, uvi, 0, offs.xz).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.yz).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.zz).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.wz).r), uvf.x);

    col.w = interpolate(vec4(
        texelFetchOffset(HeightMapArray, uvi, 0, offs.xw).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.yw).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.zw).r,
        texelFetchOffset(HeightMapArray, uvi, 0, offs.ww).r), uvf.x);

    return interpolate(col, uvf.y);
}

//-----------------------------------------------------------------------------

float   heightmapBicubic(vec2 uv)
{
    uv -= vec2(HALF_TEXEL);

    // Integer and fractional parts of texture coordinates
    ivec3 uvi = ivec3(floor(uv * TILE_RES), TexArrayIndices1.w);
    vec2  uvf = uv * TILE_RES - vec2(uvi.xy);

    return heightmapBicubicI(uvi, uvf);
}

//-----------------------------------------------------------------------------

float   heightmapNearest(vec2 uv)
{
    // texelFetch does not support texture wrapping!
    //ivec3 uvi = ivec3(floor(uv * TILE_RES), TexArrayIndices1.w);
    //return texelFetch(HeightMapArray, uvi, 0).r;

    vec4 heightData = texture(HeightMapArray, vec3(uv, TexArrayIndices1.w));
    return heightData.r;
}

//-----------------------------------------------------------------------------

void    SphereVertexCoordF(float height, out vec3 pos, out vec3 tangent)
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

/*
    // compute tangent vector
    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;
    
    if (abs(pos.y) > 0.999) // pole discontinuity
        tangent = vec3(pos.z, 0.0, -pos.x);
    else
        tangent = normalize(tangent);
*/
    // Easy analytical tangent on sphere:
    // tangent = cross(pos, vec3(0.0, 0.0, 1.0));
    // After simplification:
    tangent = vec3(pos.y, -pos.x, 0.0);

    // apply height displacement
    pos *= 1.0 + height;
}

//-----------------------------------------------------------------------------

void    SphereSegmentVertexCoordF(float height, out vec3 pos, out vec3 tangent)
{
    float size2 = 2.0 / float(VSFetchParams.z);
    vec2   uv = vec2(vTexCoord.x, 1.0 - vTexCoord.y);

    // compute node offset with high precision
    vec2 offs = vec2(VSFetchParams.xy) * size2 - 1.0;

    // compute position
    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    // compute tangent vector
    vec3 pos0 = normalize(pos - FaceBitangent);
    vec3 pos1 = normalize(pos + FaceBitangent);
    pos       = normalize(pos);
    tangent   = pos0 - pos1;
    tangent   = tangent - dot(tangent, pos) * pos;
    tangent   = normalize(tangent);

    // apply height displacement
    pos *= 1.0 + (height - vTexCoord.z * size2);
}

//-----------------------------------------------------------------------------

void    SphereSegmentVertexCoordD(float height, out dvec3 pos, out dvec3 tangent)
{
    double size2 = 2.0 / double(VSFetchParams.z);
    dvec2  uv = dvec2(vTexCoord.x, 1.0 - vTexCoord.y);

    // compute node offset with high precision
    dvec2 offs = dvec2(VSFetchParams.xy) * size2 - 1.0;

    // compute position
    pos.xy = offs + uv * size2;
    pos.z  = 1.0;

    // compute tangent vector
    dvec3 pos0 = normalize(pos - FaceBitangent);
    dvec3 pos1 = normalize(pos + FaceBitangent);
    pos        = normalize(pos);
    tangent    = pos0 - pos1;
    tangent    = tangent - dot(tangent, pos) * pos;
    tangent    = normalize(tangent);

    // apply height displacement
    pos *= 1.0 + double(height - vTexCoord.z * size2);
}

//=============================================================================
// Vertex shader entry point

void main()
{
    // Transfer the unchanged node texture coordinates
    fTexCoord0.xy = vTexCoord.xy;
    
    // Transfer the node UV shuffle noise texture coordinates
    fTexCoord0.zw = vTexCoord.xy * NoiseTexTransf.zw + NoiseTexTransf.xy;

    // Transfer diff texture coordinates
    fTexCoord1.xy = vTexCoord.xy * DiffTexTransf.zw + DiffTexTransf.xy;

    // Transfer bump texture coordinates
    fTexCoord1.zw = vTexCoord.xy * BumpTexTransf.zw + BumpTexTransf.xy;

    // Transfer normal texture coordinates
    fTexCoord2.zw = vTexCoord.xy * NormTexTransf.zw + NormTexTransf.xy;

    #if defined(DET) || defined(SAMPLE_NEAREST)
        // Transfer detail texture coordinates
        fTexCoord2.xy = vTexCoord.xy * DetTexTransf.zw + DetTexTransf.xy;
    #endif

    #ifdef EMIS
        // Transfer glow texture coordinates
        fTexCoord3.xy = vTexCoord.xy * GlowTexTransf.zw + GlowTexTransf.xy;
    #endif

    #ifdef THERM
        // Transfer temperature texture coordinates
        fTexCoord3.zw = vTexCoord.xy * TempTexTransf.zw + TempTexTransf.xy;
    #endif

    // Read the main height map
    float height = 0.0;
    if (TexArrayIndices1.w >= 0.0)
    {
        #ifdef INTEL
            height = heightmapNearest(fTexCoord1.zw);
        #else
            height = (VSFetchParams.w == 1) ? heightmapBicubic(fTexCoord1.zw) : heightmapNearest(fTexCoord1.zw);
        #endif
    }

    vec3 displaceVec = vec3(0.0);

    // Read the detail height map, shift in direction of the global normal
    #if !defined(INTEL) && defined(DET) && defined(DISP)
    /*
        // Sample the normal map
        vec4 normData = texture(NormMapArray, vec3(fTexCoord2.zw, TexArrayIndices1.x));

        // Reconstrunct the normal vector
        vec3  normVec;
        normVec.xy = 2.0 * normData.xy - NORM_ONE;
        normVec.z  = sqrt(clamp(1.0 - dot(normVec.xy, normVec.xy), 0.0, 1.0));

        //normVec = vec3(0.0, 0.0, 1.0);
    */

        // In case of compressed textures, detail texture height is stored in
        // separate DetBumpMap texture, otherwise - in the DetDiffMap alpha channel
        float detHeight = 0.0;
        #ifdef COMPR
            if (TexArrayIndices2.w >= 0.0)
                detHeight = texture(DetBumpMapArray, vec3(fTexCoord2.xy, TexArrayIndices2.w)).r;
        #else
            if (TexArrayIndices2.y >= 0.0)
                detHeight = texture(DetDiffMapArray, vec3(fTexCoord2.xy, TexArrayIndices2.y)).a;
        #endif

        //displaceVec = normVec * detHeight * SurfParams3.z * SurfParams2.x;
        height += detHeight * SurfParams3.z;
    #endif

    height = height * SurfParams2.x - NodeCenter.w;

    // Perform calcultations in double precision only for fine levels
    #ifdef VSDBL

        // Calculate the vertex position on the planet sphere and tangent space vector
        dvec3 dvPosition = dvec3(0.0);
        dvec3 dvTangent  = dvec3(0.0);
        SphereSegmentVertexCoordD(height, dvPosition, dvTangent);
        //dvPosition += dvec3(displaceVec);
        dvec3 dvPosLocal = dvPosition - dvec3(NodeCenter.xyz);
        fPosition.xyz    = vec3(dvPosition);
        fPositionLocal   = vec4(dvPosLocal * double(EyePosLocal.w), 1.0);
        fTangent         = vec3(dvTangent);

        // Calculate the output position
        gl_Position = ModelViewProj * vec4(dvPosLocal, 1.0);

    #else

        // Calculate the vertex position on the planet sphere and tangent space vector
        if (VSFetchParams.w < 0)
            SphereVertexCoordF(height, fPosition.xyz, fTangent);        // base level (sphere)
        else
            SphereSegmentVertexCoordF(height, fPosition.xyz, fTangent); // other levels (spherical quadreee patch)
        //fPosition.xyz += displaceVec;
        vec3 vPosLocal = fPosition.xyz - NodeCenter.xyz;
        fPositionLocal = vec4(vPosLocal * EyePosLocal.w, 1.0);

        // Calculate the output position
        gl_Position = ModelViewProj * vec4(vPosLocal, 1.0);

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

    #ifdef RINGS
        // Disappearing of clouds in rings shadow (the 'rings winter' effect), only for light 0
        float vposInvDist  = inversesqrt(dot(fPosition.xyz, fPosition.xyz));
        float lightInvDist = inversesqrt(dot(LightPos[0],   LightPos[0]));
        float cosPhi, lt;

        if (SurfParams3.x == 0.0)
        {
            cosPhi = abs(LightPos[0].y) * lightInvDist;
            lt = smoothstep(0.0, 0.6, abs(fPosition.y * vposInvDist)) * step(LightPos[0].y * fPosition.y, 0.0);
        }
        else
        {
            cosPhi = abs(LightPos[0].z) * lightInvDist;
            lt = smoothstep(0.0, 0.6, abs(fPosition.z * vposInvDist)) * step(LightPos[0].z * fPosition.z, 0.0);
        }

        float tanPhi = cosPhi * inversesqrt(1.0 - cosPhi * cosPhi);
        float st = clamp(tanPhi * GlowColorAtmo.w, 0.0, 1.0);
        fPositionLocal.w = 1.0 - lt * st;
    #endif // RINGS
}

#endif // _VERTEX_

//===========================================================================//
//                                                                           //
//                            Fragment shader                                //
//                                                                           //
//===========================================================================//

#ifdef _FRAGMENT_

// Fragment shader input
in vec4 fPosition;
in vec4 fPositionLocal;
in vec3 fTangent;
in vec4 fTexCoord0;
in vec4 fTexCoord1;
in vec4 fTexCoord2;

#if defined(EMIS) || defined(THERM)
in vec4 fTexCoord3;
#endif

// Fragment shader output
#ifdef INTEL
out vec4 FragColor;
#else
layout(location = 0) out vec4 FragColor;
#endif

#ifdef LOGFS
layout(depth_less) out float gl_FragDepth;
#endif

const vec3 toGray = vec3(0.299, 0.587, 0.114);

//=============================================================================
// Fragment shader entry point

void main()
{
    // Calculate small random offset to texture coordinates to break up smoothness
    vec2 uvShatter = PlanetUVShatter(fTexCoord0.zw, HALF_TEXEL);

    // Get clouds color and transparency
    #ifdef ACLOUDS
        vec2  diffTexCoord  = fTexCoord1.xy + uvShatter;
        vec4  diffColor     = vec4(0.0);
        float cloudsOpacity = 0.0;

        // In case of compressed textures, clouds color is YCoCg-encoded, opacity
        // is stored in the RoughMap texture; otherwise - in the DiffMap alpha channel
        #ifdef COMPR
            if (TexArrayIndices1.z >= 0.0)
                cloudsOpacity = texture(RoughMapArray, vec3(diffTexCoord, TexArrayIndices1.z)).r;
        
            if (cloudsOpacity < 0.05) discard;

            if (TexArrayIndices1.y >= 0.0)
            {
                diffColor = texture(DiffMapArray, vec3(diffTexCoord, TexArrayIndices1.y));
                FromYCoCg(diffColor);
            }
        #else
            if (TexArrayIndices1.y >= 0.0)
                diffColor = texture(DiffMapArray, vec3(diffTexCoord, TexArrayIndices1.y));

            if (diffColor.a < 0.05) discard;

            cloudsOpacity = diffColor.a;
        #endif

        float cloudsFade = (1.0 - 0.05 / cloudsOpacity) / 0.95 * clamp(ModulateColor.a, 0.0, 1.0);
        //float cloudsFade = clamp(ModulateColor.a, 0.0, 1.0);
        //float cloudsFade = 1.0;

        diffColor.rgb *= cloudsFade * ModulateColor.rgb;
        cloudsOpacity *= cloudsFade;
    #endif

    // Logarithmic depth buffer:
    // calculate the per-pixel logarithmic depth value (LOGFS mode)
    #ifdef LOGFS
        gl_FragDepth = log2(1.0 + fPosition.w) * LogZParams;
    #endif

    // Get normal and tangent
    vec3 Normal   = normalize(fPosition.xyz);
    vec3 Tangent  = normalize(fTangent);

    // Calculate matrix of transformation to tangent space
    mat3x3 Rotation = mat3x3(Tangent, cross(Tangent, Normal), Normal);

    vec3  normVec    = vec3(0.0, 0.0, 1.0);
    vec3  normVecSea = vec3(0.0, 0.0, 1.0);
    if (TexArrayIndices1.x >= 0.0)
    {
        // Sample the normal map
        #ifdef  SAMPLE_NEAREST
            vec4 normData = texelFetch(NormMapArray, ivec3(fTexCoord2.zw * TILE_RES, TexArrayIndices1.x), 0);
        #else
            vec4 normData = texture(NormMapArray, vec3(fTexCoord2.zw + uvShatter, TexArrayIndices1.x));
        #endif

        // Reconstrunct the normal vector
        normVec.xy = 2.0 * normData.xy - NORM_ONE;
        normVec.z  = sqrt(clamp(1.0 - dot(normVec.xy, normVec.xy), 0.0, 1.0));
    }

    // Calculate surface slope from normal
    //float nz2 = normVec.z * normVec.z;
    //float slope = clamp(1.0 - nz2*nz2*nz2, 0.0, 1.0);

    // Sample the height map; don't shatter uv
    float heightN = 0.0;
    if (TexArrayIndices1.w >= 0.0)
    {
        #ifdef  SAMPLE_NEAREST
            heightN = texelFetch(HeightMapArray, ivec3(fTexCoord1.zw * TILE_RES, TexArrayIndices1.w), 0).r;
        #else
            heightN = texture(HeightMapArray, vec3(fTexCoord1.zw, TexArrayIndices1.w)).r;
        #endif
    }
    float height = heightN * SurfParams2.x;

    // Calculate the precise fragment position and eye vector in the object space
    EyeR    = length(EyePos.xyz);
    FragR   = (1.0 + height) * Radiuses.w;
    FragPos = Normal * FragR;
    eyeVec  = FragPos - EyePos.xyz;
    eyeVecLength = length(eyeVec);

    float WaterFragRmap = FragR;
    float WaterFragR    = FragR;

    // Switch to a vertex-precise coordinates close to the camera
    #ifndef ACLOUDS
        if (eyeVecLength < 50.0) // km
        {
            float t = smoothstep(2.0, 50.0, eyeVecLength);
            vec3  FragPosP = fPositionLocal.xyz + NodeCenter.xyz * EyePosLocal.w;
            vec3  eyeVecP  = fPositionLocal.xyz - EyePosLocal.xyz;
            float FragRP   = length(FragPosP);
            FragPos = mix(FragPosP, FragPos, t);
            eyeVec  = mix(eyeVecP,  eyeVec,  t);
            FragR   = mix(FragRP,   FragR,   t);
            #ifdef AWATER
                WaterFragR = mix(FragRP, WaterFragR, t);
            #endif
            eyeVecLength = length(eyeVec);
        }
    #endif

    eyeVec /= eyeVecLength;

    // Calculate the eye vector in the tangent space
    vec3  eyeVecTS = eyeVec * Rotation;

    #ifdef ACLOUDS
        // Fade out clouds when close to the camera
        cloudsFade = smoothstep(0.0, 1.0, eyeVecLength);
        diffColor.rgb *= cloudsFade;
        cloudsOpacity *= cloudsFade;
    #else
        // Get the surface diffuse color and specular/roughness
        vec2  diffTexCoord = fTexCoord1.xy + uvShatter;
        vec4  diffColor    = vec4(0.0);
        float roughMap     = 0.0;

        if (TexArrayIndices1.y >= 0.0)
        {
            #ifdef  SAMPLE_NEAREST
                diffColor = texelFetch(DiffMapArray, ivec3(fTexCoord1.xy * TILE_RES, TexArrayIndices1.y), 0);
            #else
                diffColor = texture(DiffMapArray, vec3(diffTexCoord, TexArrayIndices1.y));
            #endif

            #ifdef COMPR
                FromYCoCg(diffColor);
            #else
                roughMap = diffColor.a;
            #endif
        }

        // In case of compressed textures, surface color is YCoCg-encoded, roughness
        // is stored in the RoughMap texture; otherwise - in the DiffMap alpha channel
        #ifdef COMPR
            if (TexArrayIndices1.z >= 0.0)
                roughMap = texture(RoughMapArray, vec3(diffTexCoord, TexArrayIndices1.z)).r;
        #endif

        diffColor.rgb *= ModulateColor.rgb;
    #endif

    // Detail texturing
    //float detailFade = smoothstep(0.0, 1.0, 2.0 - eyeVecLength);
    float detailFade = clamp(2.0 - eyeVecLength, 0.0, 1.0);
    float detailFadeSpec = detailFade * detailFade;

    #ifdef DET
        vec4  detDiffColor = vec4(0.0);
        vec2  detRoughAO   = vec2(1.0);

        // Sample detail textures and blend them with base textures based on distance
        if (detailFade > 0.0)
        {
            vec3  detNormVec = vec3(0.0, 0.0, 1.0);
            float detailFadeNorm = 0.0;
            float detailFadeDiff = 0.0;

            if (TexArrayIndices2.x >= 0.0)
            {
                // Sample the detail normal map and unpack the normal vector to [-1, 1]
                vec4 detNormData = texture(DetNormMapArray, vec3(fTexCoord2.xy, TexArrayIndices2.x));

                // Reconstrunct the normal vector
                detNormVec.xy = 2.0 * detNormData.xy - NORM_ONE;
                detNormVec.z  = sqrt(clamp(1.0 - dot(detNormVec.xy, detNormVec.xy), 0.0, 1.0));

                // In case of compressed textures, detail color is YCoCg-encoded, roughness and AO
                // are stored in DetRAOMap texture; otherwise - in DetNormMap texture blue and alpha channels
                #ifndef COMPR
                    detRoughAO = detNormData.ba;
                #endif

                detailFadeNorm = detailFade;
            }

            #if 1
                // Calculate matrix of transformation to local tangent space
                mat3x3 RotationLocal = mat3x3(Tangent, cross(Tangent, normVec), normVec);

                // Transform the detail normal vector to the local tangent space
                detNormVec = RotationLocal * detNormVec;

                // Blend to global normal map at high distance
                normVec = normalize(mix(normVec, detNormVec, detailFadeNorm));
            #else
                normVec = BlendNormals(normVec, detNormVec, 0.5 * detailFadeNorm);
            #endif

            // Sample the detail diff map
            if (TexArrayIndices2.y >= 0.0)
            {
                #ifdef  SAMPLE_NEAREST
                    detDiffColor = texelFetch(DetDiffMapArray, ivec3(fTexCoord2.xy * TILE_RES, TexArrayIndices2.y), 0);
                #else
                       detDiffColor = texture(DetDiffMapArray, vec3(fTexCoord2.xy, TexArrayIndices2.y));
                #endif

                #ifdef COMPR
                    FromYCoCg(detDiffColor);
                #endif

                detailFadeDiff = detailFade;
            }

            // In case of compressed textures, detail color is YCoCg-encoded, roughness and AO
            // are stored in DetRAOMap texture; otherwise - in DetNormMap texture blue and alpha channels
            #ifdef COMPR
                if (TexArrayIndices2.z >= 0.0)
                    detRoughAO = texture(DetRAOMapArray, vec3(fTexCoord2.xy, TexArrayIndices2.z)).rg;
            #endif

            // Modulate and blend diff maps
            detDiffColor.rgb *= ModulateColor.rgb;
            diffColor.rgb = mix(diffColor.rgb, detDiffColor.rgb, detailFadeDiff);

            detRoughAO.r = adjustRoughness(max(detRoughAO.r, 1.0e-4), normVec);
        }
    #endif // DET

    float waterMask   = 0.0;
    float waterFade3D = 1.0;
    #ifdef AWATER
        // TODO: Earth textures must be converted to PBR, and procedural planet
        // palettes must be adjusted accordingly. For now, convert roughMap values
        // from non-PBR Earth textures (water = 1, ice = 0.1, land = 0)
        // and fake procedural palettes (water = formula below, ice = 1, land = 0.1)

        //waterMask = 5e4 * (WaterParams.x - heightN);
        waterMask = step(heightN, WaterParams.x);                       // for procedural planets
        //waterMask = max(waterMask, roughMap * SurfParams1.w);           // for Earth (to highlight rivers, SurfParams1.w == 1)
        waterMask = mix(waterMask, roughMap, SurfParams1.w);            // for Earth (to highlight rivers, SurfParams1.w == 1)

        waterFade3D = clamp(eyeVecLength * WaterParams.z - 1.0,  0.0, 1.0);
        //waterFade3D *= waterFade3D;
        #ifdef WATER_HARD_TRANSITION
            waterFade3D = step(1.0, waterFade3D);
        #endif

        float wavesFade = clamp(2.0 - eyeVecLength * 0.1, 0.0, 1.0);
        wavesFade *= wavesFade;

        // Calculate length of the view ray under water.
        // TODO: change to more precise EyeH / FragH!
        // TODO2: this code does not take into account curvature of the planet and shift of the sample
        // point (it assumes that the planet is flat and that the sea bottom has no terrain).
        float underWaterDist = 0.0;
        bool  isAboveWater = (EyeR > WaterParams.y);
        if (isAboveWater)
        {
            if (WaterFragR > WaterParams.y)
                underWaterDist = 0.0;
            else
                underWaterDist = eyeVecLength * max(WaterParams.y - WaterFragR, 0.0) / (EyeR - WaterFragR);
        }
        else
        {
            if (WaterFragR > WaterParams.y)
                underWaterDist = eyeVecLength * max(WaterParams.y - EyeR, 0.0) / (WaterFragR - EyeR);
            else
                underWaterDist = eyeVecLength;
        }

        // Calculate the water mask and fading
        float waterDepth = WaterParams.y - WaterFragRmap;

        // Fade out the underwater fog effect on areas outside the Earth's water mask to fix "flooded areas"
        if (waterDepth > 0.0) underWaterDist *= waterMask;
        if (waterDepth > 0.0) waterDepth *= waterMask;

        // Fake water map for For Earth (SurfParams1.w == 1): add fake depth to high-ground areas
        // to make rivers and lakes look blue, but only onwater-masked areas (roughMap > 0.18),
        // otherwise ice and terrain will have some blueish tint
        underWaterDist += 0.07 * max(roughMap - 0.18, 0.0) * SurfParams1.w;

        float underWaterFogFade = WaterSurfColor.a;
        //if (isAboveWater) underWaterFogFade *= waterFade3D;

        //vec4  waterAttenuation = clamp(exp(vec4(-4.0, -2.0, -1.4, -15.0) * (underWaterDist * underWaterFogFade)), 0.0, 1.0);
        vec4  waterAttenuation = clamp(exp(((-underWaterDist - max(waterDepth, 0.0)) * underWaterFogFade) * WaterFogColor), 0.0, 1.0);
        float waterOpacity = 1.0 - waterAttenuation.a;
    #endif

    // Calculate the fragment position for the eclipse shadow
    #ifdef ECL
        vec3  FragPosEll = FragPos * EllipsGrav.xyz;
    #endif

    // Calculate the fragment and eye parameters for the atmospheric scattering
    #ifdef ATMO
        FragH  = (FragR - Radiuses.x) / Radiuses.z;
        EyeH   = (EyeR  - Radiuses.x) / Radiuses.z;
        FragMu = dot(FragPos,    eyeVec) / FragR;
        EyeMu  = dot(EyePos.xyz, eyeVec) / EyeR;

        // If EyePos in space, move it to nearest intersection of ray with top atmosphere boundary
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
        /*else if (EyeH < 0.0)
        {
            d = -EyeR * EyeMu + sqrt(max(EyeR * EyeR * (EyeMu * EyeMu - 1.0) + Radiuses.x * Radiuses.x, 0.0));
            if (d > 0.0)
            {
                EyePosM -= d * eyeVec;
                eyeVecLength += d;
                EyeMu = (EyeR * EyeMu + d) / Radiuses.x;
                EyeR = Radiuses.x;
                EyeH = 0.0;
            }
        }*/
    #endif

    #ifdef ATMO
        float sqrtFragH = sqrt(FragH);
    #endif

    #ifdef THERM
        float sunHeating = 0.0;
    #endif

    // Initial PBR surface parameters
    float metallic = 0.0;
    float roughTer = 0.0;
    float specTer  = 0.0;
    float aoTer    = 1.0;
    float roughSea = 0.0;
    float specSea  = 0.0;
    float aoSea    = 1.0;

    #ifndef ACLOUDS

        // Water mask with fading to 3D water and water on/off animation
        float waterMaskA  = waterMask  * WaterSurfColor.a;
        float waterMaskAF = waterMaskA * waterFade3D;

        specTer = SpecParams.x * roughMap;
        specSea = SpecParams.y;

        roughTer = SpecParams.z;
        roughSea = SpecParams.w;

        #ifdef DET
            // Lerp global textures to detail textures
            float specDetail  = 1.0;
            float roughDetail = detRoughAO.x;
            float aoDetail    = detRoughAO.y;

            specTer  = mix(specTer,  specDetail,  detailFadeSpec);
            roughTer = mix(roughTer, roughDetail, detailFade);
            aoTer    = mix(aoTer,    aoDetail,    detailFade);
        #endif

    #endif // ACLOUDS
           
    // Apply disappearing of clouds in rings shadow (the "rings winter" effect)
    #ifdef RINGS
        diffColor *= fPositionLocal.w;
        #ifdef ACLOUDS 
            cloudsOpacity *= fPositionLocal.w;
        #endif
    #endif

    // Uderwater fog
    #ifdef AWATER
        vec3 waterFogAccum = AmbientColor.rgb;
    #endif

    // Calculate the atmospheric scattering
    #ifdef ATMO

        EyeMuS = 0.0;
        MieHorFade = 0.0;

        // Atmospheric attenuation along ray from the ground to the viewer
        #ifdef ANALYTIC_TRANSM
            #if !defined(ACLOUDS) && defined(AWATER)
                // Analytic transmittance for underwater terrain gives too big
                // attenuation (the Mariana trench is visible from space).
                #if 0
                    // Method 1: switch to texture-based transmittance.
                    // Gives artifacts near shore line in dense atmosphere.
                    if (FragH < 0.0)
                        Attenuation = transmittance(sqrt(EyeH), EyeMu, sqrtFragH, FragMu);
                    else
                        Attenuation = transmittanceAnalytic(EyeR, max(EyeMu, EyePos.w), eyeVecLength);
                #else
                    // Method 2: reduce view ray length by underwater path distance.
                    // Does not completely eliminates effect, because underWaterDist is approximate.
                    eyeVecLength -= underWaterDist;
                    Attenuation = transmittanceAnalytic(EyeR, max(EyeMu, EyePos.w), eyeVecLength);
                #endif
            #else   // !ACLOUDS && AWATER
                Attenuation = transmittanceAnalytic(EyeR, max(EyeMu, EyePos.w), eyeVecLength);
            #endif  // !ACLOUDS && AWATER
        #else
            Attenuation = transmittance(sqrt(EyeH), EyeMu, sqrtFragH, FragMu);
        #endif // ANALYTIC_TRANSM

        // Fix discontinuity artifact at the horizon by interpolating values above and below the horizon
        bool atmoHorFix = false;
        #ifdef HORIZON_FIX
            float invR = Radiuses.x / EyeR;
            HorizonMu = -sqrt(1.0 - invR * invR);
            HorizonFixEps = AtmoParams1.w;
            atmoHorFix = abs(EyeMu - HorizonMu) < HorizonFixEps;
        #endif // HORIZON_FIX

        vec3 Inscatter = vec3(0.0);

        // Atmospheric scattering in the glowing atmosphere - as if light source is in the center of the planet.
        // Calculate only if glow color is non-zero, this saves a few FPS.
        #ifdef THERM
            if (GlowColorAtmo.r + GlowColorAtmo.g + GlowColorAtmo.b > 0.0)
            {
                if (atmoHorFix)
                    Inscatter = inscatterGroundFix(vec3(0.0));
                else
                    Inscatter = inscatterGround(vec3(0.0));
                Inscatter *= GlowColorAtmo.rgb;
            }
        #endif

    #endif // ATMO

    // Calculate lighting values separately for terrain and flat sea surface
    float NdotV = clamp(-dot(normVec, eyeVecTS), 0.0, 1.0);
    vec3  diffTerAccum = vec3(0.0);
    vec3  specTerAccum = vec3(0.0);
    vec3  ambTerAccum  = AmbientColor.rgb;
    vec3  diffSeaAccum = vec3(0.0);
    vec3  specSeaAccum = vec3(0.0);
    vec3  ambSeaAccum  = AmbientColor.rgb;
    vec3  cityLightingAccum = vec3(0.0);
    float EclipseMask = 1.0;

    vec3  testS = vec3(0.0);

    for (int i=0; i<NLights; i++)
    {
        // Calculate light vectors in object space
        vec3 lightPos = LightPos[i] - FragPos;
        vec3 lightVec = normalize(lightPos);

        // Calculate light vectors in tangent space
        vec3 lightVecTS = lightVec * Rotation;

        // Calculate direct sun lighting
        float NdotLS  = dot(Normal, lightVec);
        float NdotLSC = clamp(NdotLS, 0.0, 1.0);

        // Calculate inverse light distance
        #if (defined(ECL) || defined(THERM))
            vec3  lightPosEll = lightPos * EllipsGrav.xyz;
            float invLightDist = inversesqrt(dot(lightPosEll, lightPosEll));
        #endif

        // Set up atmospheric scattering variables
        #ifdef ATMO
            EyeMuS = dot(EyePosM, lightVec) / EyeR;
            MieHorFade = smoothstep(0.0, AtmoParams2.y, EyeMuS); // Fade to avoid imprecision problems in Mie scattering when sun is below horizon
        #endif

        // Rings and eclipse shadows
        float Shadow = 1.0;

        // Rings shadow
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

        // Eclipse shadows
        #ifdef ECL
            float lightAngularRadius = asin(clamp(LightParams[i].x * invLightDist, 0.0, 1.0));
            float eclipse = EclipseShadowFar(i, MAX_ECLIPSES, FragPosEll, lightPosEll * invLightDist, lightAngularRadius);
            Shadow *= 1.0 - AmbientColor.a * eclipse;
            eclipse *= step(0.0, dot(lightPosEll, FragPosEll));
            EclipseMask *= 1.0 - eclipse;
        #endif

        // Planetary sphere shadow
        // TODO: take into account sun angular size
        #ifdef ACLOUDS
            float rr = Radiuses.x / FragR;
        #else
            float rr = clamp(1.0 / (1.0 + height), 0.0, 0.9999);
        #endif
        float cosHor = sqrt(1.0 - rr*rr);
        float HorShadow = clamp((cosHor + NdotLS) * 500.0, 0.0, 1.0);

        // Direct sun light color, modulated by shadows
        vec3  sunLight = LightColor[i].rgb * Shadow;

        // Direct sun light color, attenuatied by atmosphere, or modulated by planetary sphere shadow
        vec3 sunLightHorShadow = sunLight * HorShadow;
        #ifdef ATMO
            sunLightHorShadow *= transmittanceDens(sqrtFragH, NdotLS);
        #endif

        //float NdotV_positive = clamp(dot(normVec, eyeVecTS), 0.00001, 1.0);
        float VdotL    = clamp(-dot(lightVec, eyeVec), -0.999, 1.0);
        float NdotL    = clamp(dot(normVec, lightVecTS), 0.0, 1.0);
        float NdotLsea = clamp(lightVecTS.z, 0.0, 1.0);

        // Simplified Hapke BRDF
        float Hapke = HapkeBRDF(NdotL, NdotV, VdotL);
        //float Hapke = HapkeBRDF(NdotL, NdotV_positive, VdotL);
        //#ifdef AWATER
        //    Hapke = mix(Hapke, 1.0, waterMaskAF);
        //#endif

        //ao = mix(ao, 1.0, clamp(pow(Hapke, 2.2), 0.0, 1.0));

        // Get the normal and "flat surface" lighting color
        vec3 sunLightW    = sunLightHorShadow * NdotLSC;
        vec3 sunLightN    = sunLightHorShadow * NdotL * Hapke;
        vec3 sunLightNSea = sunLightHorShadow * NdotLsea;

        // Get the sun heating value
        #ifdef THERM
            sunHeating += NdotL * Shadow * HorShadow * LightParams[i].y  * invLightDist * invLightDist;
        #endif

        // Fake daytime ambient lighting
        vec3 ambTerTerm = LightColor[i].rgb * (NdotLSC * Shadow * SurfParams2.y);
        vec3 ambSeaTerm = ambTerTerm;
        ambTerTerm *= aoTer;
        //ambTerTerm *= diffColor.rgb;
        //ambSeaTerm *= WaterSurfColor.rgb;

        // Add sky irradiance
        #ifdef ATMO
            vec3 skyIrrad = irradiance(FragH, NdotLS) * sunLight * Shadow * AtmoParams1.z;
            #if (defined(AWATER) || defined(EMIS))
                sunLightW += skyIrrad;
            #endif
            ambTerTerm += skyIrrad;
            ambSeaTerm += skyIrrad;
        #endif

        // Fade out fake day ambient under water
        //#ifdef AWATER
        //    ambTerTerm *= 1.0 - waterOpacity;
        //#endif

        // Accumulate lighting value for city lights brightness control
        #ifdef EMIS
            cityLightingAccum += sunLightW;
        #endif

        // Accumulate uderwater fog color
        #ifdef AWATER
            waterFogAccum += sunLightW;
        #endif

        // PBR workflow
        vec3  subscatTerm = vec3(0.0);
        vec3  diffTerTerm = vec3(0.0);
        vec3  specTerTerm = vec3(0.0);
        vec3  diffSeaTerm = vec3(0.0);
        vec3  specSeaTerm = vec3(0.0);

        #if (!defined(ACLOUDS) && (defined(AWATER) || defined(AICE)))

            // Cook-Torrance BRDF (terrain, sea bottom)
            CookTorranceBRDF(normVec, eyeVecTS, lightVecTS, NdotV, NdotL,
                             diffColor.rgb, roughTer, aoTer, metallic,
                             diffTerTerm, specTerTerm);
        #ifdef AWATER
            float NdotVsea = clamp(-dot(normVecSea, eyeVecTS), 0.0, 1.0);

            // Cook-Torrance BRDF (flat sea surface)
            CookTorranceBRDF(normVecSea, eyeVecTS, lightVecTS, NdotVsea, NdotLsea,
                WaterSurfColor.rgb, roughSea, aoSea, metallic,
                diffSeaTerm, specSeaTerm);

        #endif

        #else // (!defined(ACLOUDS) && (defined(AWATER) || defined(AICE)))

            // clouds

            #ifdef ACLOUDS
                // Subsurface scattering
                // Use a spherical gaussian approximation of pow() for forwardScattering
                // We could include distortion by adding shading_normal * distortion to light.l
                float thickness = 1.0 - cloudsOpacity;
                vec3  halfVecTS = normalize(lightVecTS - eyeVecTS);
                float VdotH = clamp(-dot(eyeVecTS, halfVecTS), 0.0, 1.0);
                float forwardScatter = exp2(-VdotH * SurfParams2.w - SurfParams2.w);
                float backScatter = clamp(NdotL * thickness + (1.0 - thickness), 0.0, 1.0) * 0.5;
                float subsurface = mix(backScatter, 1.0, forwardScatter) * (1.0 - thickness);
                subscatTerm = (SurfParams2.z * subsurface / pi) * sunLightHorShadow;
                //cloudsOpacity = smoothstep(0.0, 0.1, cloudsOpacity);
            #endif

            diffTerTerm = (PBR_BRIGHT_CORR/pi) * diffColor.rgb;

        #endif // (!defined(ACLOUDS) && (defined(AWATER) || defined(AICE)))

        // Accumulate ambient, diffuse and specular terms
        diffTerAccum += diffTerTerm * sunLightN + subscatTerm;
        specTerAccum += specTerTerm * sunLightN;
        ambTerAccum  += ambTerTerm;
        diffSeaAccum += diffSeaTerm * sunLightNSea;
        specSeaAccum += specSeaTerm * sunLightNSea;
        ambSeaAccum  += ambSeaTerm;

        //if (i == 0) testS = skyIrrad;

        // Calculate the atmospheric scattering along ray from ground to observer
        #ifdef ATMO
            if (atmoHorFix)
                Inscatter += inscatterGroundFix(lightVec) * sunLight;
            else
                Inscatter += inscatterGround(lightVec) * sunLight;
        #endif
    }

    // Clouds: disable ambient on transparent areas
    #ifdef ACLOUDS
        ambTerAccum *= cloudsOpacity;
    #endif

    // Modulate ambient lighting by surface color
    ambTerAccum *= diffColor.rgb;
    ambSeaAccum *= WaterSurfColor.rgb;

    // Apply brightness calibration
    diffTerAccum *= SurfParams5.x;
    specTerAccum *= SurfParams5.x * specTer;
    ambTerAccum  *= SurfParams5.z;
    diffSeaAccum *= SurfParams5.x;
    specSeaAccum *= SurfParams5.x * specSea;
    ambSeaAccum  *= SurfParams5.z;

    // Apply the underwater fog
    #ifdef AWATER
        waterFogAccum *= WaterSurfColor.rgb * SurfParams5.y;

        // For Earth, constrain underwater fog by water map
        float waterFogMix = waterOpacity * mix(1.0, waterMask, SurfParams1.w);

        diffTerAccum = mix(diffTerAccum * waterAttenuation.rgb, waterFogAccum, waterFogMix);
        specTerAccum = mix(specTerAccum * waterAttenuation.rgb, vec3(0.0),     waterFogMix);
        ambTerAccum  = mix(ambTerAccum  * waterAttenuation.rgb, vec3(0.0),     waterFogMix);
        //ambTerAccum = mix(ambTerAccum, vec3(0.0), waterOpacity);

        // Calculate the water surface opacity
        // WaterParams.w > 1 makes water surface opaque near horzion:
        // terrestrial planets:  to hide atmo scattering on underwater terrain
        // superoceanic planets: to hide planet's solid core when viewed from space
        float fresAlpha = clamp(0.02 + WaterParams.w * 0.98 * pow(1.0 - abs(dot(eyeVecTS, normVecSea)), 4), 0.0, 1.0);
        float opacity = clamp(waterOpacity + fresAlpha, 0.0, 1.0);

        // Interpolate bottom terrain to flat ocean surface when viewing from space
        //float EyeDepth = clamp((WaterParams.y - EyeR) * 1000.0, 0.0, 1.0);
        specTerAccum = mix(specTerAccum, specSeaAccum, waterMaskAF);

        #ifndef WATER_SPECULAR_ONLY
            //float seaDiffMix = mix(waterMaskA, waterMaskAF, isAboveWater ? wavesFade : 1.0);
            //float seaDiffMix = mix(waterMaskA, waterMaskAF, isAboveWater ? detailFade : 1.0);
            //float seaDiffMix = isAboveWater ? waterMaskA : waterMaskAF;
            float seaDiffMix = waterMaskAF;
            //float seaDiffMix = waterMaskA;
            diffTerAccum = mix(diffTerAccum, diffSeaAccum, seaDiffMix * opacity);
            ambTerAccum  = mix(ambTerAccum,  ambSeaAccum,  seaDiffMix * opacity);
        #endif
    #endif

    // Calculate surface color
    vec3  surfaceColor = diffTerAccum + specTerAccum + ambTerAccum;

    // Calculate emission color
    #if (defined(THERM) || defined(EMIS))
        vec3  glowColor = vec3(0.0);

        // Calculate thermal emission
        #ifdef THERM

            // Get surface temperature, unpack to thousand Kelvins
            float surfTemp = 0.0;
            if (TexArrayIndices3.x >= 0.0)
                surfTemp = DecodeTemperature(texture(TempMapArray, vec3(fTexCoord3.zw + uvShatter, TexArrayIndices3.x)).r, SurfParams3.w);

            // Heating by sun(s)
            surfTemp = pow(0.010673289 * sunHeating + pow(surfTemp, 4), 0.25); // 0.008301447 = 0.33^4 * (1 - 0.1), 0.33 = temp in thousand K, 0.1 = lava albedo

            // Gravity darkening for ellipsoidal stars
            float sinLat2 = (SurfParams3.x == 0.0) ? Normal.y * Normal.y : Normal.z * Normal.z;
            float gravity = EllipsGrav.w * sinLat2 + 1.0;
            surfTemp *= pow(gravity, 0.25);

            // Limb darkening:
            // apparent temperature at limb   = 0.86x
            // apparent temperature at center = 1.1x
            if (SurfParams1.y > 0.0) // only affect objects that use limb darkening  
            {
                float limbDarkening = mix(1.0, NdotV, SurfParams1.y);
                surfTemp *= mix(0.86, 1.1, limbDarkening);
            }
			else if (SurfParams1.y == 0.0 && SpecParams.x == 0)// && SpecParams ==0) // only affect objects that use limb darkening  SurfParams2
            {
                float limbDarkening = mix(1.0, NdotV, SurfParams1.y+1.5);
                surfTemp *= mix(0.86, 1.1, limbDarkening);
            }
            // Get thermal emission color by sampling the Planck function texture
            vec3 glowColorTherm = texture(PlanckFunction, log(surfTemp + SurfParams3.y) * 0.188 + 0.1316).rgb * SurfParams4.w;

            // Old limb darkening code
            //glowColorTherm *= vec3(0.65, 0.35, 0.20) + vec3(0.35, 0.65, 0.80) * limbDarkening;

            glowColor += glowColorTherm;
        #endif // THERM

        // Calculate night/permanent self-emission
        #ifdef EMIS
            vec4  glowData = vec4(0.0);

            // Get glow color in rgb
            if (TexArrayIndices3.y >= 0.0)
            {
                glowData = texture(GlowMapArray, vec3(fTexCoord3.xy + uvShatter, TexArrayIndices3.y));

                // In case of compressed textures, emission color is YCoCg-encoded
                #ifdef COMPR
                    FromYCoCg(glowData);
                    glowData.rgb = max(glowData.rgb - vec3(1.0/255.0), vec3(0.0)); // Fix black level of Earth's city lights
                #endif
            }

            vec3  glowColorCity = glowData.rgb * GlowColor.rgb * SurfParams4.z;

            // City lights - off in the daytime (GlowColor.a == 1.0)
            float LightingBrightness = dot(cityLightingAccum, vec3(0.3, 0.59, 0.11));
            glowColorCity *= 1.0 - smoothstep(SurfParams4.x * 0.2, SurfParams4.x, LightingBrightness) * GlowColor.a;

            glowColor += glowColorCity;
        #endif // EMIS

        #ifdef ACLOUDS
            glowColor *= cloudsOpacity;
        #endif

        surfaceColor += glowColor;
    #endif // THERM || EMIS

    // Apply the atmospheric scattering
    #ifdef ATMO
        //Attenuation = mix(Attenuation, vec3(1.0), waterOpacity);

        // Attenuate the light along the ray from the surface to the observer
        surfaceColor *= Attenuation;

        // Add atmospheric scattering along the ray the surface to the observer
        surfaceColor += Inscatter;

        #ifdef ACLOUDS
            // If this is a cloud layer, subtract atmospheric scattering from the cloud layer
            // to observer, because it was already computed on previous layer (terrain)
            surfaceColor -= Inscatter * (1.0 - cloudsOpacity);
        #endif

    #endif // ATMO

    // Write the output color
    FragColor.rgb = surfaceColor;

    #ifdef ACLOUDS
        FragColor.a = cloudsOpacity;
    #else
        FragColor.a = ModulateColor.a;
    #endif

    // Display the eclipse shadow mask
    #ifdef ECL
        FragColor.b += SurfParams1.x * step(EclipseMask, 0.0);
    #endif

    // Limit the brightness while preserving color
    if (SurfParams5.w != 0.0)
    {
        float luma = max(FragColor.r, max(FragColor.g, FragColor.b));
        FragColor.rgb *= clamp(65000.0 / (luma + 1.0e-10), 0.0, 1.0);
    }

#ifdef AWATER
    //FragColor.rgb = testS;
    //FragColor.rgb = waterAttenuation.rgb;
    //FragColor.rgb = ambSeaAccum;
    //FragColor.rgb = diffSeaAccum;
    //FragColor.rgb = vec3(roughMap * SpecParams.x);
    //FragColor.rgb = vec3(opacity * waterogColor.a);
    //FragColor.rgb = vec3(seaDiffMix);
    //FragColor.rgb = vec3(((eyeVecLength / 1000.0) - 0.1) * 10.0);
    //FragColor.rgb = vec3(-EyeMu);
    //FragColor.rgb = vec3(waterDetFadeHeight, spec, 0.0);
    //FragColor.rgb = Inscatter;
    //FragColor.rgb = Attenuation;
#endif

    // Display debug node boundaries
    #ifdef SQT
        float tileEdge = 1.0 - smoothstep(0.5, 0.48, abs(0.5 - fTexCoord0.x)) * smoothstep(0.5, 0.48, abs(0.5 - fTexCoord0.y));
        FragColor.rgb = mix(FragColor.rgb, NodeColor.rgb, tileEdge);
    #endif

#ifdef  PIXEL_GRID
    // Display debug grid - a line each 16 pixels
    vec2  uvi     = fTexCoord1.xy * TILE_RES;
    vec2  line16  = mod(uvi, vec2(16.0));
    vec2  line4   = mod(uvi, vec2(4.0));
    vec2  line2   = mod(uvi, vec2(2.0));
    float line4x  = step(line4.x,  0.5) * step(line2.y, 1.0);
    float line4y  = step(line4.y,  0.5) * step(line2.x, 1.0);
    float line16x = step(line16.x, 0.5) * step(line2.y, 1.0);
    float line16y = step(line16.y, 0.5) * step(line2.x, 1.0);
    FragColor.rgb = mix(FragColor.rgb, vec3(1.0, 0.0, 0.0), 0.75 * max(line16x, line16y) + 0.25 * max(line4x, line4y));

    #ifdef  DET
        uvi     = fTexCoord2.xy * TILE_RES;
        line16  = mod(uvi, vec2(16.0));
        line4   = mod(uvi, vec2(4.0));
        line2   = mod(uvi, vec2(2.0));
        line4x  = step(line4.x,  0.5) * step(line2.y, 1.0);
        line4y  = step(line4.y,  0.5) * step(line2.x, 1.0);
        line16x = step(line16.x, 0.5) * step(line2.y, 1.0);
        line16y = step(line16.y, 0.5) * step(line2.x, 1.0);
        FragColor.rgb = mix(FragColor.rgb, vec3(0.0, 0.0, 1.0), 0.75 * max(line16x, line16y) + 0.25 * max(line4x, line4y));
    #endif
#endif
}

#endif // _FRAGMENT_

//=============================================================================
