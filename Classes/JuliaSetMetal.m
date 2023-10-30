//  JuliaSetMetal.m
//  JuliaSet
//
//  Created by david on 10/28/23.
//

#import "JuliaSetMetal.h"
#import <Metal/Metal.h>

// Metal version of JuliaSet : NOT YET
@implementation JuliaSetMetal {
    id<MTLDevice> mDevice_;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> mJuliaFunctionPSO_;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> mCommandQueue_;

    // Buffers to hold data.
    id<MTLBuffer> mBufferOutput_;
}

- (id)init {
  self = [super init];
  if (self) {
    mDevice_ = MTLCreateSystemDefaultDevice();
    if (nil == mDevice_) {
        NSLog(@"Failed gget default metal device.");
        return nil;
    }

    id<MTLLibrary> defaultLibrary = [mDevice_ newDefaultLibrary];
    if (nil == defaultLibrary) {
        NSLog(@"Failed to find the default library.");
        return nil;
    }
    id<MTLFunction> juliaFunction = [defaultLibrary newFunctionWithName:@"ComputeRow"];
    if (nil == juliaFunction) {
        NSLog(@"Failed to find the juliaFunction function.");
        return nil;
    }
    NSError* error = nil;
    mJuliaFunctionPSO_ = [mDevice_ newComputePipelineStateWithFunction: juliaFunction error:&error];
    [juliaFunction release];
    if (nil == mJuliaFunctionPSO_) {
      NSLog(@"Failed to created pipeline state object, error %@.", error);
      return nil;
    }
    mCommandQueue_ = [mDevice_ newCommandQueue];
    if (nil == mCommandQueue_) {
      NSLog(@"Failed to find the command queue.");
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  [mCommandQueue_ release];
  mCommandQueue_ = nil;
  [mDevice_ release];
  mDevice_ = nil;
  [super dealloc];
}

@end
