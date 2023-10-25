//
//  JuliaSetOpenCL.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSetOpenCL.h"
#import <mach/mach_time.h>

#define COUNT_OF(a) (sizeof(a)/sizeof(*(a)) )

#define JULIA_FLOATTYPE float

@implementation JuliaSetOpenCL

- (id)init {
  self = [super init];
  if (self) {
    int err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_GPU, 1, &deviceID_, NULL);
    if (err != CL_SUCCESS) {
      printf("Error: Failed to create a device group!\n");
      [self release];
      return nil;
    }
    context_ = clCreateContext(0, 1, &deviceID_, NULL, NULL, &err);
    if (NULL == context_) {
      printf("Error: Failed to create a compute context!\n");
      [self release];
      return nil;
    }

    commands_ = clCreateCommandQueue(context_, deviceID_, 0, &err);
    if (NULL == commands_) {
      printf("Error: Failed to create a command commands!\n");
      [self release];
      return nil;
    }

    NSString *path = [[NSBundle mainBundle] pathForResource:@"ComputeRow" ofType:@"clx"];
    NSError *error = nil;
    NSString *update1Src = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (update1Src == nil) {
      const char *s = [[error description] UTF8String];
      if (s == NULL) { s = ""; }
      printf("Error: Failed to read ComputeRow.c! %s\n", s);
      [self release];
      return nil;
    }
    // cl_khr_fp64
    const char *programString[1];
    programString[0] = [update1Src UTF8String];
    program_ = clCreateProgramWithSource(context_, COUNT_OF(programString), programString, NULL, &err);
    if (NULL == program_) {
        printf("Error: Failed to create compute program!\n");
        [self release];
        return nil;
    }

    err = clBuildProgram(program_, 0, NULL, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
      size_t len;
      char buffer[2048];

      printf("Error: Failed to build program executable!\n");
      clGetProgramBuildInfo(program_, deviceID_, CL_PROGRAM_BUILD_LOG, sizeof(buffer), buffer, &len);
      printf("%s\n", buffer);
      [self release];
      return nil;
    }

    kernel_ = clCreateKernel(program_, "ComputeRow", &err);  // name must match.
    if (NULL == kernel_ || err != CL_SUCCESS){
      printf("Error: Failed to create compute kernel!\n");
      [self release];
      return nil;
    }
  }

  return self;
}

- (void)dealloc {
  if (output_) {
    clReleaseMemObject(output_);
    output_ = NULL;
  }
  if (kernel_) {
    clReleaseKernel(kernel_);
    kernel_ = NULL;
  }
  if (program_) {
    clReleaseProgram(program_);
    program_ = NULL;
  }
  if (commands_) {
    clReleaseCommandQueue(commands_);
    commands_ = NULL;
  }
  if (context_) {
    clReleaseContext(context_);
    context_ = NULL;
  }
  [super dealloc];
}

- (void)reallocate {
  [super reallocate];
  int count = size_.height * rowBytes_;
  if (output_) {
    clReleaseMemObject(output_);
  }
  output_ = clCreateBuffer(context_, CL_MEM_WRITE_ONLY, sizeof(int) * count, NULL, NULL);
  if (NULL == output_){
    printf("Error: Failed to create output!\n");
  }
}

- (void)update {
  if (nest_) {
    return;
  }
  int i = 0;
  if (output_) {
    elapsedTime_ = 0;
    startTime_ = mach_absolute_time();
    size_t nThreads, global;
    cl_int numIterations = numIterations_;
    cl_int rowBytes = rowBytes_;
    cl_int width = size_.width;
    cl_int height = size_.height;
    cl_int err = 0;
    cl_int unused = 0;
    JULIA_FLOATTYPE scale = scale_;
    JULIA_FLOATTYPE offsetX = offsetX_;
    JULIA_FLOATTYPE offsetY = offsetY_;
    JULIA_FLOATTYPE a = a_;
    JULIA_FLOATTYPE b = b_;
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_int), &unused); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_int), &numIterations); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_int), &width); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_int), &height); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_mem), &output_); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(cl_int), &rowBytes); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(JULIA_FLOATTYPE), &scale); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(JULIA_FLOATTYPE), &offsetX); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(JULIA_FLOATTYPE), &offsetY); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(JULIA_FLOATTYPE), &a); }
    if (!err) { err = clSetKernelArg(kernel_, i++, sizeof(JULIA_FLOATTYPE), &b); }

    if (!err) { err = clGetKernelWorkGroupInfo(kernel_, deviceID_, CL_KERNEL_WORK_GROUP_SIZE, sizeof(nThreads), &nThreads, NULL); i++; }
    if (!err) {
      global = ((height + nThreads - 1) / nThreads) * nThreads;
      // Enqueue our kernel to execute on the device
      err = clEnqueueNDRangeKernel(commands_, kernel_, 1, NULL, &global, &nThreads, 0, NULL, NULL); i++; 
    }
    // TODO: I'm getting a -36, CL_INVALID_COMMAND_QUEUE here.
    if (!err) { err = clFinish(commands_); i++; }
    if (!err) {
      err = clEnqueueReadBuffer(commands_, output_, CL_TRUE, 0, sizeof(int) * size_.height * rowBytes_, pixels_, 0, NULL, NULL ); i++;  
    }
    if (err) {
      printf("Error: Failed to update, step:%d err:%d!\n", i, err);
    } else {
      elapsedTime_ = mach_absolute_time() - startTime_;
      [self updateDone];
    }
  } else {
    [self updateN:1];
  }
  [delegate_ didUpdate:self];
}

@end
