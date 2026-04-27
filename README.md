<div align="center">

# ⚡ PixelSpark
### Professional AI Photo Editor for Android

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)]()
[![C++17](https://img.shields.io/badge/C%2B%2B-17-00599C?logo=cplusplus)]()
[![TFLite](https://img.shields.io/badge/TFLite-MIRNet-FF6F00?logo=tensorflow)]()
[![Offline](https://img.shields.io/badge/100%25-Offline-brightgreen)]()
[![Android](https://img.shields.io/badge/Android-7%2B-3DDC84?logo=android)]()

*AI-powered photo editing that runs entirely on your device*

---

## 📸 Results Showcase

<table>
  <tr>
    <td><img src="results/01.jpeg" width="300" alt="Result 1"></td>
    <td><img src="results/02.jpeg" width="300" alt="Result 2"></td>
    <td><img src="results/03.jpeg" width="300" alt="Result 3"></td>
  </tr>
  <tr>
    <td><img src="results/04.jpeg" width="300" alt="Result 4"></td>
    <td><img src="results/05.jpeg" width="300" alt="Result 5"></td>
    <td><img src="results/06.jpeg" width="300" alt="Result 6"></td>
  </tr>
  <tr>
    <td><img src="results/07.jpeg" width="300" alt="Result 7"></td>
    <td><img src="results/08.jpeg" width="300" alt="Result 8"></td>
    <td><img src="results/09.jpeg" width="300" alt="Result 9"></td>
  </tr>
</table>

</div>

---

## 🌟 Features

- **100% Offline AI**: Uses MIRNet TFLite to enhance low-light images entirely on device. No internet required.
- **High-Performance C++ Core**: Custom native processing pipeline using `dart:ffi` for maximum speed and efficiency.
- **Non-Destructive Editing**: Robust undo/redo history with memory-efficient JPEG compression.
- **Pro Editing Suite**: 21+ professional tools including AI enhancement, style filters, and manual adjustments.
- **Premium UI/UX**: Modern white and sky-blue aesthetic with smooth animations and responsive layout.

## 🛠 Tech Stack

| Layer | Technologies Used |
|-------|-------------------|
| **Frontend** | Flutter, Provider, Google Fonts, Shimmer |
| **Backend/Core** | C++17, CMake, `dart:ffi` |
| **Machine Learning** | TensorFlow Lite (`tflite_flutter`), MIRNet |
| **Architecture** | Provider State Management, Native Background Isolates |

## 🚀 Quick Start

### 1. Prerequisites
*   **Flutter SDK**: >= 3.10.0
*   **Android SDK**: Platform 35, NDK 26.1.10909125
*   **Java**: JDK 21 (Android Studio bundled is recommended)

### 2. Environment Setup
The project includes automated scripts to handle dependencies and asset generation.

```bash
# Run development build on connected device
./scripts/run.sh

# Build production-ready APK
./scripts/build_apk.sh
```

## 🧰 The Pro Toolset

- **AI Adjustments**: Smart Enhance (MIRNet), Optimization Engine Fallback.
- **Professional Filters**: Pencil Art, Anime Style, Color Pop, Comic Book, 3D Relief, Warm Classic, Retro Film, Black & White.
- **Manual Control**: Brightness, Contrast, Saturation, Sharpness, Exposure, Gamma.
- **Creative Retouch**: Soft Focus, Smooth Skin, Noise Clean, Edge Art, Sketch Style.
- **Geometry**: Rotate, Flip, Free Crop.

## 🧠 Machine Learning Details

PixelSpark features an advanced **MIRNet** architecture optimized for mobile deployment.
- **Model Size**: ~27MB
- **Processing**: Parallel isolate-based inference to keep the UI fluid.
- **Compatibility**: Automatically detects hardware support and selects the optimal processing engine (AI vs Native C++).

## 🤝 Contributing
Contributions are welcome! Please ensure all UI changes adhere to the predefined `AppTheme` and heavy processing is offloaded to isolates via `MLService` or `NativeProcessor`.

## 📜 License
MIT License. See `LICENSE` for details.
