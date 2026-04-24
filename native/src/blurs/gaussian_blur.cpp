#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_gaussian_blur(const uint8_t* rgba, int w, int h, int kernel_size, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // kernel_size → sigma (odd kernel, sigma ≈ 0.3*(r-1)+0.8)
    if (kernel_size < 3) kernel_size = 3;
    if (kernel_size % 2 == 0) kernel_size++;
    float sigma = 0.3f * ((kernel_size - 1) * 0.5f - 1) + 0.8f;

    gaussian_blur_rgba(rgba, out, w, h, sigma);
    return out;
}

} // extern "C"
