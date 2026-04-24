#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

// Quantize a value to N levels
static inline uint8_t quantize(uint8_t v, int levels) {
    float step = 255.f / (levels - 1);
    return clamp_u8f(std::round(v / step) * step);
}

extern "C" {

uint8_t* apply_cartoon(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Step 1: Bilateral-like smooth (2-pass blur to flatten areas)
    std::vector<uint8_t> smooth(n * 4);
    gaussian_blur_rgba(rgba, smooth.data(), w, h, 3.f);

    std::vector<uint8_t> smooth2(n * 4);
    gaussian_blur_rgba(smooth.data(), smooth2.data(), w, h, 3.f);

    // Step 2: Edge mask from grayscale (Sobel magnitude)
    std::vector<uint8_t> gray(n);
    to_grayscale_1ch(rgba, gray.data(), w, h);

    std::vector<uint8_t> gblur(n);
    gaussian_blur_1ch(gray.data(), gblur.data(), w, h, 1.5f);

    std::vector<uint8_t> edges(n, 0);
    for (int y = 1; y < h-1; y++) {
        for (int x = 1; x < w-1; x++) {
            int Gx = -gblur[(y-1)*w+(x-1)] + gblur[(y-1)*w+(x+1)]
                     -2*gblur[y*w+(x-1)]    + 2*gblur[y*w+(x+1)]
                     -gblur[(y+1)*w+(x-1)]  + gblur[(y+1)*w+(x+1)];
            int Gy = -gblur[(y-1)*w+(x-1)] - 2*gblur[(y-1)*w+x] - gblur[(y-1)*w+(x+1)]
                     +gblur[(y+1)*w+(x-1)] + 2*gblur[(y+1)*w+x] + gblur[(y+1)*w+(x+1)];
            int mag = static_cast<int>(std::sqrt(float(Gx*Gx + Gy*Gy)));
            edges[y*w+x] = clamp_u8(mag);
        }
    }

    // Step 3: Combine quantized color + dark edges
    const int LEVELS = 6;
    for (int i = 0; i < n; i++) {
        float edge_w = 1.f - std::min(1.f, edges[i] / 80.f);  // edge darkens
        out[i*4+0] = clamp_u8f(quantize(smooth2[i*4+0], LEVELS) * edge_w);
        out[i*4+1] = clamp_u8f(quantize(smooth2[i*4+1], LEVELS) * edge_w);
        out[i*4+2] = clamp_u8f(quantize(smooth2[i*4+2], LEVELS) * edge_w);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
