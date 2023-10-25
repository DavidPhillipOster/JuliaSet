//
//  JuliaSetGCD.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSet.h"

// GCD = Grand Central Dispatch, but really just NSOperationQueue since it
// runs on top of GCD. Each update fans out into a thread for each CPU, doing
// a fraction of the computation.
// This works. See also: JulliaSetOpenCL, which doesn't.
@interface JuliaSetGCD : JuliaSet {
  NSOperationQueue *queue_;
  int numConcurrent_;
}
+ (JuliaSet *)juliaSet;
- (void)update;
@end
