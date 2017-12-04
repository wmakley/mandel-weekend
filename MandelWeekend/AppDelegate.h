//
//  AppDelegate.h
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLMandelbrotView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet GLMandelbrotView *mandelbrotView;
@property (assign) IBOutlet NSTextField *benchmarkTextField;

- (IBAction)maxIterationsChanged:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;

@end
