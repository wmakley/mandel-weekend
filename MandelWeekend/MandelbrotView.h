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
    NSLock *renderLock;
}

@property (assign) NSTimeInterval benchmark;
@property (assign) CGFloat zoomX;
@property (assign) CGFloat zoomY;
@property (assign) CGFloat zoomScale;
@property (assign) NSInteger maxIterations;

- (void)clearFractal;
- (void)drawFractalAsync;
- (void)generateColorPalette;
- (void)resize;
- (NSRect)zoom;

@end
