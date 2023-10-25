//
//  JuliaSetOpenCL.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//
#import "JuliaSet.h"
#include <OpenCL/opencl.h>

// Does not work. Not used.
// An attempt to use OpenCL to execute the algorithm in the GPU.
// Errors out on the clEnqueueNDRangeKernel(). I don't know how to debug it.
@interface JuliaSetOpenCL : JuliaSet {
  cl_device_id deviceID_;
  cl_context context_;
  cl_command_queue commands_;
  cl_program program_;
  cl_kernel kernel_;
  cl_mem output_;
}

@end
