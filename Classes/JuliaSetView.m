//
//  JuliaSetView.m
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//

#import "JuliaSetView.h"
#import "JuliaSet.h"

@interface JuliaSetView()
- (void)setX:(double)x y:(double)y;
@end

@implementation JuliaSetView

@synthesize juliaSet = juliaSet_;
@synthesize delegate = delegate_;
@synthesize isXYValid = isXYValid_;
@synthesize x = x_;
@synthesize y = y_;

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [juliaSet_ release];
  [super dealloc];
}

- (void)awakeFromNib {
  NSRect bounds = [self bounds];
  NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited |
    NSTrackingCursorUpdate |
    NSTrackingMouseMoved |
    NSTrackingActiveInActiveApp |
    NSTrackingInVisibleRect;
  NSTrackingArea *tracking = [[[NSTrackingArea alloc] initWithRect:bounds 
      options:options
        owner:self
     userInfo:nil] autorelease];
  [self addTrackingArea:tracking];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResize:) name:NSViewFrameDidChangeNotification object:self];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}


- (void)drawRect:(NSRect)dirtyRect {
  [juliaSet_ draw];
  if (isXYValid_) {
    NSRect bounds = [self bounds];
    NSPoint p1 = NSMakePoint(NSMinX(bounds), where_.y);
    NSPoint p2 = NSMakePoint(NSMaxX(bounds), where_.y);
    [[NSColor redColor] set];
    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    NSPoint p3 = NSMakePoint(where_.x, NSMinY(bounds));
    NSPoint p4 = NSMakePoint(where_.x, NSMaxY(bounds));
    [NSBezierPath strokeLineFromPoint:p3 toPoint:p4];
  }
}

- (void)mouseEntered:(NSEvent *)theEvent {
  wasAcceptingMouseEvents_ = [[self window] acceptsMouseMovedEvents];
  [[self window] setAcceptsMouseMovedEvents:YES];
  [self mouseMoved:theEvent];
  [self setXYValid:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
  [[self window] setAcceptsMouseMovedEvents:wasAcceptingMouseEvents_];
  [self setXYValid:NO];
}

- (void)mouseMoved:(NSEvent *)theEvent {
  where_ = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  double scale = [juliaSet_ scale];
  [self setX:where_.x * scale + [juliaSet_ offsetX] y:where_.y * scale + [juliaSet_ offsetY]];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
  didDrag_ = NO;
}

- (void)zoom:(double)ratio {
  double scale = [juliaSet_ scale];
  double newScale = fmin([juliaSet_ scaleMax], scale * ratio);
  double newOffsetX = where_.x * scale + [juliaSet_ offsetX] - (where_.x * newScale);
  NSSize size = [self bounds].size;
  double y = size.height - where_.y;
  double newOffsetY = y * scale + [juliaSet_ offsetY] - (y * newScale);

  [juliaSet_ beginUpdateGroup];
  [juliaSet_ setScale:newScale];
  [juliaSet_ setOffsetX:newOffsetX];
  [juliaSet_ setOffsetY:newOffsetY];
  [juliaSet_ endUpdateGroup];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
  if (!didDrag_) {
    [self zoom:5.];
  }
}

- (void)dragged:(NSEvent *)theEvent {
  NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  BOOL isIn = NSPointInRect(where, [self bounds]);
  if (isIn != isXYValid_) {
    [self setXYValid:isIn];
  }
  if (isIn) {
    [juliaSet_ beginUpdateGroup];
    double xOffset = [theEvent deltaX] * [juliaSet_ scale];
    double yOffset = [theEvent deltaY] * [juliaSet_ scale];
    [juliaSet_ setOffsetX:[juliaSet_ offsetX] - xOffset];
    [juliaSet_ setOffsetY:[juliaSet_ offsetY] - yOffset];
    [juliaSet_ endUpdateGroup];
    [self mouseMoved:theEvent];
  }
  didDrag_ = YES;
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
  [self dragged:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent {
  didDrag_ = NO;
}

- (void)mouseUp:(NSEvent *)theEvent {
  if (!didDrag_) {
    double scaleRatio = 0.2;
    // Control-Click is a synonym for Right-Click.
    if (NSEventModifierFlagControl & [theEvent modifierFlags]) {
      scaleRatio = 5.0;
    }
    [self zoom:scaleRatio];
  }
  didDrag_ = NO;
}

- (void)mouseDragged:(NSEvent *)theEvent {
  [self dragged:theEvent];
}

- (void)scrollWheel:(NSEvent *)event {
  float scaleRatio = 1.0 - event.deltaY / 10.;
  [self zoom:scaleRatio];
}

- (void)otherMouseUp:(NSEvent *)event {
  if (2 == event.buttonNumber) {
    [self zoom:1/self.scale];
  }
}


- (void)magnifyWithEvent:(NSEvent *)event {
  float scaleRatio = 1.0 - event.magnification;
  [self zoom:scaleRatio];
}


- (void)cursorUpdate:(NSEvent *)event {
}

- (void)setJuliaSet:(JuliaSet *)juliaSet {
  if (juliaSet_ != juliaSet) {
    [juliaSet_ release];
    juliaSet_ = [juliaSet retain];
    [juliaSet_ setDelegate:self];
    [juliaSet_ setSize:[self bounds].size];
  }
}

- (void)setXYValid:(BOOL)isXYValid {
  if (isXYValid_ != isXYValid) {
    isXYValid_ = isXYValid;
    [delegate_ mouseChanged:self];
    [self setNeedsDisplay:YES];
  }
}

- (void)setX:(double)x y:(double)y {
  if (!(x_ == x && y_ == y)) {
    x_ = x;
    y_ = y;
    [delegate_ mouseChanged:self];
    [self setNeedsDisplay:YES];
  }
}

- (double)scale {
  return [juliaSet_ scale];
}

- (double)a {
  return [juliaSet_ a];
}

- (void)setA:(double)a {
  [juliaSet_ setA:a];
}

- (double)b {
  return [juliaSet_ b];
}

- (void)setB:(double)b {
  [juliaSet_ setB:b];
}

- (void)didUpdate:(JuliaSet *)juliaSet {
  float elapsed = [juliaSet elapsed];
#if DEBUG
//  printf("%s\n", [[NSString stringWithFormat:@"elapsed time ms: %g", elapsed * 1.0e3] UTF8String]);
#endif
  [self setNeedsDisplay:YES];
  [delegate_ framesPerSecond:elapsed ? 1.0/elapsed : 0];
}

- (void)didResize:(NSNotification *)notify {
  [juliaSet_ setSize:[self bounds].size];
}

- (void)scaleChanged:(JuliaSet *)juliaSet {
  [delegate_ scaleChanged:self];
}


@end
