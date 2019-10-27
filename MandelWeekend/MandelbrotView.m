//
//  MandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "MandelbrotView.h"
#import "GLMandelbrotLayer.h"

@implementation MandelbrotView

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if ( self != nil )
    {
        // Enable retina-support
        [self setWantsBestResolutionOpenGLSurface: YES];

        // Enable layer-backed drawing of view
        [self setWantsLayer:YES];
    }
    return self;
}

- (CALayer *)makeBackingLayer
{
    return [[GLMandelbrotLayer alloc] init];
}

- (void)viewDidChangeBackingProperties
{
    [super viewDidChangeBackingProperties];

    // Need to propagate information about retina resolution
    self.layer.contentsScale = self.window.backingScaleFactor;
}

@end
