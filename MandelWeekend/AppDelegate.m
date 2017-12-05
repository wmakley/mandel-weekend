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
    [_mandelbrotView resize];
}

- (IBAction)refreshButtonPressed:(id)sender
{
    [_mandelbrotView redrawFractal];
}

- (IBAction)maxIterationsChanged:(id)sender
{
//    [self refreshButtonPressed:sender];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{
    [_mandelbrotView resize];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [_mandelbrotView cleanUpOpenGL];
}

@end
