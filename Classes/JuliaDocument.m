//
//  JuliaDocument.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaDocument.h"
#import "OpQJuliaSet.h"
#import "JuliaSetOpenCL.h"
#import "JuliaSetMetal.h"

@implementation JuliaDocument

@synthesize juliaSet = juliaSet_;
@synthesize juliaSetView = juliaSetView_;
@synthesize a = a_;
@synthesize b = b_;
@synthesize x = x_;
@synthesize y = y_;
@synthesize scale = scale_;

- (void)dealloc {
  [juliaSet_ release];
  [juliaSetView_ release];
  [a_ release];
  [b_ release];
  [x_ release];
  [y_ release];
  [scale_ release];
  [super dealloc];
}

- (NSString *)windowNibName {
  return @"JuliaDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
  [super windowControllerDidLoadNib:aController];
  [[self.engine itemAtIndex:0] setTitle:[NSString stringWithFormat:@"cpu %d", OpQNumberOfCores()]];
  if (nil == juliaSet_) {
//    [self setJuliaSet:[[[OpQJuliaSet alloc] init] autorelease]];
    [self setJuliaSet:[[[JuliaSetOpenCL alloc] init] autorelease]];
    [juliaSet_ beginUpdateGroup];
    [juliaSet_ setA: -0.765];
    [juliaSet_ setB:  0.15];
    [juliaSet_ setOffsetX:-[juliaSetView_ bounds].size.width/2.];
    [juliaSet_ setOffsetY:-[juliaSetView_ bounds].size.height/2.];
    [juliaSet_ setScale:0.01];
    [juliaSet_ endUpdateGroup];
  }
  [juliaSetView_ setJuliaSet:juliaSet_];
  [self engineUpdate];
}

- (NSUInteger)indexOfEngineClass {
  if ([juliaSet_ class] == [OpQJuliaSet class]) {
    return 0;
  } else if ([juliaSet_ class] == [JuliaSetOpenCL class]) {
    return 2;
  } else if ([juliaSet_ class] == [JuliaSetMetal class]) {
    return 3;
  }
  return 1; // single threaded CPU
}

- (Class)engineClassForIndex:(NSUInteger)index {
  switch (index) {
    case 0: return [OpQJuliaSet class];
    default:
    case 1: return [JuliaSet class];
    case 2: return [JuliaSetOpenCL class];
    case 3: return [JuliaSetMetal class];
  }
}

- (void)engineUpdate {
  [self.engine selectItemAtIndex:[self indexOfEngineClass]];
  [a_ setStringValue:[NSString stringWithFormat:@"%g", [juliaSetView_ a]]];
  [b_ setStringValue:[NSString stringWithFormat:@"%g", [juliaSetView_ b]]];
  [scale_ setStringValue:[NSString stringWithFormat:@"%3.1e", 1./[juliaSetView_ scale]]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSData *result = [NSKeyedArchiver archivedDataWithRootObject:juliaSet_];
#pragma clang diagnostic pop
  if (result == nil && outError != NULL) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return result;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  JuliaSet *set = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
  BOOL isOK = [set isKindOfClass:[JuliaSet class]];
  if (isOK) {
    [self setJuliaSet:set];
  } else if (outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
  return isOK;
}

- (void)mouseChanged:(JuliaSetView *)view {
  if([view isXYValid]) {
    [x_ setStringValue:[NSString stringWithFormat:@"%g", [view x]]];
    [y_ setStringValue:[NSString stringWithFormat:@"%g", [view y]]];
  } else {
    [x_ setStringValue:@""];
    [y_ setStringValue:@""];
  }
}

- (void)scaleChanged:(JuliaSetView *)view {
  [scale_ setStringValue:[NSString stringWithFormat:@"%3.1e", 1./[view scale]]];
}

- (void)framesPerSecond:(float)fps {
  if (fps) {
    self.fps.stringValue = [NSString stringWithFormat:@"%3.1f", fps];
  } else {
    self.fps.stringValue = @"";
  }
}

- (IBAction)engineDidChange:(id)sender {
  if (sender == self.engine) {
    NSUInteger index = self.engine.indexOfSelectedItem;
    if ([self engineClassForIndex:index] != [juliaSet_ class]) {
      JuliaStruct js = [juliaSet_ juliaStruct];
      [self setJuliaSet:[[[[self engineClassForIndex:index] alloc] init] autorelease]];
      [juliaSet_ setJuliaStruct:js];
      [juliaSetView_ setJuliaSet:juliaSet_];
    }
    [self engineUpdate];
  }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
  NSString *s = [fieldEditor string];
  double d = [s doubleValue];
  if (control == a_) {
    [juliaSetView_ setA:d];
  } else if (control == b_) {
    [juliaSetView_ setB:d];
  }
  return YES;
}

// Experiments with OpQJuliaSet show that once we get to the actual number of
// cores, we're doing about as well as we are going to.
// Experimental results, on an 8-core Mac with hyperthreading, so it thinks there are 16 cores.
// column 1: number of NSBlockOperations pushed onto the NSOperationQueue to perform an update.
// column 2: average number of milliseconds to complete the update.
// 1	70.3577
// 2	35.6508
// 3	24.46
// 4	18.9888
// 5	15.901
// 6	13.5557
// 7	12.2817
// 8	11.8718
// 9	13.3674
//10	12.5851
//11	12.0446
//12	11.2476
//13	10.6115
//14	10.001
//15	9.71063
//16	9.71023
//17	11.8695
//18	11.7352
//19	11.5306
//20	11.2499
// Based on this experiment, we default to the same amount of parallelism as there are cores

- (IBAction)performanceTest:(id)sender {
  OpQJuliaSet *jset = (OpQJuliaSet *) juliaSet_;
  [jset setPerformanceTest:YES];
  [jset setOffsetX:-0.51034];
  [jset setOffsetY:0.07445];
  int threadMax = 20;
  float times[20];
  // run the experiment for linearly increasing amounts of parallelism
  for (int n = 0; n < threadMax; ++n) {
    double total = 0;
    [jset setNThreads:n+1];
    // zoom in ten times.
    for (int i = 0; i < 10; ++i) {
      float newScale = [juliaSet_ scale] * 0.1;
      [juliaSet_ setScale:newScale];
      total += [jset elapsed];
#if DEBUG
  printf("%s\n", [[NSString stringWithFormat:@"elapsed time ms: %g", [jset elapsed] * 1.0e3] UTF8String]);
#endif
    }
    // zoom out ten times.
    for (int i = 0; i < 10; ++i) {
      float newScale = [juliaSet_ scale] * 10.;
      [juliaSet_ setScale:newScale];
      total += [jset elapsed];
#if DEBUG
  printf("%s\n", [[NSString stringWithFormat:@"elapsed time ms: %g", [jset elapsed] * 1.0e3] UTF8String]);
#endif
    }
    times[n] = total/20.; // average time to recompute every pixel in the image.
  } // end of experiments.
  printf("\n\n");
  // print the data.
  for (int n = 0; n < threadMax; ++n) {
    printf("%d\t%g\n", n+1, times[n] * 1.0e3);
  }
  [jset setPerformanceTest:NO];
}






@end
