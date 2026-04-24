#pragma once
#include <cstdint>
#include <cmath>
#include <algorithm>
#include <cstring>
#include <new>
#include <vector>

// ─── Clamp helpers ────────────────────────────────────────────────────────────
inline uint8_t clamp_u8(int v)   { return static_cast<uint8_t>(v < 0 ? 0 : v > 255 ? 255 : v); }
inline uint8_t clamp_u8f(float v){ return static_cast<uint8_t>(v < 0.f ? 0 : v > 255.f ? 255 : static_cast<int>(v + 0.5f)); }
inline float   clampf(float v, float lo, float hi){ return v < lo ? lo : v > hi ? hi : v; }

// ─── Image view (non-owning) ──────────────────────────────────────────────────
struct Image {
    const uint8_t* data;
    int width, height;
    int stride() const { return width * 4; }
    const uint8_t* px(int x, int y) const { return data + y * stride() + x * 4; }
    bool valid(int x, int y) const { return x >= 0 && x < width && y >= 0 && y < height; }
};

struct MutableImage {
    uint8_t* data;
    int width, height;
    int stride() const { return width * 4; }
    uint8_t* px(int x, int y) { return data + y * stride() + x * 4; }
    const uint8_t* px(int x, int y) const { return data + y * stride() + x * 4; }
    bool valid(int x, int y) const { return x >= 0 && x < width && y >= 0 && y < height; }
};

// ─── Alloc / free ─────────────────────────────────────────────────────────────
inline uint8_t* alloc_output(int width, int height) {
    return new (std::nothrow) uint8_t[static_cast<size_t>(width) * height * 4]();
}

// ─── Color space conversions ──────────────────────────────────────────────────
inline void rgb_to_hsv(float r, float g, float b, float& h, float& s, float& v) {
    float mx = std::max({r, g, b}), mn = std::min({r, g, b});
    float d = mx - mn;
    v = mx;
    s = (mx < 1e-6f) ? 0.f : d / mx;
    if (d < 1e-6f) { h = 0.f; return; }
    if      (mx == r) h = (g - b) / d + (g < b ? 6.f : 0.f);
    else if (mx == g) h = (b - r) / d + 2.f;
    else              h = (r - g) / d + 4.f;
    h /= 6.f;
}

inline void hsv_to_rgb(float h, float s, float v, float& r, float& g, float& b) {
    if (s < 1e-6f) { r = g = b = v; return; }
    int   i = static_cast<int>(h * 6.f);
    float f = h * 6.f - i;
    float p = v * (1.f - s);
    float q = v * (1.f - f * s);
    float t = v * (1.f - (1.f - f) * s);
    switch (i % 6) {
        case 0: r=v; g=t; b=p; break;
        case 1: r=q; g=v; b=p; break;
        case 2: r=p; g=v; b=t; break;
        case 3: r=p; g=q; b=v; break;
        case 4: r=t; g=p; b=v; break;
        default:r=v; g=p; b=q; break;
    }
}

// ─── Gaussian helpers ────────────────────────────────────────────────────────
inline int gaussian_radius(float sigma) {
    return std::max(1, static_cast<int>(std::ceil(sigma * 3.f)));
}

inline void gaussian_kernel_1d(float sigma, int radius, std::vector<float>& k) {
    int sz = 2 * radius + 1;
    k.resize(sz);
    float sum = 0.f;
    for (int i = 0; i < sz; i++) {
        float x = i - radius;
        k[i] = std::exp(-(x * x) / (2.f * sigma * sigma));
        sum += k[i];
    }
    for (float& v : k) v /= sum;
}

// Separable Gaussian blur on a single-channel image (in-place)
void gaussian_blur_1ch(const uint8_t* src, uint8_t* dst, int w, int h, float sigma);

// Separable Gaussian blur on RGBA (alpha untouched)
void gaussian_blur_rgba(const uint8_t* src, uint8_t* dst, int w, int h, float sigma);

// Grayscale: returns luminance for each pixel (output is w*h bytes)
void to_grayscale_1ch(const uint8_t* rgba, uint8_t* gray, int w, int h);
