//
//  GLMandelbrotView.m
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import "GLMandelbrotView.h"
#import "mandelbrot.h"
#import <math.h>


// g for global. vertices for 2 triangles making a quad.
static const GLfloat g_vertexBufferData[] = {
    -1.0f, -1.0f, 0.0f, // lower left
    1.0f, -1.0f, 0.0f, // lower right
    1.0f,  1.0f, 0.0f, // top right
    
    -1.0f, 1.0f, 0.0f, // top left
    -1.0f, -1.0f, 0.0f, // lower left
    1.0f,  1.0f, 0.0f // top right
};


@interface GLMandelbrotView (Private)
- (NSSize)screenSizeInPixels;

- (void)zoomToDragRect;

- (void)sendTextureData;
- (void)setScreenSizeUniform:(NSSize)screenSize;
- (void)setTranslationUniformX:(GLdouble)x Y:(GLdouble)y;
- (void)setScaleUniform:(GLdouble)scale;
- (void)setMaxIterationsUniform:(GLint)maxIterations;

- (NSRect)baseGraphTransformationsAsRect;
- (NSRect)zoomedGraphTransformationsAsRect;
@end

@implementation GLMandelbrotView

+ (GLint)defaultMaxIterations {
    return 100;
}

+ (NSSize)defaultGraphSize {
    return NSMakeSize(2.6, 2.3);
}

+ (NSPoint)defaultTranslation {
    return NSMakePoint(-0.75, 0.0);
}


- (instancetype)initWithFrame:(NSRect)frame {
    NSOpenGLPixelFormatAttribute attrs[] =
    {
//        NSOpenGLPFADoubleBuffer, // This causes a black screen
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    
    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        [self setWantsBestResolutionOpenGLSurface:YES]; // enable retina support
//        [self setWantsLayer:YES]; // for over-laying the drag rect, but currently broken

        _zoomX = 0.0;
        _zoomY = 0.0;
        _zoomScale = 1.0;
        _maxIterations = [GLMandelbrotView defaultMaxIterations];
        _isRendering = NO;
        _isLiveResizing = NO;
        _texture = [[GradientTexture alloc] init];
        
        _baseGraphSize = [GLMandelbrotView defaultGraphSize];
        _baseTranslation = [GLMandelbrotView defaultTranslation];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    if ([self isDragging] || [self isRendering]) return;
//    NSLog(@"drawRect");

    [self setIsRendering:YES];
    [self setRenderTime:0];
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glVertexAttribPointer(
        0,              // attribute 0. No particular reason for 0, but must match the layout in the shader.
        3,              // vertex size
        GL_FLOAT,       // type
        GL_FALSE,       // normalized?
        0,              // stride
        (void*)0        // array buffer offset
    );
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDisableVertexAttribArray(0);
    
    glFlush();
    
    // block until rendering is done
    glFinish();

    NSTimeInterval endTime = [NSDate timeIntervalSinceReferenceDate];
    [self setRenderTime:endTime - startTime];
    [self setIsRendering:NO];
}

- (void)reshape {
    [super reshape];
//    NSLog(@"reshape");
    // Just do live resizing for now
    NSSize screenSize = [self screenSizeInPixels];
    glViewport(0, 0, screenSize.width, screenSize.height);
    [self setScreenSizeUniform:screenSize];
}

- (void)setIsLiveResizing:(BOOL)isLiveResizing {
    // Speed up the shader if the window is resizing
    if (_isLiveResizing != isLiveResizing) {
        _isLiveResizing = isLiveResizing;
        [self setMaxIterationsUniform:
            isLiveResizing
                ? [self maxIterationsDuringLiveResize]
                : (GLint)_maxIterations];
        [self setNeedsDisplay:YES];
    }
}

- (GLint)maxIterationsDuringLiveResize {
    return 50;
}

// Called externally when the view may have resized
- (void)resize {
    NSSize screenSize = [self screenSizeInPixels];
    glViewport(0, 0, screenSize.width, screenSize.height);
    [self setScreenSizeUniform:screenSize];
    [self setNeedsDisplay:YES]; // uncomment if this is called externally
}

- (void)prepareOpenGL {
    [super prepareOpenGL];

    NSLog(@"OpenGL version is %s.\nSupported GLSL version is %s.",
          (char *)glGetString(GL_VERSION),
          (char *)glGetString(GL_SHADING_LANGUAGE_VERSION)
    );
    
    // Set viewport to actual pixel dimensions (retina)
    NSSize screenSize = [self screenSizeInPixels];
    glViewport(0, 0, screenSize.width, screenSize.height);
    
    glGenVertexArrays(1, &_vertexArrayID);
    glBindVertexArray(_vertexArrayID);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertexBufferData), g_vertexBufferData, GL_STATIC_DRAW);
