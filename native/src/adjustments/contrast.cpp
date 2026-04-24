#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* adjust_contrast(const uint8_t* rgba, int w, int h, float value, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // value: -100..+100
    // factor: maps -100 → 0.0 (flat gray), 0 → 1.0, +100 → ~3.0
    float factor = (value >= 0)
        ? 1.f + value / 50.f
        : 1.f + value / 100.f;  // gentle reduction

    uint8_t lut[256];
    for (int i = 0; i < 256; i++) {
        float v = (i - 128.f) * factor + 128.f;
        lut[i] = clamp_u8f(v);
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
