"/*\n"
" * Lightmap generation D3D11 shader file\n"
" * \n"
" * This file is part of the \"SoftPixel Engine\" (Copyright (c) 2008 by Lukas Hermanns)\n"
" * See \"SoftPixelEngine.hpp\" for license information.\n"
" */\n"
"/*\n"
" * HLSL (SM 5) shader core file\n"
" * \n"
" * This file is part of the \"SoftPixel Engine\" (Copyright (c) 2008 by Lukas Hermanns)\n"
" * See \"SoftPixelEngine.hpp\" for license information.\n"
" */\n"
"#define PI      3.14159265359\n"
"#define E      2.71828182846\n"
"#define MUL(m, v)    mul(m, v)\n"
"#define MUL_TRANSPOSED(v, m) mul(v, m)\n"
"#define MUL_NORMAL(n)   (n).xyz = mul((n).xyz, float3x3(Tangent, Binormal, Normal))\n"
"#define CAST(t, v)    ((t)(v))\n"
"#define SAMPLER2D(n, i)   Texture2D n : register(t##i); SamplerState Sampler##n : register(s##i)\n"
"#define SAMPLER2DARRAY(n, i) Texture2DArray n : register(t##i); SamplerState Sampler##n : register(s##i)\n"
"#define SAMPLERCUBEARRAY(n, i) TextureCubeArray n : register(t##i); SamplerState Sampler##n : register(s##i)\n"
"#define mod(a, b)    fmod(a, b)\n"
"#define floatBitsToInt(v)  asint(v)\n"
"#define floatBitsToUInt(v)  asuint(v)\n"
"#define intBitsToFloat(v)  asfloat(v)\n"
"#define uintBitsToFloat(v)  asfloat(v)\n"
"#define tex2D(s, t)    s.Sample(Sampler##s, t)\n"
"#define tex2DArray(s, t)  s.SampleLevel(Sampler##s, t.xyz)\n"
"#define tex2DArrayLod(s, t)  s.SampleLevel(Sampler##s, t.xyz, t.w)\n"
"#define tex2DGrad(s, t, x, y) s.SampleGrad(Sampler##s, t, x, y)\n"
"#define RWTexture3DUInt   RWTexture3D<uint>\n"
"inline void InterlockedImageCompareExchange(RWTexture3DUInt Image, int3 Coord, uint Compare, uint Value, out uint Result)\n"
"{\n"
" InterlockedCompareExchange(Image[Coord], Compare, Value, Result);\n"
"}\n"
"/*\n"
" * Lightmap generation shader header file\n"
" * \n"
" * This file is part of the \"SoftPixel Engine\" (Copyright (c) 2008 by Lukas Hermanns)\n"
" * See \"SoftPixelEngine.hpp\" for license information.\n"
" */\n"
"#define ID_NONE     0xFFFFFFFF\n"
"#define EPSILON     0.0001\n"
"#define PLANE_NORMAL(Plane)  ((Plane).xyz)\n"
"#define PLANE_DISTANCE(Plane) ((Plane).w)\n"
"#define SPHERE_POINT(Sphere) ((Sphere).xyz)\n"
"#define SPHERE_RADIUS(Sphere) ((Sphere).w)\n"
"#define SPlane     float4\n"
"#define MAX_STACK_SIZE   64\n"
"/*#define THREAD_GROUP_NUM_X  8\n"
"#define THREAD_GROUP_NUM_Y  8\n"
"#define THREAD_GROUP_SIZE  (THREAD_GROUP_NUM_X * THREAD_GROUP_NUM_Y)*/\n"
"#define LIGHT_DIRECTIONAL  0\n"
"#define LIGHT_POINT    1\n"
"#define LIGHT_SPOT    2\n"
"#define KDTREE_XAXIS   0\n"
"#define KDTREE_YAXIS   1\n"
"#define KDTREE_ZAXIS   2\n"
"struct STriangle\n"
"{\n"
" float3 A, B, C;\n"
"};\n"
"struct SRay\n"
"{\n"
" float3 Origin, Direction;\n"
"};\n"
"struct SLine\n"
"{\n"
" float3 Start, End;\n"
"};\n"
"struct SKDTreeNode\n"
"{\n"
" int Axis;\n"
" float Distance;\n"
" uint TriangleStart; //!< Index to 'TriangleIdList' or ID_NONE\n"
" uint NumTriangles; //!< Length in 'TriangleIdList' or 0\n"
" uint ChildIds[2]; //!< Index to 'NodeList' or ID_NONE\n"
"};\n"
"struct SLightSource\n"
"{\n"
" int Type;\n"
" float4 Sphere;\n"
" float3 Color;\n"
" float3 Direction;\n"
" float SpotTheta;\n"
" float SpotPhiMinusTheta;\n"
"};\n"
"struct SLightmapTexel\n"
"{\n"
" float3 WorldPos;\n"
" float3 Normal;\n"
" float3 Tangent;\n"
"};\n"
"struct SIdStack\n"
"{\n"
" uint Data[MAX_STACK_SIZE];\n"
" uint Pointer;\n"
"};\n"
"cbuffer BufferMain : register(b0)\n"
"{\n"
" float4x4 InvWorldMatrix : packoffset(c0);\n"
" float4 AmbientColor  : packoffset(c4);\n"
" uint NumLights   : packoffset(c5);\n"
" uint2 LightmapSize  : packoffset(c5.y);\n"
"};\n"
"cbuffer BufferRadiositySetup : register(b1)\n"
"{\n"
" uint NumRadiosityRays : packoffset(c0);\n"
" float RadiosityFactor : packoffset(c0.y); // (1.0 / NumRadiosityRays) * Factor\n"
"}\n"
"cbuffer BufferRadiosityRays : register(b2)\n"
"{\n"
" float4 RadiosityDirections[4096];\n"
"};\n"
"StructuredBuffer<SLightSource> LightList : register(t0);\n"
"StructuredBuffer<SLightmapTexel> LightmapGrid : register(t1);  // Active lightmap texels (one draw-call for every lightmap texture)\n"
"StructuredBuffer<STriangle> TriangleList : register(t2);\n"
"StructuredBuffer<SKDTreeNode> NodeList : register(t3);\n"
"Buffer<uint> TriangleIdList : register(t4);\n"
"/*\n"
"Input lightmap image (will be a copy of \"OutputLightmap\" after\n"
"direct illumination was computed, and will be used for indirect illumination).\n"
"*/\n"
"Texture2D<float4> InputLightmap : register(t5);\n"
"RWTexture2D<float4> OutputLightmap : register(u0); // Output lightmap image\n"
"groupshared SIdStack Stack;\n"
"/*\n"
" * Lightmap generation shader procedures file\n"
" * \n"
" * This file is part of the \"SoftPixel Engine\" (Copyright (c) 2008 by Lukas Hermanns)\n"
" * See \"SoftPixelEngine.hpp\" for license information.\n"
" */\n"
"void StackInit()\n"
"{\n"
" Stack.Pointer = 0;\n"
"}\n"
"bool StackEmpty()\n"
"{\n"
" return Stack.Pointer == 0;\n"
"}\n"
"void StackPush(uint Id)\n"
"{\n"
" Stack.Data[Stack.Pointer] = Id;\n"
" ++Stack.Pointer;\n"
"}\n"
"uint StackPop()\n"
"{\n"
" --Stack.Pointer;\n"
" return Stack.Data[Stack.Pointer];\n"
"}\n"
"SPlane BuildPlane(STriangle Tri)\n"
"{\n"
" SPlane Plane;\n"
" float3 U = Tri.B - Tri.A;\n"
" float3 V = Tri.C - Tri.A;\n"
" PLANE_NORMAL(Plane) = normalize(cross(U, V));\n"
" PLANE_DISTANCE(Plane) = dot(PLANE_NORMAL(Plane), Tri.A);\n"
" return Plane;\n"
"}\n"
"bool IntersectionRayPlane(SPlane Plane, SRay Ray, out float3 Intersection)\n"
"{\n"
" float t = (PLANE_DISTANCE(Plane) - dot(PLANE_NORMAL(Plane), Ray.Origin)) / dot(PLANE_NORMAL(Plane), Ray.Direction);\n"
" if (t >= 0.0)\n"
" {\n"
"  Intersection = Ray.Origin + Ray.Direction * CAST(float3, t);\n"
"  return true;\n"
" }\n"
" return false;\n"
"}\n"
"bool IntersectionRayTriangle(STriangle Tri, SRay Ray, out float3 Intersection)\n"
"{\n"
" float3 pa = Tri.A - Ray.Origin;\n"
" float3 pb = Tri.B - Ray.Origin;\n"
" float3 pc = Tri.C - Ray.Origin;\n"
" Intersection.x = dot(pb, cross(Ray.Direction, pc));\n"
" if (Intersection.x < 0.0)\n"
"  return false;\n"
" Intersection.y = dot(pc, cross(Ray.Direction, pa));\n"
" if (Intersection.y < 0.0)\n"
"  return false;\n"
" Intersection.z = dot(pa, cross(Ray.Direction, pb));\n"
" if (Intersection.z < 0.0)\n"
"  return false;\n"
" return IntersectionRayPlane(BuildPlane(Tri), Ray, Intersection);\n"
"}\n"
"bool IntersectionLinePlane(SPlane Plane, SLine Line, out float3 Intersection)\n"
"{\n"
" float3 Dir = Line.End - Line.Start;\n"
" float t = (PLANE_DISTANCE(Plane) - dot(PLANE_NORMAL(Plane), Line.Start)) / dot(PLANE_NORMAL(Plane), Dir);\n"
" if (t >= 0.0 && t <= 1.0)\n"
" {\n"
"  Intersection = Line.Start + Dir * CAST(float3, t);\n"
"  return true;\n"
" }\n"
" return false;\n"
"}\n"
"bool IntersectionLineTriangle(STriangle Tri, SLine Line, out float3 Intersection)\n"
"{\n"
" float3 pq = Line.End - Line.Start;\n"
" float3 pa = Tri.A - Line.Start;\n"
" float3 pb = Tri.B - Line.Start;\n"
" float3 pc = Tri.C - Line.Start;\n"
" Intersection.x = dot(pb, cross(pq, pc));\n"
" if (Intersection.x < 0.0)\n"
"  return false;\n"
" Intersection.y = dot(pc, cross(pq, pa));\n"
" if (Intersection.y < 0.0)\n"
"  return false;\n"
" Intersection.z = dot(pa, cross(pq, pb));\n"
" if (Intersection.z < 0.0)\n"
"  return false;\n"
" return IntersectionLinePlane(BuildPlane(Tri), Line, Intersection);\n"
"}\n"
"bool OverlapLineTriangle(STriangle Tri, SLine Line)\n"
"{\n"
" float3 Intersection = CAST(float3, 0.0);\n"
" if (IntersectionLineTriangle(Tri, Line, Intersection))\n"
" {\n"
"  return\n"
"   distance(Intersection, Line.Start) < EPSILON && \n"
"   distance(Intersection, Line.End) < EPSILON;\n"
" }\n"
" return false;\n"
"}\n"
"void StackPushNodeChildren(SKDTreeNode Node, SLine Line)\n"
"{\n"
" float3 Vec = Line.End - Line.Start;\n"
" float tmax = length(Vec);\n"
" Vec = normalize(Vec);\n"
" int Axis = Node.Axis;\n"
" int First = (Line.Start[Axis] > Node.Distance);\n"
" if (Vec[Axis] == 0.0)\n"
" {\n"
"  StackPush(Node.ChildIds[First]);\n"
" }\n"
" else\n"
" {\n"
"  float t = (Node.Distance - Line.Start[Axis]) / Vec[Axis];\n"
"  if (t >= 0.0 && t <= tmax)\n"
"  {\n"
"   StackPush(Node.ChildIds[First]);\n"
"   StackPush(Node.ChildIds[First ^ 1]);\n"
"  }\n"
"  else\n"
"  {\n"
"   StackPush(Node.ChildIds[First]);\n"
"  }\n"
" }\n"
"}\n"
"/*bool IntersectionRayMesh()\n"
"{\n"
" return false;\n"
"}*/\n"
"float GetAngle(float3 a, float3 b)\n"
"{\n"
"    return acos(dot(a, b));\n"
"}\n"
"float GetSpotLightIntensity(float3 LightDir, SLightSource Light)\n"
"{\n"
" float Angle = GetAngle(LightDir, Light.Direction);\n"
" float ConeAngleLerp = (Angle - Light.SpotTheta) / Light.SpotPhiMinusTheta;\n"
" return saturate(1.0 - ConeAngleLerp);\n"
"}\n"
"void ComputeLightShading(inout float3 Color, SLightSource Light, SLightmapTexel Texel)\n"
"{\n"
"    /* Compute light direction vector */\n"
"    float3 LightDir = CAST(float3, 0.0);\n"
"    if (Light.Type != LIGHT_DIRECTIONAL)\n"
"        LightDir = normalize(Texel.WorldPos - SPHERE_POINT(Light.Sphere));\n"
"    else\n"
"        LightDir = Light.Direction;\n"
"    /* Compute phong shading */\n"
"    float NdotL = max(0.0, -dot(Texel.Normal, LightDir));\n"
"    /* Compute light attenuation */\n"
"    float Distance = distance(Texel.WorldPos, SPHERE_POINT(Light.Sphere));\n"
"    float AttnLinear    = Distance * SPHERE_RADIUS(Light.Sphere);\n"
"    float AttnQuadratic = AttnLinear * Distance;\n"
"    float Intensity = 1.0 / (1.0 + AttnLinear + AttnQuadratic);\n"
"    if (Light.Type == LIGHT_SPOT)\n"
"  Intensity *= GetSpotLightIntensity(LightDir, Light);\n"
"    /* Compute diffuse color */\n"
"    Color += Light.Color * CAST(float3, Intensity * NdotL);\n"
"}\n"
"bool TexelVisibleFromLight(SLightSource Light, SLightmapTexel Texel)\n"
"{\n"
" SLine Line;\n"
" Line.Start = SPHERE_POINT(Light.Sphere);\n"
" Line.End = Texel.WorldPos;\n"
" Line.Start = MUL(InvWorldMatrix, float4(Line.Start, 1.0)).xyz;\n"
" Line.End = MUL(InvWorldMatrix, float4(Line.End, 1.0)).xyz;\n"
" StackInit();\n"
" uint Id = 0;\n"
" StackPush(Id);\n"
" while (!StackEmpty())\n"
" {\n"
"  Id = StackPop();\n"
"  SKDTreeNode Node = NodeList[Id];\n"
"  if (Node.NumTriangles > 0)\n"
"  {\n"
"   for (uint i = Node.TriangleStart, n = i + Node.NumTriangles; i < n; ++i)\n"
"   {\n"
"    uint TriIndex = TriangleIdList[i];\n"
"    STriangle Tri = TriangleList[TriIndex];\n"
"    if (OverlapLineTriangle(Tri, Line))\n"
"     return false;\n"
"   }\n"
"  }\n"
"  if (Node.ChildIds[0] != ID_NONE && Node.ChildIds[1] != ID_NONE)\n"
"  {\n"
"   StackPushNodeChildren(Node, Line);\n"
"  }\n"
" }\n"
" return true;\n"
"}\n"
"float3 GetRandomRayDirection(float3x3 NormalMatrix, uint Index)\n"
"{\n"
" return MUL(NormalMatrix, RadiosityDirections[Index].xyz);\n"
"}\n"
"bool SampleLightEnergy(SRay Ray, out float3 Color, out float Distance)\n"
"{\n"
" Color = CAST(float3, 0.0);\n"
" Distance = 0.0;\n"
" return false;\n"
"}\n"
"void ComputeRadiosityShading(inout float3 Color, SRay Ray, float3 TexelNormal)\n"
"{\n"
" float3 SampleColor = CAST(float3, 0.0);\n"
" float SampleDistance = 0.0;\n"
" if (SampleLightEnergy(Ray, SampleColor, SampleDistance))\n"
" {\n"
"  float NdotL = max(0.0, dot(TexelNormal, Ray.Direction));\n"
"  Color += SampleColor * CAST(float3, NdotL * RadiosityFactor);\n"
" }\n"
"}\n"
"void GenerateLightmapTexel(inout float3 Color, SLightSource Light, SLightmapTexel Texel)\n"
"{\n"
" if (TexelVisibleFromLight(Light, Texel))\n"
"  ComputeLightShading(Color, Light, Texel);\n"
"}\n"
"[numthreads(1, 1, 1)]\n"
"void ComputeDirectIllumination(uint3 Id : SV_DispatchThreadID)\n"
"{\n"
" uint2 TexelPos = Id.xy;\n"
" SLightmapTexel Texel = LightmapGrid[TexelPos.y * LightmapSize.x + TexelPos.x];\n"
" if (!any(Texel.Normal))\n"
"  return;\n"
" float4 Color = AmbientColor;\n"
" for (uint i = 0; i < NumLights; ++i)\n"
"  GenerateLightmapTexel(Color.rgb, LightList[i], Texel);\n"
" OutputLightmap[TexelPos] = Color;\n"
"}\n"
"[numthreads(1, 1, 1)]\n"
"void ComputeIndirectIllumination(uint3 Id : SV_DispatchThreadID)\n"
"{\n"
" uint2 TexelPos = Id.xy;\n"
" SLightmapTexel Texel = LightmapGrid[TexelPos.y * LightmapSize.x + TexelPos.x];\n"
" if (!any(Texel.Normal))\n"
"  return;\n"
" float3x3 NormalMatrix = float3x3(\n"
"  Texel.Tangent,\n"
"  cross(Texel.Normal, Texel.Tangent),\n"
"  Texel.Normal\n"
" );\n"
" float4 Color = InputLightmap[TexelPos];\n"
" SRay Ray;\n"
" Ray.Origin = Texel.WorldPos;\n"
" for (uint i = 0; i < NumRadiosityRays; ++i)\n"
" {\n"
"  Ray.Direction = GetRandomRayDirection(NormalMatrix, i);\n"
"  ComputeRadiosityShading(Color.rgb, Ray, Texel.Normal);\n"
" }\n"
" OutputLightmap[TexelPos] = Color;\n"
"}\n"