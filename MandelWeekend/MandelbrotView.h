//
//  MandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MandelbrotView : NSView <NSWindowDelegate>
{
    NSBitmapImageRep *fractalBitmapRepresentation;
    NSImage *fractalImage;
}

@property (assign) NSTimeInterval benchmark;

- (void)clearFractal;
- (void)drawFractalAsync;
- (void)resize;

@end
