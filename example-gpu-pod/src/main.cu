#include <cstdio>

__global__ void hello() {
  printf("Hello from GPU thread %d in block %d!\n", threadIdx.x, blockIdx.x);
}

int main() {
  int deviceCount = 0;
  cudaGetDeviceCount(&deviceCount);
  printf("CUDA devices found: %d\n", deviceCount);

  if (deviceCount == 0) {
    printf("No CUDA devices available.\n");
    return 1;
  }

  cudaDeviceProp prop;
  cudaGetDeviceProperties(&prop, 0);
  printf("Device: %s\n", prop.name);
  printf("Compute capability: %d.%d\n", prop.major, prop.minor);

  hello<<<2, 4>>>();
  cudaDeviceSynchronize();

  printf("Done.\n");
  return 0;
}
