#auto_version

//===========================================================================//
//                                                                           //
//               SpaceEngine planetary sky rendering shader                  //
//                                                                           //
//===========================================================================//

// Defines passed from SpaceEngine. Possible defines:
// Effects:           	THERM, RINGS, ECL, PLANEMO
// Vendor-specific:     INTEL, LOGVS, LOGFS
#auto_defines

#ifdef LOGFS
#extension GL_ARB_conservative_depth : enable
#endif

// Standard defines
#define MAX_LIGHTS   4
#define MAX_ECLIPSES 8

#define SHADOW (defined(RINGS) || defined(ECL))

//===========================================================================//
//                                                                           //
//                            Texture samplers                               //
//                                                                           //
//===========================================================================//

uniform sampler2D irradianceSampler;    // precomputed skylight irradiance (E table)
uniform sampler2D transmittanceSampler; // precomputed transmittance (T table)
uniform sampler3D inscatterSampler;     // precomputed inscattered light (S table)

#ifdef RINGS
uniform sampler2D RingsMap;
#endif

//===========================================================================//
//                                                                           //
//                                Uniforms                                   //
//                                                                           //
//===========================================================================//

//uniform vec4   AtmoParams1;   // density, scattering bright, skylight bright, exposure
//uniform vec4   AtmoParams2;   // MieG, MieFade, HR, HM
//uniform vec4   AtmoParams3;   // planet_radius^2, atmoH^2, atmoH, mieG^2
//uniform vec3   AtmoRayleigh;  // betaR
//uniform vec3   AtmoMieExt;    // betaMExt
//uniform vec2   AtmoColAdjust; // hsl color adjust
//
//uniform vec4   Radiuses;      // atmosphere bottom radius, atmosphere top radius, atmosphere height, surface radius
//uniform mat4x4 ModelViewProj; // modelview * projection matrix
//
//uniform int    NLights;                 // lights count
//uniform vec3   LightPos   [MAX_LIGHTS]; // object-space light position
//uniform vec3   LightColor [MAX_LIGHTS]; // light color
//uniform vec3   LightParams[MAX_LIGHTS]; // light radius, light luminosity, light specular power
//
//#ifdef ECL
//uniform vec4   EclipseCasters[MAX_LIGHTS * MAX_ECLIPSES];
//#endif
//
//uniform vec4   AmbientColor;  // ambient color, eclipse shadow intensity
//uniform vec3   GlowColorAtmo; // glow color of the atmosphere
//uniform vec3   EyePos;        // object-space camera position, minEyeMu
//uniform vec3   Ellipsoid;     // planet ellipsoid oblateness
//
//#ifdef RINGS
//uniform vec3   RingsParams;   // rings inner radius, rings thickness, rings density, inv width
//#endif
//
//#if (defined(LOGFS) || defined(LOGVS))
//uniform float  LogZParams;    // logFactor
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
vec3  Attenuation   = vec3(0.0,0.0,0.0);

const float pi = 3.14159265359;

#include "hsl.glh"
#include "atmo_common.glh"

#ifdef RINGS
#define RINGS_SHADOW_CODE
#include "rings_common.glh"
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
layout(location = 0) in  vec3  VertexPos;
layout(location = 1) in  vec2  TexCoord;
layout(location = 2) in  vec3  Tangent;

// Vertex shader output
out vec4 vPosition;

//=============================================================================
// Vertex shader entry point

void main()
{
    // Calculate the output position
    gl_Position = ModelViewProj * vec4(VertexPos, 1.0);
    vPosition.xyz = VertexPos;

    // Logarithmic depth buffer:
    // calculate the per-vertex logarithmic depth value in vertex shader (LOGVS mode),
    // or transfer it to the fragment shader for further per-fragment calculation (LOGFS mode)
	#ifdef LOGVS
		gl_Position.z = (log2(max(1.0e-6, 1.0 + gl_Position.w)) * LogZParams - 1.0) * gl_Position.w;
    #endif
	#ifdef LOGFS
		vPosition.w = gl_Position.z;
	#endif
}

#endif // _VERTEX_

