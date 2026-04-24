#include "../include/utils.h"

void gaussian_blur_1ch(const uint8_t* src, uint8_t* dst, int w, int h, float sigma) {
    int r = gaussian_radius(sigma);
    std::vector<float> k;
    gaussian_kernel_1d(sigma, r, k);

    // Horizontal pass → temp
    std::vector<float> tmp(static_cast<size_t>(w) * h);
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float acc = 0.f;
            for (int i = -r; i <= r; i++) {
                int sx = std::max(0, std::min(w - 1, x + i));
                acc += src[y * w + sx] * k[i + r];
            }
            tmp[y * w + x] = acc;
        }
    }
    // Vertical pass → dst
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float acc = 0.f;
            for (int i = -r; i <= r; i++) {
                int sy = std::max(0, std::min(h - 1, y + i));
                acc += tmp[sy * w + x] * k[i + r];
            }
            dst[y * w + x] = clamp_u8f(acc);
        }
    }
}

void gaussian_blur_rgba(const uint8_t* src, uint8_t* dst, int w, int h, float sigma) {
    int r = gaussian_radius(sigma);
    std::vector<float> k;
    gaussian_kernel_1d(sigma, r, k);

    int stride = w * 4;
    std::vector<float> tmp(static_cast<size_t>(w) * h * 4, 0.f);

    // Horizontal pass
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float R=0,G=0,B=0;
            for (int i = -r; i <= r; i++) {
                int sx = std::max(0, std::min(w-1, x+i));
                float wt = k[i+r];
                const uint8_t* p = src + y*stride + sx*4;
                R += p[0]*wt; G += p[1]*wt; B += p[2]*wt;
            }
            float* t = &tmp[(y*w+x)*4];
            t[0]=R; t[1]=G; t[2]=B;
            t[3] = src[y*stride+x*4+3]; // preserve alpha
        }
    }
    // Vertical pass
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float R=0,G=0,B=0;
            for (int i = -r; i <= r; i++) {
                int sy = std::max(0, std::min(h-1, y+i));
                float wt = k[i+r];
                const float* t = &tmp[(sy*w+x)*4];
                R += t[0]*wt; G += t[1]*wt; B += t[2]*wt;
            }
            uint8_t* d = dst + y*stride + x*4;
            d[0]=clamp_u8f(R); d[1]=clamp_u8f(G); d[2]=clamp_u8f(B);
            d[3] = static_cast<uint8_t>(tmp[(y*w+x)*4+3]);
        }
    }
}

void to_grayscale_1ch(const uint8_t* rgba, uint8_t* gray, int w, int h) {
    int n = w * h;
    for (int i = 0; i < n; i++) {
        gray[i] = clamp_u8f(0.299f*rgba[i*4] + 0.587f*rgba[i*4+1] + 0.114f*rgba[i*4+2]);
    }
}
