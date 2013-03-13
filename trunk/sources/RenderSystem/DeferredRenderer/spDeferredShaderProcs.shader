/*
 * Deferred shader procedures file
 * 
 * This file is part of the "SoftPixel Engine" (Copyright (c) 2008 by Lukas Hermanns)
 * See "SoftPixelEngine.hpp" for license information.
 */

float GetAngle(in float3 a, in float3 b)
{
    return acos(dot(a, b));
}

void Frustum(inout float4 v, in float w, in float h)
{
    float aspect = (w*3.0) / (h*4.0);
    v.x = (v.x - w*0.5) / (w*0.5) * aspect;
    v.y = (v.y - h*0.5) / (w*0.5) * aspect;
}

#ifdef _DEB_INVVIEWPROJ_
void Frustum2(inout float4 v, in float w, in float h)
{
    v.x = (v.x - w*0.5) / (w*0.5);
    v.y = (v.y - h*0.5) / (h*0.5);
}
#endif

#ifdef SHADOW_MAPPING

// Chebyshev inequality function for VSM (variance shadow maps)
// see GPUGems3 at nVIDIA for more details: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch08.html
float ChebyshevUpperBound(in float2 Moments, in float t)
{
    /* One-tailed inequality valid if t > Moments.x */
	float p = step(t, Moments.x);
	
    /* Compute variance */
    float Variance = Moments.y - (Moments.x*Moments.x);
    Variance = max(Variance, MIN_VARIANCE);
    
    /* Compute probabilistic upper bound. */
    float d = t - Moments.x;
    float p_max = Variance / (Variance + d*d);
    
    return max(p, p_max);
}

float LinStep(in float min, in float max, in float v)
{
    return saturate((v - min) / (max - min));
}

float ReduceLightBleeding(in float p_max, in float Amount)
{
    /* remove the [0, amount] ail and linearly rescale [amount, 1] */
    return LinStep(Amount, 1.0, p_max);
}

float ShadowContribution(in float2 Moments, in float LightDistance)
{
    /* Compute the Chebyshev upper bound */
    float p_max = ChebyshevUpperBound(Moments, LightDistance);
    return ReduceLightBleeding(p_max, 0.6);
}

float4 Projection(in float4x4 ProjectionMatrix, in float4 Point)
{
    float4 ProjectedPoint = ProjectionMatrix * Point;

    ProjectedPoint.xy = (ProjectedPoint.xy / float2(ProjectedPoint.w) + float2(1.0)) * float2(0.5);

    return ProjectedPoint;
}

#endif

