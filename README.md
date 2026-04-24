<div align="center">

# ⚡ PixelSpark
### Professional AI Photo Editor for Android

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)]()
[![C++17](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=cplusplus)]()
[![TFLite](https://img.shields.io/badge/TFLite-MIRNet-FF6F00?logo=tensorflow)]()
[![Offline](https://img.shields.io/badge/100%25-Offline-brightgreen)]()
[![Android](https://img.shields.io/badge/Android-7%2B-3DDC84?logo=android)]()

*AI-powered photo editing that runs entirely on your device*

</div>

---

## 🌟 Features

- **100% Offline AI**: Uses MIRNet TFLite to enhance low-light images entirely on device.
- **C++ Performance**: Custom native processing pipeline using `dart:ffi` for maximum performance.
- **Non-Destructive Editing**: Robust undo/redo history.
- **21+ Editing Tools**: Professional adjustments, style filters, retouching, and transforms.
- **Premium UI/UX**: Designed using Inter font, smooth gradients, and micro-animations.

## 🛠 Tech Stack

| Layer | Technologies Used |
|-------|-------------------|
| **Frontend** | Flutter, Provider, Google Fonts, Shimmer |
| **Backend/Core** | C++17, CMake, `dart:ffi` |
| **Machine Learning** | TensorFlow Lite (`tflite_flutter`), MIRNet |
| **Architecture** | Provider State Management, Native Background Isolates |

## 🚀 Quick Start

1. **Prerequisites**: Flutter SDK >= 3.10, Android NDK 26.1+
2. **Run dev build**:
   ```bash
   ./scripts/run.sh
   ```
3. **Build Release APK**:
   ```bash
   ./scripts/build_apk.sh
   ```

## 🧰 The 21 Native Operations

- **Adjustments**: Brightness, Contrast, Saturation, Sharpness, Exposure, Smart Enhance
- **Filters**: Original, Pencil Art, Anime Style, Color Pop, Comic Book, 3D Relief, Warm Classic, Retro Film, Black & White
- **Retouch**: Soft Focus, Smooth Skin, Noise Clean, Edge Art, Sketch Style
- **Transforms**: Rotate Right, Rotate Left, Flip Horizontal, Flip Vertical, Free Crop

## 🧠 Machine Learning

The app includes an advanced **MIRNet** AI model for image restoration and enhancement.
- Size: ~27MB
- Input/Output: 400x400 Float32
- Seamlessly falls back to a C++ algorithmic enhancement pipeline if unsupported on device.

## 🤝 Contributing
Pull requests welcome! Ensure your code respects the `AppTheme` constraints and isolates CPU-heavy work.

## 📜 License
MIT License. See `LICENSE` for details.
