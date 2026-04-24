#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* adjust_saturation(const uint8_t* rgba, int w, int h, float value, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // value: 0.0 (grayscale) to 2.0 (double saturation), 1.0 = unchanged
    for (int i = 0; i < n; i++) {
        float r = rgba[i*4+0] / 255.f;
        float g = rgba[i*4+1] / 255.f;
        float b = rgba[i*4+2] / 255.f;
        float h_c, s_c, v_c;
        rgb_to_hsv(r, g, b, h_c, s_c, v_c);
        s_c = clampf(s_c * value, 0.f, 1.f);
        float rr, gg, bb;
        hsv_to_rgb(h_c, s_c, v_c, rr, gg, bb);
        out[i*4+0] = clamp_u8f(rr * 255.f);
        out[i*4+1] = clamp_u8f(gg * 255.f);
        out[i*4+2] = clamp_u8f(bb * 255.f);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
