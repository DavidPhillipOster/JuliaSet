//
//  JuliaSet.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSet.h"
#import "ComputeRow.h"
#import <mach/mach.h>
#import <mach/mach_time.h>

@implementation JuliaSet

@synthesize a = a_;
@synthesize b = b_;
@synthesize delegate = delegate_;
@synthesize nThreads = nThreads_;
@synthesize offsetX = offsetX_;
@synthesize offsetY = offsetY_;
@synthesize scale = scale_;
@synthesize size = size_;
@synthesize isPerformanceTest = isPerformanceTest_;
@synthesize startTime = startTime_;
@synthesize elapsedTime = elapsedTime_;

- (id)init {
  self = [super init];
  if (self) {
    nThreads_ = 1;
    scale_ = 1.0;
    numIterations_ = 256;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)archive {
  self = [self init];  // we inherit from object, which isn't a coder.
  if (self) {
    a_ = [archive decodeDoubleForKey:@"a"];
    b_ = [archive decodeDoubleForKey:@"b"];
    numIterations_ = [archive decodeIntForKey:@"iter"];
    offsetX_ = [archive decodeDoubleForKey:@"x"];
    offsetY_ = [archive decodeDoubleForKey:@"y"];
    scale_ = [archive decodeDoubleForKey:@"scale"];
  }
  return self;
}

- (void)dealloc {
  [image_ release]; image_ = nil;
  if (pixels_) { free(pixels_); pixels_ = nil; }
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)archive {
  [archive encodeDouble:a_ forKey:@"a"];
  [archive encodeDouble:b_ forKey:@"b"];
  [archive encodeInt:numIterations_ forKey:@"iter"];
  [archive encodeDouble:offsetX_ forKey:@"x"];
  [archive encodeDouble:offsetY_ forKey:@"y"];
  [archive encodeDouble:scale_ forKey:@"scale"];
}

- (void)draw {
  [image_ draw];
}

- (int)numberOfUsableThreads {
  int result =  nThreads_;
  if (size_.height < nThreads_) {
    result = size_.height;
  }
  if (result < 1) {
    result = 1;
  }
  return result;
}



- (void)updateN:(int)n {
  int nThreads = [self numberOfUsableThreads];
  int height = size_.height;
  int width = size_.width;
  for (int j = n; j < height; j += nThreads) {
    ComputeRow(j, numIterations_, width, height, pixels_, rowBytes_, scale_, offsetX_, offsetY_, a_, b_);
  }
}


- (void)update {
  if (nil == pixels_) {
    return;
  }
  if (nest_) {
    return;
  }
  elapsedTime_ = 0;
  startTime_ = mach_absolute_time();
  [self updateN:0];
  elapsedTime_ = mach_absolute_time() - startTime_;
  [self updateDone];
}

- (void)updateDone {
  [image_ release]; image_ = nil;
  image_ = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&pixels_
                                                   pixelsWide:size_.width
                                                   pixelsHigh:size_.height
                                                bitsPerSample:8
                                              samplesPerPixel:3
                                                     hasAlpha:NO
                                                     isPlanar:NO
                                               colorSpaceName:NSDeviceRGBColorSpace
                                                 bitmapFormat:0
                                                  bytesPerRow:rowBytes_
                                                 bitsPerPixel:32];
  if (!isPerformanceTest_) {
   [delegate_ didUpdate:self];
  }
}

- (void)setA:(double)a {
  if (a_ != a) {
    a_ = a;
    [self update];
  }
}

- (void)setB:(double)b {
  if (b_ != b) {
    b_ = b;
    [self update];
  }
}

- (void)setOffsetX:(double)offsetX  {
  if (offsetX_ != offsetX) {
    offsetX_ = offsetX;
    [self update];
  }
}

- (void)setOffsetY:(double)offsetY  {
  if (offsetY_ != offsetY) {
    offsetY_ = offsetY;
    [self update];
  }
}

- (double)scaleMax {
  return 0.01;
}

- (void)setScale:(double)scale {
  if (scale_ != scale && 0 < scale && scale <= [self scaleMax]) {
    if (scale_) {
      offsetY_ *= scale/scale_;
      offsetX_ *= scale/scale_;
    }
    scale_ = scale;
    [delegate_ scaleChanged:self];
    [self update];
  }
}

- (void)reallocate {
  if (pixels_) { free(pixels_); pixels_ = nil; }

  rowBytes_ = ((floor(size_.width) + 31) / 32) * 32 * sizeof(int);
  pixels_ = malloc(rowBytes_ * size_.height);
  NSAssert(pixels_, @"must not be nil");
}

- (void)setSize:(NSSize)size {
  if (!(size_.width == size.width && size_.height == size.height)) {
    size_ = size;
    [self reallocate];
    [self update];
  }
}

- (void)beginUpdateGroup {
  nest_++;
}

- (void)endUpdateGroup {
  nest_--;
  [self update];
}

- (float)elapsed {
  static mach_timebase_info_data_t sTimebaseInfo;
  if (0 == sTimebaseInfo.denom) {
    mach_timebase_info(&sTimebaseInfo);
  }
  return  (elapsedTime_ * sTimebaseInfo.numer) / (sTimebaseInfo.denom * 1.0e9) ;
}

@end
