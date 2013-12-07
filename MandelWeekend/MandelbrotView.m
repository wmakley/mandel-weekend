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
- (CGFloat)aspectRatio;
- (NSBitmapImageRep *)fractalBitmapRepresentation;
- (void)drawFractal;
- (void)drawFractalAsync;
- (NSPoint)coordinatesOfPixelAtIndex:(NSInteger)index width:(NSInteger)width height:(NSInteger)height;
- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint;
- (NSRect)zoomedFractalSpace;
- (void)zoomToDragRect;
@end

@implementation MandelbrotView

@synthesize renderTime, zoomX, zoomY, zoomScale, maxIterations;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fractalImage = [[NSImage alloc] init];
        renderLock = [[NSLock alloc] init];
        bitmapLock = [[NSLock alloc] init];
        zoomX = 0.0;
        zoomY = 0.0;
        zoomScale = 1.0;
        maxIterations = 1000;
        baseFractalSpace = NSMakeRect(-0.72, 0.0, 3.5, 2.3);
        self.isRendering = NO;
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

- (CGFloat)aspectRatio
{
    NSRect bounds = [self bounds];
    return bounds.size.width / bounds.size.height;
}

- (void)clearFractal;
{
    [bitmapLock lock];
    if (fractalBitmapRepresentation) {
        [fractalImage removeRepresentation:fractalBitmapRepresentation];
        fractalBitmapRepresentation = nil;
    }
    [bitmapLock unlock];
}

- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint
{
    return mandelbrot_point_for_pixel(screenPoint, [self bounds].size, [self zoomedFractalSpace]);
}

// Convert the index of pixel in a 1D array of pixels to a 2D point.
- (NSPoint)coordinatesOfPixelAtIndex:(NSInteger)index width:(NSInteger)width height:(NSInteger)height
{
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
    if ([self isRendering]) {
        return;
    }
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
    [self setIsRendering:YES];
    [self setRenderTime:0];
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    [bitmapLock lock];
    NSBitmapImageRep *fractalRep = [self fractalBitmapRepresentation];
    
    unsigned char *bitmapData = [fractalRep bitmapData];
    UInt32 *colors = [colorPalette mutableBytes];
    NSInteger pixelsWide = [fractalRep pixelsWide];
    NSInteger pixelsHigh = [fractalRep pixelsHigh];
    NSInteger totalPixels = pixelsWide * pixelsHigh;

    NSSize imageSize = NSMakeSize(pixelsWide, pixelsHigh);
    NSRect fractalSpace = [self zoomedFractalSpace];
    
    dispatch_apply(totalPixels,
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^(size_t i){
        
        NSPoint pixel = [self coordinatesOfPixelAtIndex:i width:pixelsWide height:pixelsHigh];
        NSPoint mandelbrotPoint = mandelbrot_point_for_pixel(pixel, imageSize, fractalSpace);
        NSInteger escapeTime = mandelbrot_escape_time(mandelbrotPoint, maxIterations);
        UInt32 color = colors[escapeTime - 1];
        
        NSInteger bitmapIndex = i * 4;
        bitmapData[bitmapIndex] = color >> 24;
        bitmapData[bitmapIndex+1] = color >> 16;
        bitmapData[bitmapIndex+2] = color >> 8;
        bitmapData[bitmapIndex+3] = color;

    });
    
    [bitmapLock unlock];
    
    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    [self setRenderTime:(endTime - startTime)];
    [self setIsRendering:NO];
    [renderLock unlock];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // fill with black
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    
    // blit fractal image
    [bitmapLock lock];
    if (fractalImage.representations.count > 0) {
        [fractalImage drawInRect:[self bounds]];
    }
    [bitmapLock unlock];
    
    // draw drag rect if dragging
    if (self.isDragging) {
        [[NSColor whiteColor] setStroke];
        [NSBezierPath strokeRect:dragRect];
    }
}

- (void)redrawFractal
{
    [self clearFractal];
    [self drawFractalAsync];
}

- (void)resize
{
    [self redrawFractal];
}

- (NSRect)zoom
{
    return NSMakeRect(zoomX, zoomY, zoomScale, zoomScale);
}

- (NSRect)zoomedFractalSpace
{
    return zoom_in_on_rect(baseFractalSpace, [self zoom]);
}

- (void)zoomToDragRect
{
    NSRect currentSpace = [self zoomedFractalSpace];
    
    // cancel zoom if the box is too small
    CGFloat newScale = [self zoomScale];
    if (dragRect.size.width > 2) {
        CGFloat dragWidth = currentSpace.size.width * dragRect.size.width / self.bounds.size.width;
        newScale = dragWidth / baseFractalSpace.size.width;
    }

    // get center of drag rect in pixel coordinates, and convert to fractal coordinates
    NSPoint dragCenterPx = NSMakePoint( dragRect.origin.x + (dragRect.size.width / 2.0),
                                        dragRect.origin.y + (dragRect.size.height / 2.0) );

    NSPoint dragCenter = [self convertScreenPointToFractalPoint:dragCenterPx];
    
    // Calculate new zoom translation by taking different between this point and fractal space translation
    // and adding it to the old zoom translation.
    NSPoint translation = NSMakePoint( zoomX + (dragCenter.x - currentSpace.origin.x),
                                       zoomY + (dragCenter.y - currentSpace.origin.y) );
    
    [self setZoomScale: newScale];
    [self setZoomX: translation.x];
    [self setZoomY: translation.y];
    [self redrawFractal];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    NSPoint location = [self convertPointFromBase:[theEvent locationInWindow]];
    
    dragRect = NSMakeRect(location.x, location.y, 0, 0);
    
    [self setIsDragging:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    NSPoint location = [self convertPointFromBase:[theEvent locationInWindow]];
    
    dragRect.size.width = location.x - dragRect.origin.x;
    dragRect.size.height = dragRect.size.width / [self aspectRatio];
    
    [self setIsDragging:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    [self setIsDragging:NO];
    [self zoomToDragRect];
}

@end
