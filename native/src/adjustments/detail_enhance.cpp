#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cstring>

// Simplified CLAHE on luminance channel:
//   8x8 tile grid, clip limit = 3.0 * (tile_area / 256)
static void clahe_1ch(const uint8_t* src, uint8_t* dst, int w, int h) {
    const int TILES_X = 8, TILES_Y = 8;
    int tw = (w + TILES_X - 1) / TILES_X;  // tile width
    int th = (h + TILES_Y - 1) / TILES_Y;  // tile height

    // LUTs for each tile: lut[ty][tx][256]
    std::vector<uint8_t> luts(TILES_Y * TILES_X * 256);

    for (int ty = 0; ty < TILES_Y; ty++) {
        for (int tx = 0; tx < TILES_X; tx++) {
            int x0 = tx * tw, y0 = ty * th;
            int x1 = std::min(x0 + tw, w);
            int y1 = std::min(y0 + th, h);
            int tile_area = (x1 - x0) * (y1 - y0);

            // Histogram
            int hist[256] = {};
            for (int y = y0; y < y1; y++)
                for (int x = x0; x < x1; x++)
                    hist[src[y*w+x]]++;

            // Clip limit
            int clip_limit = std::max(1, static_cast<int>(3.0f * tile_area / 256));
            int excess = 0;
            for (int i = 0; i < 256; i++) {
                if (hist[i] > clip_limit) {
                    excess += hist[i] - clip_limit;
                    hist[i] = clip_limit;
                }
            }
            // Redistribute excess uniformly
            int add_each = excess / 256;
            for (int i = 0; i < 256; i++) hist[i] += add_each;

            // CDF → LUT
            uint8_t* lut = &luts[(ty * TILES_X + tx) * 256];
            long cdf = 0;
            for (int i = 0; i < 256; i++) {
                cdf += hist[i];
                lut[i] = static_cast<uint8_t>(std::min(255L, cdf * 255L / tile_area));
            }
        }
    }

    // Bilinear interpolation between tile LUTs
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint8_t v = src[y*w+x];

            // Find surrounding tile centres
            float fx = (x + 0.5f) / tw - 0.5f;
            float fy = (y + 0.5f) / th - 0.5f;
            int tx0 = static_cast<int>(fx); float ax = fx - tx0;
            int ty0 = static_cast<int>(fy); float ay = fy - ty0;
            int tx1 = tx0 + 1, ty1 = ty0 + 1;
            tx0 = std::max(0, std::min(TILES_X-1, tx0));
            tx1 = std::max(0, std::min(TILES_X-1, tx1));
            ty0 = std::max(0, std::min(TILES_Y-1, ty0));
            ty1 = std::max(0, std::min(TILES_Y-1, ty1));
            ax = clampf(ax, 0.f, 1.f);
            ay = clampf(ay, 0.f, 1.f);

            float top    = luts[(ty0*TILES_X+tx0)*256+v]*(1.f-ax)
                         + luts[(ty0*TILES_X+tx1)*256+v]*ax;
            float bottom = luts[(ty1*TILES_X+tx0)*256+v]*(1.f-ax)
                         + luts[(ty1*TILES_X+tx1)*256+v]*ax;
            dst[y*w+x] = clamp_u8f(top*(1.f-ay) + bottom*ay);
        }
    }
}

extern "C" {

uint8_t* enhance_details(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // Apply CLAHE to luminance only, keep chroma
    for (int i = 0; i < n; i++) {
        float r = rgba[i*4+0]/255.f, g = rgba[i*4+1]/255.f, b = rgba[i*4+2]/255.f;
        float h_c, s_c, v_c;
        rgb_to_hsv(r, g, b, h_c, s_c, v_c);
        // Store V in a temp channel as uint8
        out[i*4+0] = clamp_u8f(v_c * 255.f); // reuse R for V
        out[i*4+1] = rgba[i*4+1]; // placeholder
        out[i*4+2] = rgba[i*4+2]; // placeholder
        out[i*4+3] = rgba[i*4+3];
        // Also store h, s as floats — use a side buffer
        (void)h_c; (void)s_c;
    }

    // Build lum channel
    std::vector<uint8_t> lum(n), lum_eq(n);
    std::vector<float> hues(n), sats(n);
    for (int i = 0; i < n; i++) {
        float r = rgba[i*4+0]/255.f, g = rgba[i*4+1]/255.f, b = rgba[i*4+2]/255.f;
        float hh, ss, vv;
        rgb_to_hsv(r, g, b, hh, ss, vv);
        lum[i] = clamp_u8f(vv * 255.f);
        hues[i] = hh; sats[i] = ss;
    }

    clahe_1ch(lum.data(), lum_eq.data(), w, h);

    // Reconstruct
    for (int i = 0; i < n; i++) {
        float rr, gg, bb;
        hsv_to_rgb(hues[i], sats[i], lum_eq[i]/255.f, rr, gg, bb);
        out[i*4+0] = clamp_u8f(rr*255.f);
        out[i*4+1] = clamp_u8f(gg*255.f);
        out[i*4+2] = clamp_u8f(bb*255.f);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
