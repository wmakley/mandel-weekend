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
    for (UInt32 i = 0; i < MAX_ITERATIONS - 1; i += 1) {
        UInt32 color = 0x000000FF; // full alpha
        color = color | (((MAX_ITERATIONS - i) % 256) << 8);
        color = color | ((i % 256) << 16);
        color = color | ((i * 10 % 256) << 24);
        colorPalette[i] = color;
    }
    colorPalette[MAX_ITERATIONS - 1] = 0x000000FF; // black if point doesn't escape
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
    NSInteger pixelsWide = [fractalRep pixelsWide];
    NSInteger pixelsHigh = [fractalRep pixelsHigh];
    NSInteger bitmapLength = 4 * pixelsWide * pixelsHigh;
    
    NSPoint pixel = NSMakePoint(0.0f, 0.0f);
    NSSize imageSize = NSMakeSize([fractalRep pixelsWide], [fractalRep pixelsHigh]);
    
    for (NSInteger i = 0; i < bitmapLength; i += 4) {
        
        pixel.x = (i / 4) % pixelsWide;
        pixel.y = (i / 4) / pixelsWide;
        
        NSPoint mandelbrotPoint = mandelbrot_point_for_pixel(pixel, imageSize);
        NSInteger escapeTime = mandelbrot_escape_time(mandelbrotPoint, MAX_ITERATIONS);
        UInt32 color = colorPalette[escapeTime - 1];
        
        bitmapData[i] = color >> 24;
        bitmapData[i+1] = color >> 16;
        bitmapData[i+2] = color >> 8;
        bitmapData[i+3] = color;

    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    [fractalImage drawInRect:[self bounds]];
}

@end
