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

// g for global
static const GLfloat g_vertexBufferData[] = {
    -1.0f, -1.0f, 0.0f, // lower left
    1.0f, -1.0f, 0.0f, // lower right
    1.0f,  1.0f, 0.0f, // top right
    -1.0f, 1.0f, 0.0f // top left
};

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
        
        _vertexArrayID = 0;
        _vertexBuffer = 0;
        _vertexShaderID = 0;
        _fragmentShaderID = 0;
        [self setWantsBestResolutionOpenGLSurface:YES];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // prevent certain state changes during rendering
    [self setIsRendering:YES];
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glVertexAttribPointer(
        0,              // attribute 0. No particular reason for 0, but must match the layout in the shader.
        4,              // size
        GL_FLOAT,       // type
        GL_FALSE,       // normalized?
        0,              // stride
        (void*)0        // array buffer offset
    );
    glDrawArrays(GL_QUADS, 0, 4); // Starting from vertex 0; 4 vertices total -> 1 quad
    glDisableVertexAttribArray(0);
    
    glFlush();
    
    [self setIsRendering:NO];
}

- (void)prepareOpenGL {
    glGenVertexArraysAPPLE(1, &_vertexArrayID);
    glBindVertexArrayAPPLE(_vertexArrayID);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertexBufferData), g_vertexBufferData, GL_STATIC_DRAW);
    
    _vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    _fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    glClearColor(0, 0, 0, 0);
}

- (CGFloat)aspectRatio {
    NSRect bounds = [self bounds];
    return bounds.size.width / bounds.size.height;
}

- (void)redrawFractal {
    [self setNeedsDisplay:YES];
    // TODO
}

- (void)resize {
    // TODO
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
