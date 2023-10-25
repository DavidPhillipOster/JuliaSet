//
//  OpQJuliaSet.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSet.h"


// NSOperationQueue version of JuliaSet
@interface OpQJuliaSet : JuliaSet {
  NSOperationQueue *q_;
}

- (void)update; // recompute the bitmap and request a re-draw.

@end
