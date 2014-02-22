
#include	<wb.h>


__global__ void vecAdd(int * in, int * out, int width) {
    int index = threadIdx.x + blockIdx.x*blockDim.x;
    if (index < width)
        out[index] += in[index];
}

int main(void) {
	int ii;
	int * in, * out;
    int * d_in, * d_out;
    int width = 1<<10;

	wbTime_start(Generic, "Creating memory on host");
    in = (int *) malloc(width * sizeof(int));
    out = (int *) malloc(width * sizeof(int));
	wbTime_stop(Generic, "Creating memory on host");

    wbLog(TRACE, "HELLO Logger");

	wbTime_start(IO, "Initializing host values");
    for (ii = 0; ii < width; ii++) {
    	in[ii] = ii;
    	out[ii] = ii;
    }
	wbTime_stop(IO, "Initializing host values");

	wbTime_start(GPU, "Doing GPU allocation + computation");
    cudaMalloc((void **) &d_in, width*sizeof(int));
    cudaMalloc((void **) &d_out, width*sizeof(int));
    
    wbTime_start(Copy, "Copying memory to the device");
    cudaMemcpy(d_in, in, width * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_out, out, width * sizeof(int), cudaMemcpyHostToDevice);
    wbTime_stop(Copy, "Copying memory to the device");
    
    dim3 blockDim(32);
    dim3 gridDim(width/32);
    
    wbTime_start(Compute, "Performing CUDA computation");
    vecAdd<<<blockDim, gridDim>>>(d_in, d_out, width);
    cudaThreadSynchronize();
    wbTime_stop(Compute, "Performing CUDA computation");
    
    wbTime_start(Copy, "Copying memory back from the device");
    cudaMemcpy(out, d_out, width * sizeof(int), cudaMemcpyDeviceToHost);
    wbTime_stop(Copy, "Copying memory back from the device");
	wbTime_stop(GPU, "Doing GPU allocation + computation");
    

    return 0;
}

