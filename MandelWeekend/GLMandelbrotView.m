//
//  GLMandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import "GLMandelbrotView.h"
#import "ColorPalette.h"
#import "mandelbrot.h"

@interface GLMandelbrotView (Private)
- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint;
- (NSRect)zoomedFractalSpace;
- (void)zoomToDragRect;
@end

@implementation GLMandelbrotView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _zoomX = 0.0;
        _zoomY = 0.0;
        _zoomScale = 1.0;
        _maxIterations = 1000;
        _baseFractalSpace = NSMakeRect(-0.72, 0.0, 3.5, 2.3);
        _isRendering = NO;
        _colorPalette = [[ColorPalette alloc] initWithMaxIterations:_maxIterations];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self setIsRendering:YES];
    [super drawRect:dirtyRect];
    
    glBegin(GL_QUADS);
    glTexCoord2f(0, 0);
    glVertex2f(-1, -1);
    glTexCoord2f(1, 0);
    glVertex2f(1, -1);
    glTexCoord2f(1, 1);
    glVertex2f(1, 1);
    glTexCoord2f(0, 1);
    glVertex2f(-1, 1);
    glEnd();
    
    [self setIsRendering:NO];
}

- (void)resize {
    // TODO
}

- (void)prepareOpenGL {
    // setup OpenGL here
}

- (CGFloat)aspectRatio {
    NSRect bounds = [self bounds];
    return bounds.size.width / bounds.size.height;
}

- (NSRect)zoom {
    return NSMakeRect(_zoomX, _zoomY, _zoomScale, _zoomScale);
}

- (void)zoomToDragRect {
    // TODO
}

- (NSRect)zoomedFractalSpace {
    return zoom_in_on_rect(_baseFractalSpace, [self zoom]);
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    _dragRect = NSMakeRect(location.x, location.y, 0, 0);
    
    [self setIsDragging:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if ([self isRendering]) return;
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    _dragRect.size.width = location.x - _dragRect.origin.x;
    _dragRect.size.height = _dragRect.size.width / [self aspectRatio];
    
    if (_dragRect.size.width < 0 && location.y > _dragRect.origin.y) {
        _dragRect.size.height *= -1;
    }
    else if (_dragRect.size.width > 0 && location.y < _dragRect.origin.y) {
        _dragRect.size.height *= -1;
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
