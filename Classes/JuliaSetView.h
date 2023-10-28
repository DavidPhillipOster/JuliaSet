//
//  JuliaSetView.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSet.h"

@class JuliaSetView;

@protocol JuliaSetViewDelegate
- (void)mouseChanged:(JuliaSetView *)view;
- (void)scaleChanged:(JuliaSetView *)view;
- (void)framesPerSecond:(float)fps;
@end

@interface JuliaSetView : NSView<JuliaSetDelegate> {
  JuliaSet *juliaSet_;
  NSPoint where_;
  id<JuliaSetViewDelegate> delegate_;
  double x_, y_;
  BOOL isXYValid_;
  BOOL wasAcceptingMouseEvents_;
  BOOL didDrag_;
}
@property (nonatomic, retain) JuliaSet *juliaSet;
@property (nonatomic, assign, setter=setXYValid:) BOOL isXYValid;
@property (nonatomic, assign) double a;
@property (nonatomic, assign) double b;
@property (nonatomic, assign, readonly) double x;
@property (nonatomic, assign, readonly) double y;
@property (nonatomic, assign, readonly) double scale;
@property (nonatomic, assign) IBOutlet id delegate;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseMoved:(NSEvent *)theEvent;

- (void)zoom:(double)ratio;

@end
