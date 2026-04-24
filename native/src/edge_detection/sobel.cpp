#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

extern "C" {

uint8_t* apply_sobel(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    std::vector<uint8_t> gray(n);
    to_grayscale_1ch(rgba, gray.data(), w, h);

    std::vector<uint8_t> blur(n);
    gaussian_blur_1ch(gray.data(), blur.data(), w, h, 1.f);

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int idx = (y*w+x)*4;
            if (x == 0 || x == w-1 || y == 0 || y == h-1) {
                out[idx+0]=out[idx+1]=out[idx+2]=0;
                out[idx+3]=rgba[idx+3];
                continue;
            }
            int Gx = -blur[(y-1)*w+(x-1)] + blur[(y-1)*w+(x+1)]
                     -2*blur[y*w+(x-1)]    + 2*blur[y*w+(x+1)]
                     -blur[(y+1)*w+(x-1)]  + blur[(y+1)*w+(x+1)];
            int Gy = -blur[(y-1)*w+(x-1)] - 2*blur[(y-1)*w+x] - blur[(y-1)*w+(x+1)]
                     +blur[(y+1)*w+(x-1)] + 2*blur[(y+1)*w+x] + blur[(y+1)*w+(x+1)];
            uint8_t mag = clamp_u8f(std::sqrt(float(Gx*Gx + Gy*Gy)));
            out[idx+0]=mag; out[idx+1]=mag; out[idx+2]=mag;
            out[idx+3]=rgba[idx+3];
        }
    }
    return out;
}

} // extern "C"
