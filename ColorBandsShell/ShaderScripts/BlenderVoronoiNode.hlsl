#include "util_hash.hlsl"

/* SSE Versions Of Jenkins Lookup3 Hash Functions */

#define NODE_VORONOI_EUCLIDEAN 0
#define NODE_VORONOI_MANHATTAN 1
#define NODE_VORONOI_CHEBYCHEV 2
#define NODE_VORONOI_MINKOWSKI 3

inline float voronoi_distance_3d(float3 a,
	float3 b,
	int metric,
	float exponent)
{
	if (metric == NODE_VORONOI_EUCLIDEAN) {
		return distance(a, b);
	}
	else if (metric == NODE_VORONOI_MANHATTAN) {
		return fabsf(a.x - b.x) + fabsf(a.y - b.y) + fabsf(a.z - b.z);
	}
	else if (metric == NODE_VORONOI_CHEBYCHEV) {
		return max(fabsf(a.x - b.x), max(fabsf(a.y - b.y), fabsf(a.z - b.z)));
	}
	else if (metric == NODE_VORONOI_MINKOWSKI) {
		return powf(powf(fabsf(a.x - b.x), exponent) + powf(fabsf(a.y - b.y), exponent) +
			powf(fabsf(a.z - b.z), exponent),
			1.0f / exponent);
	}
	else {
		return 0.0f;
	}
}

void Blender_Voronoi_float(float3 coord, float smoothness, float exponent, float randomness, int metric, out float outDistance, out float3 outColor, out float3 outPosition)
{
	float3 cellPosition = floor(coord);
	float3 localPosition = coord - cellPosition;

	float smoothDistance = 8.0f;
	float3 smoothColor = make_float3(0.0f, 0.0f, 0.0f);
	float3 smoothPosition = make_float3(0.0f, 0.0f, 0.0f);
	for (int k = -2; k <= 2; k++) {
		for (int j = -2; j <= 2; j++) {
			for (int i = -2; i <= 2; i++) {
				float3 cellOffset = make_float3(i, j, k);
				float3 pointPosition = cellOffset +
					hash_float3_to_float3(cellPosition + cellOffset) * randomness;
				float distanceToPoint = voronoi_distance_3d(
					pointPosition, localPosition, metric, exponent);
				float h = smoothstep(
					0.0f, 1.0f, 0.5f + 0.5f * (smoothDistance - distanceToPoint) / smoothness);
				float correctionFactor = smoothness * h * (1.0f - h);
				smoothDistance = lerp(smoothDistance, distanceToPoint, h) - correctionFactor;
				correctionFactor /= 1.0f + 3.0f * smoothness;
				float3 cellColor = hash_float3_to_float3(cellPosition + cellOffset);
				smoothColor = lerp(smoothColor, cellColor, h) - correctionFactor;
				smoothPosition = lerp(smoothPosition, pointPosition, h) - correctionFactor;
			}
		}
	}

	outColor = smoothColor;
	outDistance = smoothDistance;
	outPosition = cellPosition + smoothPosition;
}