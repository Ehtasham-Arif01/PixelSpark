#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* adjust_brightness(const uint8_t* rgba, int w, int h, float value, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // value: -100..+100 mapped to -100..+100 direct pixel offset
    int delta = static_cast<int>(value);
    for (int i = 0; i < n; i++) {
        out[i*4+0] = clamp_u8(rgba[i*4+0] + delta);
        out[i*4+1] = clamp_u8(rgba[i*4+1] + delta);
        out[i*4+2] = clamp_u8(rgba[i*4+2] + delta);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