//===========================================================================//
//                                                                           //
//                            Fragment shader                                //
//                                                                           //
//===========================================================================//

#ifdef _FRAGMENT_

// Fragment shader input
in vec4 vPosition;

// Fragment shader output
#ifdef INTEL
out vec4 FragColor;
#else
layout(location = 0) out vec4 FragColor;
#endif

#ifdef LOGFS
layout(depth_less) out float gl_FragDepth;
#endif

//=============================================================================
// Fragment shader entry point

void main()
{
    // Logarithmic depth buffer:
    // calculate the per-pixel logarithmic depth value (LOGFS mode)
	#ifdef LOGFS
		gl_FragDepth = log2(1.0 + vPosition.w) * LogZParams;
	#endif

    // Calculate precise fragment position
    FragR   = Radiuses.w;
    FragPos = normalize(vPosition.xyz) * FragR;
    vec3  FragPosS = FragPos * Ellipsoid;
    vec3  Normal = normalize(FragPos);

    // Calculate eye vector in object space
    eyeVec = normalize(FragPos - EyePos);

    // Calculate fragment and eye parameters for atmosphere
    EyeR  = length(EyePos);
    EyeH  = (EyeR - Radiuses.x) / Radiuses.z;
    EyeMu = dot(EyePos, eyeVec) / EyeR;

    EyePosM = EyePos;
    float b = -EyeR * EyeMu;
    float t = EyeR * EyeR * (EyeMu * EyeMu - 1.0);
    float d = b - sqrt(max(t + Radiuses.w * Radiuses.w, 0.0));
    if (d > 0.0)
    {
        // if EyePos in space, move it to nearest intersection of ray with top atmosphere boundary
        EyePosM += d * eyeVec;
        EyeMu = (EyeR * EyeMu + d) / Radiuses.w;
        EyeR = Radiuses.w;
        EyeH = 1.0;
    }
    else if (EyeH < 0.0)
    {
        // if EyePos is below sea level, move it to nearest intersection of ray with bottom atmosphere boundary
        d = b + sqrt(t + Radiuses.x * Radiuses.x);
        if (d >= 0.0)
        {
            EyePosM += d * eyeVec;
            EyeMu = (EyeR * EyeMu + d) / Radiuses.x;
            EyeR = Radiuses.x;
            EyeH = 0.001;
        }
    }

    // Atmospheric scattering along ray from the atmosphere top boundary to the viewer
    #ifdef THERM
        EyeMuS = 0.0;
        MieHorFade = 0.0;
        vec3 Inscatter = inscatterSky(vec3(0.0)) * GlowColorAtmo;
    #else
        vec3 Inscatter = vec3(0.0);
    #endif

    // Calculate light vectors in object space
    for (int i=0; i<NLights; i++)
    {
        vec3 lightPos = LightPos[i] - FragPos;
        vec3 lightVec = normalize(lightPos);

        EyeMuS = dot(EyePosM, lightVec) / EyeR;
        MieHorFade = smoothstep(0.0, AtmoParams2.y, EyeMuS); // Fade to avoid imprecision problems in Mie scattering when sun is below horizon

        // Rings and eclipse shadows
        float Shadow = 1.0;

        #if SHADOW

            // Calculate shadow by rings
            #ifdef RINGS
                float cosPhi = abs(lightVec.y);
                vec2  shadowProj = vPosition.xz - lightPos.xz * min(vPosition.y / lightPos.y, 0.0);
                float texU = (length(shadowProj) * Radiuses.y - RingsParams.x) * RingsParams.w;
                Shadow *= RingsShadow(texU, cosPhi);
            #endif

            // Calculate eclipse shadow
            #ifdef ECL
                vec3  lightVecSN = normalize(lightPos * Ellipsoid);
                float lightAngularRadius = asin(LightParams[i].x * inversesqrt(dot(LightPos[i], LightPos[i])));
                Shadow *= 1.0 - AmbientColor.a * EclipseShadowFar(i, MAX_ECLIPSES, FragPosS, lightVecSN, lightAngularRadius);
            #endif

        #endif // SHADOW

        // Direct sun light color, modulated by shadows
        vec3  sunLight = LightColor[i].rgb * Shadow;
	
        // Atmospheric scattering along ray from the atmosphere top boundary to the viewer
        Inscatter += inscatterSky(lightVec) * sunLight;
  
// Ringshine
        #ifdef RINGS
           
            float ringNormalL = lightVec.y;
            float ringNormalN = Normal.y; // Use viewer's latitude
            
            float sameSide = step(0.0, ringNormalL * ringNormalN);
            
            // Horizon Culling
            float latSine = abs(ringNormalN);
            
            // Calculate where rings dip below the horizon
            float InnerRing = (Radiuses.y - Radiuses.z) / (RingsParams.x);  // Inner ring rel to planet
			float OuterRing = (Radiuses.y - Radiuses.z) / ((RingsParams.x + (1/RingsParams.w))); // Outer ring rel to planet
			float MeanRing = (Radiuses.y - Radiuses.z) / ((RingsParams.x + (1/RingsParams.w))/2); // mean ring rel to planet

			float MinOutRing = tan(1/OuterRing)/1.57;
			float MinInnerRing = tan(1/InnerRing)/1.57;
			
			float MinRing = pow((InnerRing+OuterRing)/4,2); //Minimum ring visibity from surface
			float Ang =  abs(ringNormalL);//pow(tanh(abs(ringNormalL))/tanh(pi/2),3);
			float MinIllum = (1-MinRing)*pow(1/((max(MinOutRing/(Ang+1e-6),1)+max(MinInnerRing/(Ang+1e-6),1))/2),3)+MinRing;
			
			float horizonStart = sqrt(acos(InnerRing)/acos(0.0)); // Latitude where inner ring dips below horizon
            float horizonEnd   = sqrt(acos(OuterRing)/acos(0.0)); // Latitude where outer ring dips below horizon
          
            float horizonVisibility = 1.0 - smoothstep(horizonStart, horizonEnd, latSine);
			float nightVisibility = 1.0 - smoothstep(0.0, horizonEnd, latSine);

		   
			
// Planet shadow on rings
    
    vec2 lonNormal = normalize(Normal.xz + 1e-6);
    vec2 lonLight  = normalize(lightVec.xz + 1e-6);
    
    // Calculate the longitude "time of day"
    float lonDot = dot(lonNormal, lonLight);
    
    // Midnight fade: 0.0 at midnight (lonDot = -1.0), 1.0 at terminator (lonDot = 0.0)
    float midnightFade = smoothstep(-1.0, 0.0, lonDot);
    float nightShadow = min(1, mix(MinIllum, 1, midnightFade)); //min(1, mix(abs(ringNormalL*ringNormalL*ringNormalL)*MeanRing + MinRing, latSine*horizonEnd, midnightFade));
    // ----------------------------------------------
			

            
            float ringIntensity = abs(ringNormalL) * latSine * nightShadow;  //horizonVisibility
            float ringIllum = mix(0.05, 0.25, sameSide) * ringIntensity;
            
            // Calculate the ring light color
            vec3 ringShine = LightColor[i].rgb * ringIllum * RingsParams.z;
            
            // Fake out my Night culling
            float savedEyeMuS = EyeMuS;
            
            // Fake Ring position in sky relative to atmosphere
            EyeMuS = 1-pow(latSine/(horizonEnd),2);             //1-((Radiuses.y + Radiuses.z*3.14)/(Radiuses.y))*(latSine)/horizonEnd; 
            
            Inscatter += inscatterSky(vec3(0.0)) * ringShine; 
            
            // Restore night
            EyeMuS = savedEyeMuS;
            // ---------------------------------
        #endif
        // -----------------------------
  
  }

    FragColor = vec4(Inscatter, 0.0);

    // Limit the brightness while preserving color
    float luma = max(FragColor.r, max(FragColor.g, FragColor.b));
    FragColor.rgb *= clamp(65000.0 / (luma + 1.0e-10), 0.0, 1.0);
}

#endif // _FRAGMENT_

//=============================================================================
