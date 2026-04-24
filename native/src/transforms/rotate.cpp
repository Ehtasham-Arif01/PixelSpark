#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

// Bilinear sample from RGBA image, returns {r,g,b,a}
static void bilinear_sample(const uint8_t* src, int w, int h,
                             float sx, float sy, uint8_t out[4]) {
    sx = clampf(sx, 0.f, w-1.f);
    sy = clampf(sy, 0.f, h-1.f);
    int x0 = static_cast<int>(sx), y0 = static_cast<int>(sy);
    int x1 = std::min(x0+1, w-1), y1 = std::min(y0+1, h-1);
    float ax = sx - x0, ay = sy - y0;
    for (int c = 0; c < 4; c++) {
        float top    = src[(y0*w+x0)*4+c]*(1-ax) + src[(y0*w+x1)*4+c]*ax;
        float bottom = src[(y1*w+x0)*4+c]*(1-ax) + src[(y1*w+x1)*4+c]*ax;
        out[c] = clamp_u8f(top*(1-ay) + bottom*ay);
    }
}

extern "C" {

uint8_t* apply_rotate(const uint8_t* rgba, int w, int h,
                      float angle_deg, int* out_w, int* out_h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_w || !out_h || !out_size) return nullptr;

    float rad = angle_deg * 3.14159265f / 180.f;
    float cosA = std::cos(rad), sinA = std::sin(rad);

    // Compute output bounding box
    float corners[4][2] = {
        {0.f, 0.f}, {(float)w, 0.f}, {0.f, (float)h}, {(float)w, (float)h}
    };
    float minX=1e9, maxX=-1e9, minY=1e9, maxY=-1e9;
    for (auto& c : corners) {
        float rx =  cosA*c[0] + sinA*c[1];
        float ry = -sinA*c[0] + cosA*c[1];
        if (rx < minX) minX=rx; if (rx > maxX) maxX=rx;
        if (ry < minY) minY=ry; if (ry > maxY) maxY=ry;
    }
    int nw = static_cast<int>(std::ceil(maxX - minX));
    int nh = static_cast<int>(std::ceil(maxY - minY));
    *out_w = nw; *out_h = nh;
    *out_size = nw * nh * 4;

    uint8_t* out = new (std::nothrow) uint8_t[static_cast<size_t>(nw)*nh*4]();
    if (!out) return nullptr;

    float cx_in  = w  * 0.5f, cy_in  = h  * 0.5f;
    float cx_out = nw * 0.5f, cy_out = nh * 0.5f;

    for (int y = 0; y < nh; y++) {
        for (int x = 0; x < nw; x++) {
            float dx = x - cx_out, dy = y - cy_out;
            // Inverse rotation
            float sx = cosA*dx - sinA*dy + cx_in;
            float sy = sinA*dx + cosA*dy + cy_in;
            if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
                uint8_t px[4];
                bilinear_sample(rgba, w, h, sx, sy, px);
                int idx = (y*nw+x)*4;
                out[idx+0]=px[0]; out[idx+1]=px[1];
                out[idx+2]=px[2]; out[idx+3]=px[3];
            }
            // else: transparent (already zeroed)
        }
    }
    return out;
}

} // extern "C"
