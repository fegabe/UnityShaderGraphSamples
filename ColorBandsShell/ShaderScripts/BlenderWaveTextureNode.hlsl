#define M_PI 3.1415926535897932       /* pi */

#include "gpu_shader_material_noise.hlsl"

/* The fractal_noise functions are all exactly the same except for the input type. */
float fractal_noise(float p, float octaves)
{
	float fscale = 1.0;
	float amp = 1.0;
	float sum = 0.0;
	octaves = clamp(octaves, 0.0, 16.0);
	int n = int(octaves);
	for (int i = 0; i <= n; i++) {
		float t = noise(fscale * p);
		sum += t * amp;
		amp *= 0.5;
		fscale *= 2.0;
	}
	float rmd = octaves - floor(octaves);
	if (rmd != 0.0) {
		float t = noise(fscale * p);
		float sum2 = sum + t * amp;
		sum *= (float(1 << n) / float((1 << (n + 1)) - 1));
		sum2 *= (float(1 << (n + 1)) / float((1 << (n + 2)) - 1));
		return (1.0 - rmd) * sum + rmd * sum2;
	}
	else {
		sum *= (float(1 << n) / float((1 << (n + 1)) - 1));
		return sum;
	}
}

float calc_wave(float3 p, float distortion, float detail, float detail_scale, int wave_type, int wave_profile)
{
	float n;

	if (wave_type == 0) { /* type bands */
		n = (p.x + p.y + p.z) * 10.0;
	}
	else { /* type rings */
		n = length(p) * 20.0;
	}

	if (distortion != 0.0) {
		n += distortion * fractal_noise(p * detail_scale, detail);
	}

	if (wave_profile == 0) { /* profile sin */
		return 0.5 + 0.5 * sin(n);
	}
	else { /* profile saw */
		n /= 2.0 * M_PI;
		n -= int(n);
		return (n < 0.0) ? n + 1.0 : n;
	}
}

void node_tex_wave_float(
	float3 coord,
	float scale,
	float distortion,
	float detail,
	float detail_scale,
	float wave_type,
	float wave_profile,
	out float4 color,
	out float fac)
{
	float f;
	f = calc_wave(coord * scale, distortion, detail, detail_scale, int(wave_type), int(wave_profile));

	color = float4(f, f, f, 1.0);
	fac = f;
}
