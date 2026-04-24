#include "../../include/image_processor.h"
#include "../../include/utils.h"

extern "C" {

uint8_t* apply_flip(const uint8_t* rgba, int w, int h, int direction, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            int src_x = (direction == 0) ? w - 1 - x : x;  // 0=horizontal
            int src_y = (direction == 1) ? h - 1 - y : y;  // 1=vertical
            const uint8_t* s = rgba + (src_y*w+src_x)*4;
            uint8_t*       d = out  + (y*w+x)*4;
            d[0]=s[0]; d[1]=s[1]; d[2]=s[2]; d[3]=s[3];
        }
    }
    return out;
}

} // extern "C"
