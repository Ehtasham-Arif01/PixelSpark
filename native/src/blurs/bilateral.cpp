#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

extern "C" {

uint8_t* apply_bilateral(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    const float sigma_s = 8.f;   // spatial
    const float sigma_r = 60.f;  // range
    const int   radius  = 6;

    // Precompute spatial Gaussian weights
    int kw = 2*radius+1;
    std::vector<float> spatial(kw * kw);
    for (int dy = -radius; dy <= radius; dy++)
        for (int dx = -radius; dx <= radius; dx++)
            spatial[(dy+radius)*kw+(dx+radius)] =
                std::exp(-(dx*dx+dy*dy)/(2.f*sigma_s*sigma_s));

    // Range LUT (squared differences for each channel sum 0..255^2*3)
    // Use fast per-channel range weight
    float range_lut[256];
    for (int i = 0; i < 256; i++)
        range_lut[i] = std::exp(-(float)(i*i)/(2.f*sigma_r*sigma_r));

    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float R=0,G=0,B=0, W=0;
            const uint8_t* cp = rgba + (y*w+x)*4;
            for (int dy = -radius; dy <= radius; dy++) {
                for (int dx = -radius; dx <= radius; dx++) {
                    int sy = std::max(0, std::min(h-1, y+dy));
                    int sx = std::max(0, std::min(w-1, x+dx));
                    const uint8_t* np = rgba + (sy*w+sx)*4;
                    float ws = spatial[(dy+radius)*kw+(dx+radius)];
                    int dr = std::abs(cp[0]-np[0]);
                    int dg = std::abs(cp[1]-np[1]);
                    int db = std::abs(cp[2]-np[2]);
                    // Approximate range weight as product per channel
                    float wr = range_lut[dr] * range_lut[dg] * range_lut[db];
                    float w_total = ws * wr;
                    R += np[0] * w_total;
                    G += np[1] * w_total;
                    B += np[2] * w_total;
                    W += w_total;
                }
            }
            int idx = (y*w+x)*4;
            out[idx+0] = clamp_u8f(R/W);
            out[idx+1] = clamp_u8f(G/W);
            out[idx+2] = clamp_u8f(B/W);
            out[idx+3] = rgba[idx+3];
        }
    }
    return out;
}

} // extern "C"
