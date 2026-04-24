cmake_minimum_required(VERSION 3.10)
project(image_processor VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Release optimisations
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -ffast-math -fno-exceptions-rtti 2>/dev/null || true")

set(SOURCES
    src/image_processor.cpp
    src/utils.cpp
    src/filters/grayscale.cpp
    src/filters/sepia.cpp
    src/filters/vintage.cpp
    src/filters/emboss.cpp
    src/filters/pencil_sketch.cpp
    src/filters/color_sketch.cpp
    src/filters/cartoon.cpp
    src/filters/ghibli_effect.cpp
    src/adjustments/brightness.cpp
    src/adjustments/contrast.cpp
    src/adjustments/saturation.cpp
    src/adjustments/sharpen.cpp
    src/adjustments/gamma.cpp
    src/adjustments/detail_enhance.cpp
    src/blurs/gaussian_blur.cpp
    src/blurs/median_blur.cpp
    src/blurs/bilateral.cpp
    src/edge_detection/sobel.cpp
    src/edge_detection/canny.cpp
    src/transforms/rotate.cpp
    src/transforms/flip.cpp
)

add_library(image_processor SHARED ${SOURCES})

target_include_directories(image_processor PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Android-specific linker deps
if(ANDROID)
    find_library(log-lib log)
    target_link_libraries(image_processor ${log-lib})

    if(ANDROID_ABI STREQUAL "armeabi-v7a")
        target_compile_options(image_processor PRIVATE -mfpu=neon -mfloat-abi=softfp)
    endif()
endif()

# Expose symbols for FFI dlopen
set_target_properties(image_processor PROPERTIES
    CXX_VISIBILITY_PRESET default
    VISIBILITY_INLINES_HIDDEN OFF
)
