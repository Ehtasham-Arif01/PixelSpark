#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_emboss(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Emboss kernel (top-left light source)
    static const int kx[3][3] = {{-2,-1,0},{-1,1,1},{0,1,2}};

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int acc = 128; // bias
            for (int ky = -1; ky <= 1; ky++) {
                for (int kx2 = -1; kx2 <= 1; kx2++) {
                    int sy = std::max(0, std::min(h-1, y+ky));
                    int sx = std::max(0, std::min(w-1, x+kx2));
                    const uint8_t* p = rgba + (sy*w+sx)*4;
                    int gray = static_cast<int>(0.299f*p[0]+0.587f*p[1]+0.114f*p[2]);
                    acc += gray * kx[ky+1][kx2+1];
                }
            }
            uint8_t v = clamp_u8(acc);
            int idx = (y*w+x)*4;
            out[idx+0] = v;
            out[idx+1] = v;
            out[idx+2] = v;
            out[idx+3] = rgba[idx+3];
        }
    }
    return out;
}

} // extern "C"
