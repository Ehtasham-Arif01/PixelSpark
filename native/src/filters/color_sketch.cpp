#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_color_sketch(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Gaussian blur each channel separately (simulate smear)
    std::vector<uint8_t> blurred(n * 4);
    gaussian_blur_rgba(rgba, blurred.data(), w, h, 6.f);

    // Color dodge: original / (1 - blurred/255)  per channel
    for (int i = 0; i < n; i++) {
        for (int c = 0; c < 3; c++) {
            float orig  = rgba   [i*4+c] / 255.f;
            float blur  = blurred[i*4+c] / 255.f;
            float inv_b = 1.f - blur;
            float v = (inv_b < 0.01f) ? 1.f : std::min(1.f, orig / inv_b);
            out[i*4+c] = clamp_u8f(v * 255.f);
        }
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
