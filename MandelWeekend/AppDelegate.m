//
//  AppDelegate.m
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_mandelbrotView setNeedsDisplay:YES];
}

- (IBAction)refreshButtonPressed:(id)sender
{
    [_mandelbrotView setNeedsDisplay:YES];
}

- (IBAction)maxIterationsChanged:(id)sender
{
    // sometimes the change isn't sent when the enter key is pressed
    [self refreshButtonPressed:sender];
}

- (void)windowWillStartLiveResize:(NSNotification *)notification {
    [_mandelbrotView setIsLiveResizing:YES];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{
    [_mandelbrotView setIsLiveResizing:NO];
    // we are using live resizing for now, since there is no way to disable it
//    [_mandelbrotView resize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
//    [_mandelbrotView cleanUpOpenGL];
}

@end
