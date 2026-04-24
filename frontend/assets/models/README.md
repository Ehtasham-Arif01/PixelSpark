# MIRNet TFLite Model — Setup Instructions

## Model Details
Name:        MIRNet-fixed
Task:        Low-light enhancement / image restoration
Input shape: [1, 400, 400, 3]  float32  RGB normalized [0.0, 1.0]
Output shape:[1, 400, 400, 3]  float32  RGB normalized [0.0, 1.0]
Size:        ~27MB

## Download (choose one method)

### Method 1: wget
```bash
wget -O frontend/assets/models/enhancer.tflite \
"https://tfhub.dev/sayakpaul/lite-model/mirnet-fixed/dr/1\
?lite-format=tflite"
```

### Method 2: Python
```python
import urllib.request
url = ("https://tfhub.dev/sayakpaul/lite-model/"
       "mirnet-fixed/dr/1?lite-format=tflite")
urllib.request.urlretrieve(url, "enhancer.tflite")
```

### Method 3: Browser
Go to: https://tfhub.dev/sayakpaul/lite-model/mirnet-fixed/dr/1
Click "Download" -> rename file to enhancer.tflite
Place at: frontend/assets/models/enhancer.tflite

## Fallback Mode
If enhancer.tflite is NOT placed in this folder:
  - App detects missing model automatically
  - Falls back to C++ enhancement pipeline
  - No crash, no error shown to user
  - Full app functionality maintained