//    NSLog(@"vertices size: %lu", sizeof(g_vertexBufferData));

    _fractalProgram = [[ShaderProgram alloc] init];
    [_fractalProgram addVertexShaderWithFileName:@"mandelbrot"];
    [_fractalProgram addFragmentShaderWithFileName:@"mandelbrot"];
    if ( ! [_fractalProgram compileAndLink] ) {
        [self cleanUpOpenGL];
        abort();
    }
    
//    NSLog(@"Shader program is valid, activating");
    _programID = [_fractalProgram programID];
    [_fractalProgram useProgram];
    
    glGenTextures(1, &_gradientTextureID);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_1D, _gradientTextureID);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    [self sendTextureData];
    
//    GLint texLoc = [_fractalProgram getUniformLocation:"tex"];
    GLint graphSizeLoc = [_fractalProgram getUniformLocation:"graphSize"];
    _screenSizeUniformLoc = [_fractalProgram getUniformLocation:"screenSize"];
    _translateUniformLoc = [_fractalProgram getUniformLocation:"translate"];
    _scaleUniformLoc = [_fractalProgram getUniformLocation:"scale"];
    _maxIterationsUniformLoc = [_fractalProgram getUniformLocation:"iter"];

    // uniform sampler1D tex - always points to texture 0;
//    glProgramUniform1i(_programID, texLoc, 0);
    // Base scaling of the graph never changes, but we need to know it
    // both here and in the shader.
    glProgramUniform2d(_programID, graphSizeLoc, _baseGraphSize.width, _baseGraphSize.height);
    [self setScreenSizeUniform:screenSize];
    [self setTranslationUniformX:_zoomX Y:_zoomY];
    [self setScaleUniform:_zoomScale];
    [self setMaxIterationsUniform:(GLint)_maxIterations];
    
    // Set up render-to-texture
//    glGenFramebuffers(1, &_framebufferID);
//    glGenTextures(1, &_renderedTextureID);
//
//    glBindTexture(GL_TEXTURE_2D, _renderedTextureID);
//    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGB, 1024, 768, 0,GL_RGB, GL_UNSIGNED_BYTE, 0);
}

// Needs to be called any time the texture changes
- (void)sendTextureData {
    glTexImage1D(
                 GL_TEXTURE_1D, // target
                 0, // mip map level (0 = base)
                 GL_RGBA, // internalFormat
                 [_texture width], // width in texels
                 0, // border (legacy; must be 0)
                 GL_RGB, // external format
                 GL_FLOAT, // external type of each individual color component
                 [_texture bytes] // data
    );
}

- (CGFloat)aspectRatio {
    NSRect bounds = [self bounds];
    return bounds.size.width / bounds.size.height;
}

- (void)redrawFractal {
    [self setNeedsDisplay:YES];
}


- (void)setZoomX:(CGFloat)zoomX {
    if (zoomX != _zoomX) {
        [self willChangeValueForKey:@"zoomX"];
        _zoomX = zoomX;
        [self setTranslationUniformX:_zoomX Y:_zoomY];
        [self didChangeValueForKey:@"zoomX"];
    }
}

- (void)setZoomY:(CGFloat)zoomY {
    if (zoomY != _zoomY) {
        [self willChangeValueForKey:@"zoomY"];
        _zoomY = zoomY;
        [self setTranslationUniformX:_zoomX Y:_zoomY];
        [self didChangeValueForKey:@"zoomY"];
    }
}

// Set both X and Y at the same time if both changed to avoid 2 re-draws
- (void)setZoomX:(CGFloat)zoomX Y:(CGFloat)zoomY {
    BOOL changed = NO;
    if (zoomX != _zoomX) {
        [self willChangeValueForKey:@"zoomX"];
        _zoomX = zoomX;
        [self didChangeValueForKey:@"zoomX"];
        changed = YES;
    }
    if (zoomY != _zoomY) {
        [self willChangeValueForKey:@"zoomY"];
        _zoomY = zoomY;
        [self didChangeValueForKey:@"zoomY"];
        changed = YES;
    }
    if (changed) {
        [self setTranslationUniformX:_zoomX Y:_zoomY];
    }
}

- (void)setZoomScale:(CGFloat)zoomScale {
    if (zoomScale != _zoomScale) {
        [self willChangeValueForKey:@"zoomScale"];
        _zoomScale = zoomScale;
        [self didChangeValueForKey:@"zoomScale"];
        [self setScaleUniform:zoomScale];
    }
}

