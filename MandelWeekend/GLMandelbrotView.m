//
//  GLMandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 1/17/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import "GLMandelbrotView.h"

@implementation GLMandelbrotView

- (void)prepareOpenGL
{
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    [[self openGLContext] flushBuffer];
}

- (void)reshape
{
    // TODO: change opengl viewport
    [super reshape];
}

@end
