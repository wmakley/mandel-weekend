//
//  MandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/29/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "MandelbrotView.h"
#import "ColorPalette.h"
#import "mandelbrot.h"
#import <dispatch/dispatch.h>
#import <math.h>

@interface MandelbrotView (Private)
- (CGFloat)aspectRatio;
- (NSBitmapImageRep *)fractalBitmapRepresentation;
- (void)drawFractal;
- (void)drawFractalAsync;
- (NSPoint)coordinatesOfPixelAtIndex:(NSInteger)index width:(NSInteger)width height:(NSInteger)height;
- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint;
- (NSRect)zoomedFractalSpace;
- (void)zoomToDragRect;
- (UInt32)colorForEscapeTime:(NSInteger)escapeTime;
@end

@implementation MandelbrotView

@synthesize renderTime, zoomX, zoomY, zoomScale, maxIterations;

- (instancetype)initWithFrame:(NSRect)frame
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
        colorPalette = [[ColorPalette alloc] initWithMaxIterations:maxIterations];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        fractalImage = [coder decodeObjectForKey:@"fractalImage"];
        renderLock = [[NSLock alloc] init];
        bitmapLock = [[NSLock alloc] init];
        zoomX = [coder decodeDoubleForKey:@"zoomX"];
        zoomY = [coder decodeDoubleForKey:@"zoomY"];
        zoomScale = [coder decodeDoubleForKey:@"zoomScale"];
        maxIterations = [coder decodeIntegerForKey:@"maxIterations"];
        baseFractalSpace = NSMakeRect(-0.72, 0.0, 3.5, 2.3);
        self.isRendering = NO;
        colorPalette = [[ColorPalette alloc] initWithMaxIterations:maxIterations];
    }
    return self;
}

- (void)generateColorPalette
{
    [colorPalette setMaxIterations:self.maxIterations];
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
        UInt32 color = [colorPalette colorForEscapeTime:escapeTime];
        
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
        
        // flip rect origin if width or height is negative
        NSRect fixedDragRect = dragRect;
        if (fixedDragRect.size.width < 0) {
            fixedDragRect.origin.x += fixedDragRect.size.width;
            fixedDragRect.size.width *= -1;
        }
        if (fixedDragRect.size.height < 0) {
            fixedDragRect.origin.y += fixedDragRect.size.height;
            fixedDragRect.size.height *= -1;
        }
        [[NSColor whiteColor] setStroke];
        [NSBezierPath strokeRect:fixedDragRect];
    }
}

- (void)redrawFractal
{
    [self clearFractal];
    [colorPalette setMaxIterations:self.maxIterations];
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
    if (fabs(dragRect.size.width) > 2) {
        CGFloat dragWidth = currentSpace.size.width * fabs(dragRect.size.width) / self.bounds.size.width;
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
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    dragRect = NSMakeRect(location.x, location.y, 0, 0);
    
    [self setIsDragging:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    dragRect.size.width = location.x - dragRect.origin.x;
    dragRect.size.height = dragRect.size.width / [self aspectRatio];
    
    if (dragRect.size.width < 0 && location.y > dragRect.origin.y) {
        dragRect.size.height *= -1;
    }
    else if (dragRect.size.width > 0 && location.y < dragRect.origin.y) {
        dragRect.size.height *= -1;
    }
    
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