- (void)setMaxIterations:(GLint)maxIterations {
    GLint clamped;
    if (maxIterations < 1) {
        clamped = 1;
    } else if (maxIterations > 20000) {
        clamped = 20000;
    } else {
        clamped = maxIterations;
    }

    if (clamped != _maxIterations) {
        [self willChangeValueForKey:@"maxIterations"];
        _maxIterations = clamped;
        [self didChangeValueForKey:@"maxIterations"];
        [self setMaxIterationsUniform:(GLint)_maxIterations];
    }
}


- (void)setScreenSizeUniform:(NSSize)screenSize {
    glProgramUniform2d(_programID, _screenSizeUniformLoc, screenSize.width, screenSize.height);
}

- (void)setTranslationUniformX:(GLdouble)x Y:(GLdouble)y {
    glProgramUniform2d(_programID, _translateUniformLoc, _baseTranslation.x + x, y);
}

- (void)setScaleUniform:(GLdouble)scale {
    glProgramUniform1d(_programID, _scaleUniformLoc, scale);
}

- (void)setMaxIterationsUniform:(GLint)maxIterations {
    glProgramUniform1i(_programID, _maxIterationsUniformLoc, maxIterations);
}

- (NSSize)screenSizeInPixels {
    NSRect backingBounds = [self convertRectToBacking:[self bounds]];
    GLsizei backingPixelWidth  = (GLsizei)(backingBounds.size.width),
    backingPixelHeight = (GLsizei)(backingBounds.size.height);
    return NSMakeSize(backingPixelWidth, backingPixelHeight);
}

// Legacy stuff from the original software renderer.
// I packed a bunch of translations into NSRects,
// where the size is the scaling and the origin is the translation
// of the complex number graph.
//
// This is the only place this math is used. It is otherwise
// all done in the shader now.
- (void)zoomToDragRect {
    NSRect baseFractalSpace = [self baseGraphTransformationsAsRect];
    NSRect currentSpace = [self zoomedGraphTransformationsAsRect];
    
    // cancel zoom if the box is too small
    CGFloat newScale = [self zoomScale];
    if (fabs(_dragRect.size.width) > 2) {
        CGFloat dragWidth = currentSpace.size.width * fabs(_dragRect.size.width) / self.bounds.size.width;
        newScale = dragWidth / baseFractalSpace.size.width;
    }
    
    // get center of drag rect in pixel coordinates, and convert to fractal coordinates
    NSPoint dragCenterPx = NSMakePoint( _dragRect.origin.x + (_dragRect.size.width / 2.0),
                                        _dragRect.origin.y + (_dragRect.size.height / 2.0) );
    
    NSPoint dragCenter = [self convertScreenPointToFractalPoint:dragCenterPx];
    
    // Calculate new zoom translation by taking difference between this point and fractal space translation
    // and adding it to the old zoom translation.
    NSPoint translation = NSMakePoint( _zoomX + (dragCenter.x - currentSpace.origin.x),
                                       _zoomY + (dragCenter.y - currentSpace.origin.y) );

    [self setZoomScale: newScale];
    [self setZoomX: translation.x Y: translation.y];
    [self redrawFractal];
}

// used by zoomToDragRect
- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint
{
    return mandelbrot_point_for_pixel(screenPoint, [self bounds].size, [self zoomedGraphTransformationsAsRect]);
}

// used by zoomToDragRect
- (NSRect)zoomAsRect
{
    return NSMakeRect(_zoomX, _zoomY, _zoomScale, _zoomScale);
}

// used by zoomToDragRect
- (NSRect)baseGraphTransformationsAsRect {
    return NSMakeRect(_baseTranslation.x, _baseTranslation.y,
                      _baseGraphSize.width, _baseGraphSize.height);
}

// apply the current user zoom to the base translations
// used by zoomToDragRect
- (NSRect)zoomedGraphTransformationsAsRect
{
    return zoom_in_on_rect([self baseGraphTransformationsAsRect],
                           [self zoomAsRect]);
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

- (void)cleanUpOpenGL {
//    NSLog(@"cleanUpOpenGL");
    if (_programID != 0) {
        [_fractalProgram deleteShadersAndProgram];
        _programID = 0;
    }
    if (_vertexBuffer != 0) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    if (_vertexArrayID != 0) {
        glDeleteVertexArrays(1, &_vertexArrayID);
        _vertexArrayID = 0;
    }
    if (_gradientTextureID != 0) {
        glDeleteTextures(1, &_gradientTextureID);
        _gradientTextureID = 0;
    }
}

- (void)dealloc {
//    NSLog(@"dealloc");
    [self cleanUpOpenGL];
}

@end
