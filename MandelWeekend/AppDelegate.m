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
    [self.mandelbrotView drawFractalAsync];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification
{
    [self.mandelbrotView drawFractalAsync];
}

@end
