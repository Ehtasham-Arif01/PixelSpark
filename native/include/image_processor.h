#pragma once
#include <cstdint>

// All functions:
//   Input : rgba  – pointer to RGBA pixels (width * height * 4 bytes)
//           width, height – image dimensions
//           [optional params]
//   Output: out_size – set to (width * height * 4)
//   Return: newly-allocated RGBA buffer; caller must call free_result()
//           nullptr on failure

extern "C" {

// ─── Memory ──────────────────────────────────────────────────────────────────
void free_result(uint8_t* ptr);

// ─── Filters ─────────────────────────────────────────────────────────────────
uint8_t* apply_grayscale    (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_sepia        (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_vintage      (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_emboss       (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_pencil_sketch(const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_color_sketch (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_cartoon      (const uint8_t* rgba, int w, int h, int* out_size);
uint8_t* apply_ghibli       (const uint8_t* rgba, int w, int h, int* out_size);

// ─── Adjustments ─────────────────────────────────────────────────────────────
// value: -100 to +100
uint8_t* adjust_brightness  (const uint8_t* rgba, int w, int h, float value, int* out_size);
uint8_t* adjust_contrast    (const uint8_t* rgba, int w, int h, float value, int* out_size);
// value: 0.0 to 2.0 (1.0 = no change)
uint8_t* adjust_saturation  (const uint8_t* rgba, int w, int h, float value, int* out_size);
// strength: 0.0 to 3.0
uint8_t* apply_sharpen      (const uint8_t* rgba, int w, int h, float strength, int* out_size);
uint8_t* enhance_details    (const uint8_t* rgba, int w, int h, int* out_size);
// gamma: 0.5 to 2.0 (1.0 = no change)
uint8_t* apply_gamma        (const uint8_t* rgba, int w, int h, float gamma, int* out_size);

// ─── Blurs ───────────────────────────────────────────────────────────────────
// kernel_size: odd number (3, 5, 7, ...)
uint8_t* apply_gaussian_blur(const uint8_t* rgba, int w, int h, int kernel_size, int* out_size);
uint8_t* apply_median_blur  (const uint8_t* rgba, int w, int h, int kernel_size, int* out_size);
uint8_t* apply_bilateral    (const uint8_t* rgba, int w, int h, int* out_size);

// ─── Edge detection ──────────────────────────────────────────────────────────
uint8_t* apply_sobel        (const uint8_t* rgba, int w, int h, int* out_size);
// t1, t2: thresholds (e.g. 50, 150)
uint8_t* apply_canny        (const uint8_t* rgba, int w, int h, int t1, int t2, int* out_size);

// ─── Transforms ──────────────────────────────────────────────────────────────
// angle: degrees (positive = clockwise)
// out_w, out_h: set to output dimensions (may differ from input for free rotate)
uint8_t* apply_rotate       (const uint8_t* rgba, int w, int h, float angle, int* out_w, int* out_h, int* out_size);
// direction: 0 = horizontal, 1 = vertical
uint8_t* apply_flip         (const uint8_t* rgba, int w, int h, int direction, int* out_size);

} // extern "C"
