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

#define MAX_ITERATIONS 1000

static UInt32 colorPalette[MAX_ITERATIONS];

@interface MandelbrotView (Private)
@property (readonly) NSBitmapImageRep *fractalBitmapRepresentation;
- (void)drawFractal;
- (void)generateColorPalette;
@end

@implementation MandelbrotView

@synthesize benchmark;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fractalImage = [[NSImage alloc] init];
        [self generateColorPalette];
    }
    return self;
}

- (void)generateColorPalette
{
    for (UInt32 i = 0; i < MAX_ITERATIONS - 1; i += 1) {
        UInt32 color = 0x000000FF; // full alpha
        color = color | (((MAX_ITERATIONS - i) % 256) << 8);
        color = color | ((i % 256) << 16);
        color = color | ((i * 10 % 256) << 24);
        colorPalette[i] = color;
    }
    colorPalette[MAX_ITERATIONS - 1] = 0x000000FF; // black if point doesn't escape
}

- (void)clearFractal;
{
    if (fractalBitmapRepresentation) {
        [fractalImage removeRepresentation:fractalBitmapRepresentation];
        fractalBitmapRepresentation = nil;
    }
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

- (void)resize
{
    [self clearFractal];
    [self drawFractalAsync];
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

- (void)drawFractal
{
    [self setBenchmark:0];
    NSTimeInterval benchStart = [NSDate timeIntervalSinceReferenceDate];
    
    NSBitmapImageRep *fractalRep = [self fractalBitmapRepresentation];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:fractalRep]];
    
    unsigned char *bitmapData = [fractalRep bitmapData];
    NSInteger pixelsWide = [fractalRep pixelsWide];
    NSInteger pixelsHigh = [fractalRep pixelsHigh];
    NSInteger totalPixels = pixelsWide * pixelsHigh;

    NSSize imageSize = NSMakeSize(pixelsWide, pixelsHigh);
    
    dispatch_apply(totalPixels,
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^(size_t i){
        
        NSPoint pixel = NSMakePoint(i % pixelsWide, i / pixelsWide);

        NSPoint mandelbrotPoint = mandelbrot_point_for_pixel(pixel, imageSize);
        NSInteger escapeTime = mandelbrot_escape_time(mandelbrotPoint, MAX_ITERATIONS);
        UInt32 color = colorPalette[escapeTime - 1];
        
        NSInteger bitmapIndex = i * 4;
        bitmapData[bitmapIndex] = color >> 24;
        bitmapData[bitmapIndex+1] = color >> 16;
        bitmapData[bitmapIndex+2] = color >> 8;
        bitmapData[bitmapIndex+3] = color;

    });
    
    [NSGraphicsContext restoreGraphicsState];
    
    NSTimeInterval benchEnd = [NSDate timeIntervalSinceReferenceDate];
    [self setBenchmark:(benchEnd - benchStart)];
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

@end
