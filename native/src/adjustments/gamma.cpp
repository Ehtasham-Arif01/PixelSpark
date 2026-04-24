#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

extern "C" {

uint8_t* apply_gamma(const uint8_t* rgba, int w, int h, float gamma, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    if (gamma < 0.01f) gamma = 0.01f;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // LUT: output = (input/255)^(1/gamma) * 255
    uint8_t lut[256];
    float inv_gamma = 1.f / gamma;
    for (int i = 0; i < 256; i++) {
        lut[i] = clamp_u8f(std::pow(i / 255.f, inv_gamma) * 255.f);
    }
    for (int i = 0; i < n; i++) {
        out[i*4+0] = lut[rgba[i*4+0]];
        out[i*4+1] = lut[rgba[i*4+1]];
        out[i*4+2] = lut[rgba[i*4+2]];
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
