//
//  MandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "MandelbrotView.h"
#import "mandelbrot.h"

#define MAX_ITERATIONS 1000

static UInt32 colorPalette[MAX_ITERATIONS];

@implementation MandelbrotView

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
    for (NSInteger i = 0; i < MAX_ITERATIONS; i += 1) {
        colorPalette[i] = i % 1000 * 10;
    }
}

- (void)drawFractal
{
    if (fractalRep) {
        [fractalImage removeRepresentation:fractalRep];
        fractalRep = nil;
    }
    NSRect offscreenRect = [self bounds];
    fractalRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
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
    [fractalImage addRepresentation:fractalRep];
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:fractalRep]];
    
    unsigned char *bitmapData = [fractalRep bitmapData];
    NSInteger bitmapLength = 4 * [fractalRep pixelsWide] * [fractalRep pixelsHigh];
    
    NSPoint pixel = NSMakePoint(0.0f, 0.0f);
    NSSize imageSize = NSMakeSize([fractalRep pixelsWide], [fractalRep pixelsHigh]);
    NSPoint mandelbrotPoint;
    NSInteger escapeTime;
    
    for (NSInteger i = 0; i < bitmapLength; i += 4) {
        pixel.x += 1;
        if (pixel.x > imageSize.width - 1) {
            pixel.x = 0;
            pixel.y += 1;
        }
        mandelbrotPoint = mandelbrot_point_for_pixel(pixel, imageSize);
        escapeTime = mandelbrot_escape_time(mandelbrotPoint, MAX_ITERATIONS);
        
        if (escapeTime < MAX_ITERATIONS) {
            bitmapData[i] = colorPalette[escapeTime] > 2;
            bitmapData[i+1] = colorPalette[escapeTime] > 1;
            bitmapData[i+2] = colorPalette[escapeTime];
        }
        
        bitmapData[i+3] = 255;
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    [fractalImage drawInRect:[self bounds]];
}

@end
