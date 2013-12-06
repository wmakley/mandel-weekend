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
    NSMutableData *colorPalette;
    CGFloat zoomX, zoomY, zoomScale;
    NSInteger maxIterations;
    NSAffineTransform *viewTransformation;

    // Used by drawFractal to prevent more than one thread from calling drawFractal at a time,
    // so benchmarks aren't affected by race conditions.
    NSLock *renderLock;

    // Lock when modifying or reading fractalBitmapRepresentation
    NSLock *bitmapLock;
}

@property (assign) NSTimeInterval benchmark;
@property (assign) CGFloat zoomX;
@property (assign) CGFloat zoomY;
@property (assign) CGFloat zoomScale;
@property (assign) NSInteger maxIterations;
@property (assign) BOOL isRendering;

- (void)clearFractal;
- (void)drawFractalAsync;
- (void)generateColorPalette;
- (void)resize;
- (NSRect)zoom;

@end
