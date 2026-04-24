#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_sepia(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;
    for (int i = 0; i < n; i++) {
        float r = rgba[i*4+0], g = rgba[i*4+1], b = rgba[i*4+2];
        out[i*4+0] = clamp_u8f(r*0.393f + g*0.769f + b*0.189f);
        out[i*4+1] = clamp_u8f(r*0.349f + g*0.686f + b*0.168f);
        out[i*4+2] = clamp_u8f(r*0.272f + g*0.534f + b*0.131f);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
