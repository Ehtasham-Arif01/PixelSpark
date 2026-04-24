#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cstdlib>

extern "C" {

uint8_t* apply_vintage(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Warm sepia-ish tone curve
    uint8_t lut_r[256], lut_g[256], lut_b[256];
    for (int i = 0; i < 256; i++) {
        float t = i / 255.f;
        // Lift shadows, compress highlights
        float tone = t * 0.85f + 0.05f;
        lut_r[i] = clamp_u8f((tone * 1.10f) * 255.f);  // warm red
        lut_g[i] = clamp_u8f((tone * 0.95f) * 255.f);  // slight green dip
        lut_b[i] = clamp_u8f((tone * 0.75f) * 255.f);  // cool blue pull-down
    }

    // Vignette weight per-pixel
    float cx = w * 0.5f, cy = h * 0.5f;
    float maxR = std::sqrt(cx*cx + cy*cy);

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int i = y * w + x;
            float dx = x - cx, dy = y - cy;
            float dist = std::sqrt(dx*dx + dy*dy) / maxR;
            float vig = 1.f - 0.55f * dist * dist;  // vignette multiplier

            float r = lut_r[rgba[i*4+0]] * vig;
            float g = lut_g[rgba[i*4+1]] * vig;
            float b = lut_b[rgba[i*4+2]] * vig;

            // Slight grain
            int grain = (rand() % 13) - 6;
            out[i*4+0] = clamp_u8(static_cast<int>(r) + grain);
            out[i*4+1] = clamp_u8(static_cast<int>(g) + grain);
            out[i*4+2] = clamp_u8(static_cast<int>(b) + grain);
            out[i*4+3] = rgba[i*4+3];
        }
    }
    return out;
}

} // extern "C"
