#include "../../include/image_processor.h"
#include "../../include/utils.h"
#include <cmath>

// Screen blend mode: 1 - (1-a)(1-b)
static inline uint8_t screen_blend(uint8_t a, uint8_t b) {
    float fa = a / 255.f, fb = b / 255.f;
    return clamp_u8f((1.f - (1.f-fa)*(1.f-fb)) * 255.f);
}

// Lift-and-compress tone curve: lifts blacks, softens highlights (dreamy)
static inline uint8_t dream_tone(uint8_t v) {
    float t = v / 255.f;
    // Lift shadows to ~0.08, compress top to ~0.95
    float out = 0.08f + t * 0.87f;
    // Slight S-curve to add gentle contrast in midtones
    out = out - 0.04f * std::sin(2.f * 3.14159f * out);
    return clamp_u8f(out * 255.f);
}

extern "C" {

uint8_t* apply_ghibli(const uint8_t* rgba, int w, int h, int* out_size) {
    if (!rgba || w <= 0 || h <= 0 || !out_size) return nullptr;
    int n = w * h;
    *out_size = n * 4;
    uint8_t* out = alloc_output(w, h);
    if (!out) return nullptr;

    // ── 1. Strong bilateral-like smoothing (3-pass Gaussian) ────────────────
    //    This flattens textures like Ghibli's hand-painted cells.
    std::vector<uint8_t> smooth(n * 4);
    gaussian_blur_rgba(rgba, smooth.data(), w, h, 2.5f);
    std::vector<uint8_t> smooth2(n * 4);
    gaussian_blur_rgba(smooth.data(), smooth2.data(), w, h, 2.0f);

    // ── 2. Soft glow layer (wide blur, screen-blended at 35%) ───────────────
    std::vector<uint8_t> glow(n * 4);
    gaussian_blur_rgba(smooth2.data(), glow.data(), w, h, 5.f);

    // ── 3. Very soft edge overlay (7% darkening at edges) ───────────────────
    std::vector<uint8_t> gray(n);
    to_grayscale_1ch(smooth2.data(), gray.data(), w, h);
    std::vector<uint8_t> gblur(n);
    gaussian_blur_1ch(gray.data(), gblur.data(), w, h, 2.f);
    std::vector<float> edge_strength(n, 0.f);
    for (int y = 1; y < h-1; y++) {
        for (int x = 1; x < w-1; x++) {
            int Gx = -gblur[(y-1)*w+(x-1)] + gblur[(y-1)*w+(x+1)]
                     -2*gblur[y*w+(x-1)]    + 2*gblur[y*w+(x+1)]
                     -gblur[(y+1)*w+(x-1)]  + gblur[(y+1)*w+(x+1)];
            int Gy = -gblur[(y-1)*w+(x-1)] - 2*gblur[(y-1)*w+x] - gblur[(y-1)*w+(x+1)]
                     +gblur[(y+1)*w+(x-1)] + 2*gblur[(y+1)*w+x] + gblur[(y+1)*w+(x+1)];
            float mag = std::sqrt(float(Gx*Gx + Gy*Gy));
            edge_strength[y*w+x] = std::min(1.f, mag / 200.f);
        }
    }

    // ── 4. Per-pixel compose ────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
        float R = smooth2[i*4+0], G = smooth2[i*4+1], B = smooth2[i*4+2];

        // Screen glow (35% weight)
        R = R * 0.65f + screen_blend(static_cast<uint8_t>(R), glow[i*4+0]) * 0.35f;
        G = G * 0.65f + screen_blend(static_cast<uint8_t>(G), glow[i*4+1]) * 0.35f;
        B = B * 0.65f + screen_blend(static_cast<uint8_t>(B), glow[i*4+2]) * 0.35f;

        // Pastel shift: blend 12% toward white (desaturates and lifts)
        R = R * 0.88f + 255.f * 0.12f;
        G = G * 0.88f + 255.f * 0.12f;
        B = B * 0.88f + 255.f * 0.12f;

        // Warm tint: boost greens/reds slightly, pull blues gently
        R = clampf(R * 1.04f, 0, 255);
        G = clampf(G * 1.02f, 0, 255);
        B = clampf(B * 0.94f, 0, 255);

        // Dreamy tone curve (lift blacks, soft highlights)
        R = dream_tone(static_cast<uint8_t>(R));
        G = dream_tone(static_cast<uint8_t>(G));
        B = dream_tone(static_cast<uint8_t>(B));

        // Soft edge darkening (7%)
        float em = edge_strength[i] * 0.07f;
        R = clampf(R * (1.f - em), 0, 255);
        G = clampf(G * (1.f - em), 0, 255);
        B = clampf(B * (1.f - em), 0, 255);

        // Slight saturation boost (Ghibli colors are vivid but soft)
        float h_c, s_c, v_c;
        rgb_to_hsv(R/255.f, G/255.f, B/255.f, h_c, s_c, v_c);
        s_c = clampf(s_c * 1.15f, 0.f, 1.f);
        float rr, gg, bb;
        hsv_to_rgb(h_c, s_c, v_c, rr, gg, bb);

        out[i*4+0] = clamp_u8f(rr * 255.f);
        out[i*4+1] = clamp_u8f(gg * 255.f);
        out[i*4+2] = clamp_u8f(bb * 255.f);
        out[i*4+3] = rgba[i*4+3];
    }
    return out;
}

} // extern "C"
