//
//  GlowingWaves.metal
//  Lagoon
//
//  Metal shader for glowing waves animation
//  Inspired by GLSL shader Chromatic Resonance by Philippe Desgranges
//

#include <metal_stdlib>
using namespace metal;

struct WaveVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex WaveVertexOut waveVertexShader(uint vertexID [[vertex_id]], constant float2 *resolution [[buffer(1)]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    WaveVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

float waveN2(float2 p) {
    p = fmod(p, float2(1456.2346));
    float3 p3 = fract(float3(p.xyx) * float3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float waveCosineInterpolate(float y1, float y2, float t) {
    float mu = (1.0 - cos(t * 3.14159265359)) * 0.5;
    return (y1 * (1.0 - mu) + y2 * mu);
}

float waveNoise2(float2 uv) {
    float2 corner = floor(uv);
    float c00 = waveN2(corner + float2(0.0, 0.0));
    float c01 = waveN2(corner + float2(0.0, 1.0));
    float c11 = waveN2(corner + float2(1.0, 1.0));
    float c10 = waveN2(corner + float2(1.0, 0.0));

    float2 diff = fract(uv);

    return waveCosineInterpolate(waveCosineInterpolate(c00, c10, diff.x), waveCosineInterpolate(c01, c11, diff.x), diff.y);
}

float waveLineNoise(float x, float t) {
    float n = waveNoise2(float2(x * 0.6, t * 0.2));
    return n - 0.5;
}

float waveLine(float2 uv, float t, float scroll) {
    float ax = abs(uv.x);
    uv.y *= 0.5 + ax * ax * 0.3;
    uv.y *= 1.2;  // Lower = taller waves (was 5)
    uv.x += t * scroll;

    float n1 = waveLineNoise(uv.x, t);
    float n2 = waveLineNoise(uv.x + 0.5, t + 10.0) * 2.0;

    float ay = abs(uv.y - n1);
    float lum = smoothstep(0.02, 0.00, ay) * 1.5;
    lum += smoothstep(1.5, 0.00, ay) * 0.1;

    float r = (uv.y - n1) / (n2 - n1);
    float h = clamp(1.0 - r, 0.0, 1.0);
    if (r > 0.0) lum = max(lum, h * h * 0.7);

    return lum;
}

fragment float4 waveFragmentShader(WaveVertexOut in [[stage_in]], constant float &iTime [[buffer(0)]]) {
    #define pi 3.14159265359
    #define pi2 (pi * 2.0)

    float2 uv = (2.0 * in.uv - 1.0);

    float lum = waveLine(uv * float2(2.0, 1.0), iTime * 0.3, 0.1) * 0.6;
    lum += waveLine(uv * float2(1.5, 0.9) + float2(0.33, 0.0), iTime * 0.5 + 45.0, 0.15) * 0.5;
    lum += waveLine(uv * float2(1.3, 1.2) + float2(0.66, 0.0), iTime * 0.4 + 67.3, 0.2) * 0.3;
    lum += waveLine(uv * float2(1.5, 1.15) + float2(0.8, 0.0), iTime * 0.77 + 1235.45, 0.23) * 0.43;
    lum += waveLine(uv * float2(1.5, 1.15) + float2(0.8, 0.0), iTime * 0.77 + 456.45, 0.3) * 0.25;

    float ax = abs(uv.x);
    lum += ax * ax * 0.005;

    // pH ideal color: #0AAAC6 (cyan/türkis)
    float3 phColor = float3(10.0/255.0, 170.0/255.0, 198.0/255.0);
    // Chlorine ideal color: #1FBF4A (grün)
    float3 clColor = float3(31.0/255.0, 191.0/255.0, 74.0/255.0);

    // Blend between the two colors based on position and time
    float blend = sin(uv.x * 2.0 + iTime * 0.3) * 0.5 + 0.5;
    float3 hue = mix(phColor, clColor, blend);

    float3 col;
    float thres = 0.7;
    if (lum < thres)
        col = hue * lum / thres;
    else
        col = float3(1.0) - (float3(1.0 - (lum - thres)) * (float3(1.0) - hue));

    float alpha = saturate(col.r + col.g + col.b);

    float4 premultipliedColor = float4(col, alpha);

    return premultipliedColor;
}
