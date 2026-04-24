#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_sharpen(const uint8_t* rgba, int w, int h, float strength, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Unsharp mask: result = original + strength * (original - blurred)
    std::vector<uint8_t> blurred(n * 4);
    gaussian_blur_rgba(rgba, blurred.data(), w, h, 1.5f);

    for (int i = 0; i < n; i++) {
        for (int c = 0; c < 3; c++) {
            float orig = rgba   [i*4+c];
            float blur = blurred[i*4+c];
            float v    = orig + strength * (orig - blur);
            out[i*4+c] = clamp_u8f(v);
        }
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
