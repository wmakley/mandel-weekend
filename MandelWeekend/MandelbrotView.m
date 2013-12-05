//
//  MandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "MandelbrotView.h"
#import "mandelbrot.h"
#import <dispatch/dispatch.h>

@interface MandelbrotView (Private)
@property (readonly) NSBitmapImageRep *fractalBitmapRepresentation;
- (void)drawFractal;
- (NSPoint)coordinatesOfPixelAtIndex:(NSInteger)index width:(NSInteger)width height:(NSInteger)height;
@end

@implementation MandelbrotView

@synthesize benchmark, zoomX, zoomY, zoomScale, maxIterations;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fractalImage = [[NSImage alloc] init];
        renderLock = [[NSLock alloc] init];
        zoomX = 0.0;
        zoomY = 0.0;
        zoomScale = 1.0;
        maxIterations = 1000;
        [self generateColorPalette];
    }
    return self;
}

- (void)generateColorPalette
{
    NSUInteger totalColors = self.maxIterations;
    NSUInteger byteLength = totalColors * sizeof(UInt32);
    if (!colorPalette) {
        colorPalette = [[NSMutableData alloc] initWithCapacity:byteLength];
    }
    else if (colorPalette.length != byteLength) {
        [colorPalette setLength:byteLength];
    }
    UInt32 *colors = [colorPalette mutableBytes];
    for (UInt32 i = 0; i < totalColors; i += 1) {
        // alpha = 255
        UInt32 color = 0x000000FF;
        // red
        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 255.0) << 24);
        // green
        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 100.0) << 16);
        // blue
        color = color | ((i % 256) << 8);
        colors[i] = color;
    }
    colors[totalColors - 1] = 0x000000FF; // black if point doesn't escape
}

- (void)clearFractal;
{
    if (fractalBitmapRepresentation) {
        [fractalImage removeRepresentation:fractalBitmapRepresentation];
        fractalBitmapRepresentation = nil;
    }
}

- (NSPoint)coordinatesOfPixelAtIndex:(NSInteger)index width:(NSInteger)width height:(NSInteger)height
{
    // origin is in lower-left to match Cocoa conventions
    return NSMakePoint(index % width, (height - 1) - (index / width));
}

- (NSBitmapImageRep *)fractalBitmapRepresentation {
    if (!fractalBitmapRepresentation) {
        NSRect offscreenRect = [self bounds];
        fractalBitmapRepresentation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                             pixelsWide:offscreenRect.size.width
                                                             pixelsHigh:offscreenRect.size.height
                                                          bitsPerSample:8
                                                        samplesPerPixel:4
                                                               hasAlpha:YES
                                                               isPlanar:NO
                                                         colorSpaceName:NSCalibratedRGBColorSpace
                                                           bitmapFormat:0
                                                            bytesPerRow:(4 * offscreenRect.size.width)
                                                           bitsPerPixel:32];
        [fractalImage addRepresentation:fractalBitmapRepresentation];
    }
    return fractalBitmapRepresentation;
}

- (void)drawFractalAsync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self drawFractal];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay:YES];
        });
    });
}

- (void)drawFractal
{
    [renderLock lock];
    [self setBenchmark:0];
    NSTimeInterval benchStart = [NSDate timeIntervalSinceReferenceDate];
    
    NSBitmapImageRep *fractalRep = [self fractalBitmapRepresentation];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:fractalRep]];
    
    unsigned char *bitmapData = [fractalRep bitmapData];
    UInt32 *colors = [colorPalette mutableBytes];
    NSInteger pixelsWide = [fractalRep pixelsWide];
    NSInteger pixelsHigh = [fractalRep pixelsHigh];
    NSInteger totalPixels = pixelsWide * pixelsHigh;

    NSSize imageSize = NSMakeSize(pixelsWide, pixelsHigh);
    
    static const NSRect baseMandelbrotSpace = {{-0.72, 0.0}, {3.5, 2.3}};
    NSRect mandelbrotSpace = zoom_in_on_rect(baseMandelbrotSpace, [self zoom]);
    
    dispatch_apply(totalPixels,
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^(size_t i){
        
        NSPoint pixel = [self coordinatesOfPixelAtIndex:i width:pixelsWide height:pixelsHigh];
        NSPoint mandelbrotPoint = mandelbrot_point_for_pixel(pixel, imageSize, mandelbrotSpace);
        NSInteger escapeTime = mandelbrot_escape_time(mandelbrotPoint, maxIterations);
        UInt32 color = colors[escapeTime - 1];
        
        NSInteger bitmapIndex = i * 4;
        bitmapData[bitmapIndex] = color >> 24;
        bitmapData[bitmapIndex+1] = color >> 16;
        bitmapData[bitmapIndex+2] = color >> 8;
        bitmapData[bitmapIndex+3] = color;

    });
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSTimeInterval benchEnd = [NSDate timeIntervalSinceReferenceDate];
    [self setBenchmark:(benchEnd - benchStart)];
    [renderLock unlock];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    if (fractalImage.representations.count > 0) {
        [fractalImage drawInRect:[self bounds]];
    }
}

- (void)resize
{
    [self clearFractal];
    [self drawFractalAsync];
}

- (NSRect)zoom
{
    return NSMakeRect(zoomX, zoomY, zoomScale, zoomScale);
}

@end
