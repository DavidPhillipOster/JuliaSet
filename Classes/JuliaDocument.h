//
//  JuliaDocument.h
//  JuliaSet
//
//  Created by David Phillip Oster on 12/28/10.
//  Copyright 2010 David Phillip Oster. All rights reserved.
//


#import "JuliaSetView.h"

@class JuliaSet;

@interface JuliaDocument : NSDocument<JuliaSetViewDelegate> {
  JuliaSet *juliaSet_;
  JuliaSetView *juliaSetView_;
  NSTextField *a_;
  NSTextField *b_;
  NSTextField *x_;
  NSTextField *y_;
  NSTextField *scale_;
}
@property (nonatomic, retain) JuliaSet *juliaSet;
@property (nonatomic, retain) IBOutlet JuliaSetView *juliaSetView;
@property (nonatomic, retain) IBOutlet NSTextField *a;
@property (nonatomic, retain) IBOutlet NSTextField *b;
@property (nonatomic, retain) IBOutlet NSTextField *scale;
@property (nonatomic, retain) IBOutlet NSTextField *x;
@property (nonatomic, retain) IBOutlet NSTextField *y;

- (IBAction)performanceTest:(id)sender;

@end
