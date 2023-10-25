//
//  JuliaSet.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JuliaSet;

@protocol JuliaSetDelegate
- (void)didUpdate:(JuliaSet *)juliaSet;
- (void)scaleChanged:(JuliaSet *)juliaSet;
@end

// Create a drawable image of the julia set.
@interface JuliaSet : NSObject<NSCoding> {
 @protected
  double a_;
  double b_;
  id<JuliaSetDelegate> delegate_;
  int nThreads_;  // always 1 in this class.
  int numIterations_;
  int rowBytes_;
  double offsetX_, offsetY_;
  double scale_;
  NSSize size_;
  unsigned char *pixels_;
  NSBitmapImageRep *image_;
  int nest_;

  uint64_t startTime_;
  uint64_t elapsedTime_;
}
@property (nonatomic, assign) double a;
@property (nonatomic, assign) double b;
@property (nonatomic, assign) id<JuliaSetDelegate> delegate;
@property (nonatomic, assign) int nThreads;
@property (nonatomic, assign) double offsetX;
@property (nonatomic, assign) double offsetY;
@property (nonatomic, assign) double scale;
@property (nonatomic, assign) NSSize size;
@property (nonatomic, assign, setter=setPerformanceTest:) BOOL isPerformanceTest;


// properties for subclasses
@property (nonatomic, assign) uint64_t startTime;
@property (nonatomic, assign) uint64_t elapsedTime;

- (double)scaleMax;

- (void)draw;

// Normally, the bitmap is re-evaluated each time a property changes.
// Group a set of property changes, so we won't update until endUpdateGroup is
// called. These nest, so the update doesn't happen until we are unnested.
- (void)beginUpdateGroup;
- (void)endUpdateGroup;

// wall clock time to do the previous update, in seconds.
- (float)elapsed;

// We support up to one thread per row.
- (int)numberOfUsableThreads;

// methods for subclasses
- (void)reallocate; // size changed. re-size our bitmap.
- (void)update; // recompute the bitmap and request a re-draw.
- (void)updateN:(int)n; // N is an integer offset, used for multi-threads.
- (void)updateDone; // update should call this when it's done.
@end
