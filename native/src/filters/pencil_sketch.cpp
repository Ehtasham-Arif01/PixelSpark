#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_pencil_sketch(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Convert to grayscale
    std::vector<uint8_t> gray(n);
    to_grayscale_1ch(rgba, gray.data(), w, h);

    // Invert grayscale
    std::vector<uint8_t> inv(n);
    for (int i = 0; i < n; i++) inv[i] = 255 - gray[i];

    // Blur the inverted image
    std::vector<uint8_t> blur(n);
    gaussian_blur_1ch(inv.data(), blur.data(), w, h, 8.f);

    // Color dodge blend: gray / (1 - blur/255)
    for (int i = 0; i < n; i++) {
        float g = gray[i] / 255.f;
        float b = blur[i] / 255.f;
        float denom = 1.f - b;
        float v = (denom < 0.01f) ? 255.f : std::min(1.f, g / denom) * 255.f;
        uint8_t pv = clamp_u8f(v);
        out[i*4+0] = pv;
        out[i*4+1] = pv;
        out[i*4+2] = pv;
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
