#include "../include/image_processor.h"

extern "C" {

void free_result(uint8_t* ptr) {
    delete[] ptr;
}

} // extern "C"
