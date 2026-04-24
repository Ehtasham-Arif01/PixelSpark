#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>
#include <queue>

extern "C" {

uint8_t* apply_canny(const uint8_t* rgba, int w, int h, int t1, int t2, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // 1. Grayscale + Gaussian blur
    std::vector<uint8_t> gray(n), blur(n);
    to_grayscale_1ch(rgba, gray.data(), w, h);
    gaussian_blur_1ch(gray.data(), blur.data(), w, h, 1.4f);

    // 2. Sobel gradients
    std::vector<float> mag(n, 0.f);
    std::vector<float> angle(n, 0.f);
    for (int y = 1; y < h-1; y++) {
        for (int x = 1; x < w-1; x++) {
            float Gx = -blur[(y-1)*w+(x-1)] + blur[(y-1)*w+(x+1)]
                       -2.f*blur[y*w+(x-1)] + 2.f*blur[y*w+(x+1)]
                       -blur[(y+1)*w+(x-1)] + blur[(y+1)*w+(x+1)];
            float Gy = -blur[(y-1)*w+(x-1)] - 2.f*blur[(y-1)*w+x] - blur[(y-1)*w+(x+1)]
                       +blur[(y+1)*w+(x-1)] + 2.f*blur[(y+1)*w+x] + blur[(y+1)*w+(x+1)];
            mag[y*w+x]   = std::sqrt(Gx*Gx + Gy*Gy);
            angle[y*w+x] = std::atan2(Gy, Gx);  // radians
        }
    }

    // 3. Non-maximum suppression
    std::vector<float> nms(n, 0.f);
    const float PI = 3.14159265f;
    for (int y = 1; y < h-1; y++) {
        for (int x = 1; x < w-1; x++) {
            float a = angle[y*w+x];
            // Quantise angle to 4 directions
            float deg = a * 180.f / PI;
            if (deg < 0) deg += 180.f;
            float q, r;
            if (deg < 22.5f || deg >= 157.5f) {       // 0°
                q = mag[y*w+(x+1)]; r = mag[y*w+(x-1)];
            } else if (deg < 67.5f) {                  // 45°
                q = mag[(y+1)*w+(x-1)]; r = mag[(y-1)*w+(x+1)];
            } else if (deg < 112.5f) {                 // 90°
                q = mag[(y+1)*w+x]; r = mag[(y-1)*w+x];
            } else {                                    // 135°
                q = mag[(y-1)*w+(x-1)]; r = mag[(y+1)*w+(x+1)];
            }
            float m = mag[y*w+x];
            nms[y*w+x] = (m >= q && m >= r) ? m : 0.f;
        }
    }

    // 4. Double threshold
    std::vector<uint8_t> strong(n, 0), weak(n, 0);
    for (int i = 0; i < n; i++) {
        if (nms[i] >= t2)      strong[i] = 255;
        else if (nms[i] >= t1) weak[i]   = 128;
    }

    // 5. Hysteresis: BFS from strong pixels
    std::vector<uint8_t> result(n, 0);
    std::queue<int> q;
    for (int i = 0; i < n; i++) {
        if (strong[i]) { result[i] = 255; q.push(i); }
    }
    while (!q.empty()) {
        int idx = q.front(); q.pop();
        int y = idx / w, x = idx % w;
        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                if (!dy && !dx) continue;
                int ny = y+dy, nx = x+dx;
                if (ny<0||ny>=h||nx<0||nx>=w) continue;
                int ni = ny*w+nx;
                if (weak[ni] && !result[ni]) {
                    result[ni] = 255; q.push(ni);
                }
            }
        }
    }

    for (int i = 0; i < n; i++) {
        out[i*4+0]=result[i]; out[i*4+1]=result[i];
        out[i*4+2]=result[i]; out[i*4+3]=rgba[i*4+3];
    }
    return out;
}

} // extern "C"
