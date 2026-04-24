#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <algorithm>

extern "C" {

uint8_t* apply_median_blur(const uint8_t* rgba, int w, int h, int kernel_size, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    if (kernel_size < 3) kernel_size = 3;
    if (kernel_size % 2 == 0) kernel_size++;
    int r = kernel_size / 2;
    int ksz = kernel_size * kernel_size;

    std::vector<uint8_t> win(ksz);

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            for (int c = 0; c < 3; c++) {
                int cnt = 0;
                for (int ky = -r; ky <= r; ky++) {
                    for (int kx = -r; kx <= r; kx++) {
                        int sy = std::max(0, std::min(h-1, y+ky));
                        int sx = std::max(0, std::min(w-1, x+kx));
                        win[cnt++] = rgba[(sy*w+sx)*4+c];
                    }
                }
                std::nth_element(win.begin(), win.begin()+cnt/2, win.begin()+cnt);
                out[(y*w+x)*4+c] = win[cnt/2];
            }
            out[(y*w+x)*4+3] = rgba[(y*w+x)*4+3];
        }
    }
    return out;
}

} // extern "C"
