//
//  MandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ColorPalette;

@interface MandelbrotView : NSView <NSWindowDelegate>
{
    NSBitmapImageRep *fractalBitmapRepresentation;
    NSImage *fractalImage;
    ColorPalette *colorPalette;
    CGFloat zoomX, zoomY, zoomScale;
    NSInteger maxIterations;
    
    NSRect dragRect;
    
    NSAffineTransform *viewToFractal;
    
    NSRect baseFractalSpace;

    // Used by drawFractal to prevent more than one thread from calling drawFractal at a time,
    // so benchmarks aren't affected by race conditions.
    NSLock *renderLock;

    // Lock when modifying or reading fractalBitmapRepresentation
    NSLock *bitmapLock;
}

- (instancetype)initWithFrame:(NSRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@property (assign) NSTimeInterval renderTime;
@property (assign) CGFloat zoomX;
@property (assign) CGFloat zoomY;
@property (assign) CGFloat zoomScale;
@property (assign) NSInteger maxIterations;
@property (assign) BOOL isRendering;
@property (assign) BOOL isDragging;

- (void)redrawFractal;
- (void)resize;
- (NSRect)zoom;

@end