void ComputeLightShading(
    in SLight Light, in SLightEx LightEx,
    in float3 Point, in float3 Normal, in float Shininess, in float3 ViewDir,
	#ifdef HAS_LIGHT_MAP
	inout float3 StaticDiffuseColor, inout float3 StaticSpecularColor,
	#endif
    inout float3 DiffuseColor, inout float3 SpecularColor)
{
    /* Compute light direction vector */
    float3 LightDir = float3(0.0);
	
    if (Light.Type != LIGHT_DIRECTIONAL)
        LightDir = normalize(Point - Light.PositionAndRadius.xyz);
    else
        LightDir = LightEx.Direction;
	
    /* Compute phong shading */
    float NdotL = max(AMBIENT_LIGHT_FACTOR, -dot(Normal, LightDir));
	
    /* Compute light attenuation */
    float Distance = distance(Point, Light.PositionAndRadius.xyz);
	
    float AttnLinear    = Distance / Light.PositionAndRadius.w;
    float AttnQuadratic = AttnLinear * Distance;
	
    float Intensity = 1.0 / (1.0 + AttnLinear + AttnQuadratic);
	
    if (Light.Type == LIGHT_SPOT)
    {
        /* Compute spot light cone */
        float Angle = GetAngle(LightDir, LightEx.Direction);
        float ConeAngleLerp = (Angle - LightEx.SpotTheta) / LightEx.SpotPhiMinusTheta;
		
        Intensity *= saturate(1.0 - ConeAngleLerp);
    }

    /* Compute diffuse color */
    float3 Diffuse = Light.Color * float3(Intensity * NdotL);

    /* Compute specular color */
    float3 Reflection = normalize(reflect(LightDir, Normal));

    float NdotHV = -dot(ViewDir, Reflection);

    float3 Specular = Light.Color * float3(Intensity * pow(max(0.0, NdotHV), Shininess));

    #ifdef SHADOW_MAPPING
	
    /* Apply shadow */
    if (Light.ShadowIndex != -1)
    {
        if (Light.Type == LIGHT_POINT)
        {
            //todo
        }
        else if (Light.Type == LIGHT_SPOT)
        {
            /* Get shadow map texture coordinate */
            float4 ShadowTexCoord = Projection(LightEx.Projection, float4(Point, 1.0));
			
            if ( ShadowTexCoord.x >= 0.0 && ShadowTexCoord.x <= 1.0 &&
                 ShadowTexCoord.y >= 0.0 && ShadowTexCoord.y <= 1.0 &&
                 ShadowTexCoord.z < 0.0 )
            {
                /* Adjust texture coordinate */
                ShadowTexCoord.x = 1.0 - ShadowTexCoord.x;
                ShadowTexCoord.z = float(Light.ShadowIndex);
                ShadowTexCoord.w = 2.0;
				
                /* Sample moments from shadow map */
                float2 Moments = tex2DArrayLod(DirLightShadowMaps, ShadowTexCoord).ra;
				
                /* Compute shadow contribution */
                float Shadow = ShadowContribution(Moments, Distance);
				
                Diffuse *= float3(Shadow);
                Specular *= float3(Shadow);
            }
			
			#ifdef GLOBAL_ILLUMINATION
			
			/* Compute indirect lights */
			float3 IndirectTexCoord = float3(0.0, 0.0, float(Light.ShadowIndex));
			
			for (int i = 0; i < 10; ++i)
			{
				IndirectTexCoord.x = float(i) * 0.1;
				
				for (int j = 0; j < 10; ++j)
				{
					IndirectTexCoord.y = float(j) * 0.1;
					
					/* Get color and normal from indirect light */
					float IndirectDist		= tex2DArray(DirLightShadowMaps, IndirectTexCoord).r;
					float3 IndirectColor	= tex2DArray(DirLightDiffuseMaps, IndirectTexCoord).rgb;
					float3 IndirectNormal	= tex2DArray(DirLightNormalMaps, IndirectTexCoord).rgb;
					
					IndirectNormal = IndirectNormal * float3(2.0) - float3(1.0);
					
					/* Get the indirect light's position */
					float3 IndirectPoint = normalize(float3(IndirectTexCoord.x*2.0 - 1.0, IndirectTexCoord.y*2.0 - 1.0, 1.0));
					IndirectPoint = (LightEx.ViewTransform * float4(IndirectPoint * float3(IndirectDist), 1.0)).xyz;
					
					/* Compute phong shading for indirect light */
					float NdotIL = max(0.0, -dot(Normal, IndirectNormal));
					
					/* Compute light attenuation */
					float DistanceIL = distance(Point, IndirectPoint);
					
					float AttnLinearIL    = DistanceIL * 10.0;
					float AttnQuadraticIL = AttnLinearIL * DistanceIL;
					
					float IntensityIL = 1.0 / (1.0 + AttnLinearIL + AttnQuadraticIL);
					
					/* Shade indirect light */
					Diffuse += Light.Color * IndirectColor * float3(IntensityIL * NdotIL);
				}
			}
			
			#endif
        }
    }
	
    #endif
	
    /* Add light color */
	#ifdef HAS_LIGHT_MAP
	
	if (Light.UsedForLightmaps != 0)
	{
		StaticDiffuseColor += Diffuse;
		StaticSpecularColor += Specular;
	}
	else
	{
		DiffuseColor += Diffuse;
		SpecularColor += Specular;
	}
	
	#else
	
    DiffuseColor += Diffuse;
    SpecularColor += Specular;
	
	#endif
}