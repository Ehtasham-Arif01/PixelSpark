#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_grayscale(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;
    for (int i = 0; i < n; i++) {
        uint8_t g = clamp_u8f(0.299f*rgba[i*4] + 0.587f*rgba[i*4+1] + 0.114f*rgba[i*4+2]);
        out[i*4+0] = g;
        out[i*4+1] = g;
        out[i*4+2] = g;
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
