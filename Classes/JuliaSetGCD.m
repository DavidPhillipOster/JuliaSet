//
//  JuliaSetGCD.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSetGCD.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <sys/sysctl.h>

typedef struct JuliaParams {
  int count; int height; int rowBytes; int numIterations;
  double scale; double offsetX; double offsetY; double a; double b;
  unsigned char *pixels; int begin; int end;
} JuliaParams;

static void update1(int count, int height, int rowBytes, int numIterations,
  double scale, double offsetX, double offsetY, double a, double b,
  unsigned char *pixels, int index) {

  if (index < count) {
    int i = index / height;
    int j = index % height;
    unsigned int *p = (unsigned int *)(pixels + j*rowBytes);
    double x = i*scale + offsetX;
    double y = j*scale + offsetY;
    int color = 0;
    int n = 0;
    // This for() loop is the actual Julia set equation.
    for (; n < numIterations_ && x*x + y*y < 4; ++n) {
      double newX = x*x - y*y + a;
      y = 2*x*y + b;
      x = newX;
    }
    color = n << 12;
    p[i] = color;
  }
}

@interface JulliaSetBaseOperation : NSOperation {
  BOOL isExecuting_;
  BOOL isFinished_;
}
- (void)doWork;
@end

@interface JulliaSetComputeOperation : JulliaSetBaseOperation {
  JuliaParams params_;
}
- (id)initWithParams:(const JuliaParams *)params;
- (void)doWork;
@end

@interface JulliaSetCompleteOperation : JulliaSetBaseOperation {
  id delegate_;
  JuliaSetGCD *juliaSet_;
}
- (id)initWithDelegate:(id)delegate julia:(JuliaSetGCD *)juliaSet;
- (void)doWork;
@end


@implementation JulliaSetBaseOperation

- (id)init {
  self = [super init];
  if (self) {
  }
  return self;
}

- (BOOL)isConcurrent {
  return YES;
}

- (BOOL)isExecuting {
  return isExecuting_;
}

- (BOOL)isFinished {
    return isFinished_;
}

- (void)start {
  if ([self isCancelled]) {
    [self willChangeValueForKey:@"isFinished"];
    isFinished_ = YES;
    [self didChangeValueForKey:@"isFinished"];
  } else {
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    isExecuting_ = YES;
    [self didChangeValueForKey:@"isExecuting"];
  }
}

- (void)completeOperation {
  [self willChangeValueForKey:@"isFinished"];
  [self willChangeValueForKey:@"isExecuting"];
  isExecuting_ = NO;
  isFinished_ = YES;
  [self didChangeValueForKey:@"isExecuting"];
  [self didChangeValueForKey:@"isFinished"];
}

- (void)doWork {
}

- (void)main {
  @try {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [self doWork];
    [self completeOperation];
    [pool release];
  } @catch(...) {
  }
}

@end

@implementation JulliaSetComputeOperation
- (id)initWithParams:(const JuliaParams *)params {
  self = [super init];
  if (self) {
    params_ = *params;
  }
  return self;
}

- (void)doWork {
  for (int i = params_.begin; i < params_.end && ![self isCancelled]; ++i) {
    update1(params_.count, params_.height, params_.rowBytes, params_.numIterations, params_.scale, params_.offsetX, params_.offsetY, params_.a, params_.b, params_.pixels, i);
  }
}

@end

@implementation JulliaSetCompleteOperation
- (id)initWithDelegate:(id)delegate julia:(JuliaSetGCD *)juliaSet {
  self = [super init];
  if (self) {
    delegate_ = [delegate retain];
    juliaSet_ = [juliaSet retain];
  }
  return self;
}
- (void)dealloc {
  [delegate_ release];
  [juliaSet_ release];
  [super dealloc];
}

- (void)doWork {
  if (![self isCancelled]) {
    [juliaSet_ setElapsedTime:mach_absolute_time() - [juliaSet_ startTime]];
    [delegate_ performSelectorOnMainThread:@selector(didUpdate:) withObject:juliaSet_ waitUntilDone:NO];
  }
}

@end


@implementation JuliaSetGCD

+ (JuliaSet*)juliaSet {
  JuliaSet* result = nil;
  if (YES) {
    result = [[[JuliaSetGCD alloc] init] autorelease];
  }
  if (nil == result) {
    result = [[[JuliaSet alloc] init] autorelease];
  }
  return result;
}

- (id)init {
  self = [super init];
  if (self) {
    size_t n = 0;
    size_t nLen = sizeof n;
    sysctlbyname("hw.activecpu", &n, &nLen, NULL, 0);
    if (n) {
      if (n == 1) {
        [self release];
        return nil;
      }
      numConcurrent_ = n;
    }
    queue_ = [[NSOperationQueue alloc] init];
    [queue_ setMaxConcurrentOperationCount:numConcurrent_];
  }
  return self;
}

- (void)dealloc {
  [queue_ release];
  [super dealloc];
}

- (void)reallocate {
  [queue_ cancelAllOperations];
  [super reallocate];
}

- (void)update {
  if (nil == image_) {
    return;
  }
  if (nest_) {
    return;
  }
  elapsedTime_ = 0;
  startTime_ = mach_absolute_time();
  [queue_ waitUntilAllOperationsAreFinished];
  int i = 0, count = size_.height * size_.width;
  JulliaSetCompleteOperation *completeOp = [[[JulliaSetCompleteOperation alloc] initWithDelegate:delegate_ julia:self] autorelease];
  int stride = ((count + (numConcurrent_-1))/numConcurrent_)*numConcurrent_;
  JuliaParams params;
  params.count = count;
  params.height = size_.height;
  params.rowBytes = rowBytes_;
  params.numIterations = numIterations_;
  params.scale = scale_;
  params.offsetX = offsetX_;
  params.offsetY = offsetY_;
  params.a = a_;
  params.b = b_;
  params.pixels = pixels_;
  params.begin = 0;
  params.end = stride;
  for (i = 0; i < numConcurrent_; ++i) {
    JulliaSetComputeOperation *op = [[[JulliaSetComputeOperation alloc] initWithParams:&params] autorelease];
    [completeOp addDependency:op];
    [queue_ addOperation:op];
    params.begin += stride;
    params.end += stride;
  }
  [queue_ addOperation:completeOp];
}

@end

