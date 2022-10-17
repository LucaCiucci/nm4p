
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <cuda.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>
#include <cuda_runtime_api.h>
#include <iostream>
//#include "cudaDmy.cuh"

#ifdef __INTELLISENSE__
//#define __global__
#endif

//#include <cuda

__global__ void cuda_hello(){
    printf("Hello World from GPU!\n");
}

int cuda_main() {
    std::cout << "A" << std::endl;
    cuda_hello<<<1,1>>>(); 
    std::cout << "B" << std::endl;
    return 0;
}