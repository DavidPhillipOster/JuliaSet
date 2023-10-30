//
//  JuliaSet.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "OpQJuliaSet.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <sys/sysctl.h>

// Experiments show we get the best performance by spawning a thread per core.
int OpQNumberOfCores(void) {
  size_t n = 0;
  size_t nLen = sizeof n;
  sysctlbyname("hw.activecpu", &n, &nLen, NULL, 0);
  if (NSNotFound <= n) {
    n = 0;
  }
  return (int)n;
}

@implementation OpQJuliaSet {
  NSOperationQueue *q_;
}


- (id)init {
  self = [super init];
  if (self) {
    int n = OpQNumberOfCores();
    if (0 < n) {
      [self setNThreads:n];
    }
    q_ = [[NSOperationQueue alloc] init];
  }
  return self;
}



- (void)dealloc {
  [q_ release];
  [super dealloc];
}

- (void)update {
  if (nil == pixels_) {
    return;
  }
  if (nest_) {
    return;
  }
  [q_ cancelAllOperations];
  elapsedTime_ = 0;
  startTime_ = mach_absolute_time();
  int nThreads = [self numberOfUsableThreads];
  for (int n = 0; n < nThreads; ++n) {
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{[self updateN:n];}];
    [q_ addOperation:op];
  }
  [q_ waitUntilAllOperationsAreFinished];
  elapsedTime_ = mach_absolute_time() - startTime_;
  [self updateDone];
}


@end
