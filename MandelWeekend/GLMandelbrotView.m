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

+ (NSInteger)defaultMaxIterations {
    return 100;
}

+ (GLKVector2)defaultGraphSize {
    return GLKVector2Make(2.6, 2.3);
}

+ (GLKVector2)defaultTranslation {
    return GLKVector2Make(-0.75, 0.0);
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
        _zoomX = 0.0;
        _zoomY = 0.0;
        _zoomScale = 1.0;
        _maxIterations = [GLMandelbrotView defaultMaxIterations];
        _isRendering = NO;
        _texture = [[GradientTexture alloc] initWithWidth:256];
        NSLog(@"starting programID: %u", _programID);
        
        BASE_GRAPH_SIZE = [GLMandelbrotView defaultGraphSize];
        BASE_TRANSLATION = [GLMandelbrotView defaultTranslation];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // set this flag so certain messages can be ignored during rendering
//    [self setIsRendering:YES];
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
//    [self setIsRendering:NO];
}

- (void)prepareOpenGL {
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
    
    _vertexShader = [[Shader alloc] initWithFileName:@"mandelbrot" extension:@"vsh" shaderType:GL_VERTEX_SHADER];
    _fragmentShader = [[Shader alloc] initWithFileName:@"mandelbrot" extension:@"fsh" shaderType:GL_FRAGMENT_SHADER];
    
    if ( ! [_vertexShader compile] ) {
        NSLog(@"Vertex shader compilation failed");
        [self cleanUpOpenGL];
        abort();
    }
    if ( ! [_fragmentShader compile] ) {
        NSLog(@"Fragment shader compilation failed");
        [self cleanUpOpenGL];
        abort();
    }
    
    _programID = glCreateProgram();
    glAttachShader(_programID, [_vertexShader shaderID]);
    glAttachShader(_programID, [_fragmentShader shaderID]);
    glLinkProgram(_programID);
    glValidateProgram(_programID);
    
    GLint linkResult = GL_FALSE;
    GLint infoLogLength = 0;
    GLint isValid = GL_FALSE;
    glGetProgramiv(_programID, GL_LINK_STATUS, &linkResult);
    glGetProgramiv(_programID, GL_VALIDATE_STATUS, &isValid);
    glGetProgramiv(_programID, GL_INFO_LOG_LENGTH, &infoLogLength);
    
    if (infoLogLength > 0) {
        GLchar infoLogCString[infoLogLength];
        glGetProgramInfoLog(_programID, infoLogLength, NULL, &infoLogCString[0]);
        NSLog(@"Program linking log: %s", infoLogCString);
    }
    
    if (linkResult == GL_FALSE || isValid == GL_FALSE) {
        NSLog(@"linking or validation failed, link = %d, valid = %d", linkResult, isValid);
        [self cleanUpOpenGL];
        abort();
    }
    
    NSLog(@"Shader program is valid, activating");
    glUseProgram(_programID);
    
    glGenTextures(1, &_textureID);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_1D, _textureID);
//    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    [self sendTextureData];
    
    GLint texLoc = glGetUniformLocation(_programID, "tex");
    GLint graphSizeLoc = glGetUniformLocation(_programID, "graphSize");
    _screenSizeUniformLoc = glGetUniformLocation(_programID, "screenSize");
    _translateUniformLoc = glGetUniformLocation(_programID, "translate");
    _scaleUniformLoc = glGetUniformLocation(_programID, "scale");
    _maxIterationsUniformLoc = glGetUniformLocation(_programID, "iter");
//    NSLog(@"tex: %d, center: %d, scale: %d, iter: %d", texLoc, centerLoc, scaleLoc, iterLoc);

    // uniform sampler1D tex - always points to texture 0;
    glProgramUniform1i(_programID, texLoc, 0);
    // Base scaling of the graph never changes, but we need to know it
    // both here and in the shader.
    glProgramUniform2d(_programID, graphSizeLoc, BASE_GRAPH_SIZE.x, BASE_GRAPH_SIZE.y);
    [self setScreenSizeUniform:screenSize];
    [self setTranslationUniformX:_zoomX Y:_zoomY];
    [self setScaleUniform:_zoomScale];
    [self setMaxIterationsUniform:(GLint)_maxIterations];
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
    @synchronized (self) {
        if (zoomX != _zoomX) {
            _zoomX = zoomX;
            [self setTranslationUniformX:_zoomX Y:_zoomY];
        }
    }
}

- (void)setZoomY:(CGFloat)zoomY {
    @synchronized (self) {
        if (zoomY != _zoomY) {
            _zoomY = zoomY;
            [self setTranslationUniformX:_zoomX Y:_zoomY];
        }
    }
}

// Set both X and Y at the same time if both changed to avoid 2 re-draws
- (void)setZoomX:(CGFloat)zoomX Y:(CGFloat)zoomY {
    @synchronized (self) {
        BOOL changed = NO;
        if (zoomX != _zoomX) {
            _zoomX = zoomX;
            changed = YES;
        }
        if (zoomY != _zoomY) {
            _zoomY = zoomY;
            changed = YES;
        }
        if (changed) {
            [self setTranslationUniformX:_zoomX Y:_zoomY];
        }
    }
}

- (void)setZoomScale:(CGFloat)zoomScale {
    @synchronized (self) {
        if (zoomScale != _zoomScale) {
            _zoomScale = zoomScale;
            [self setScaleUniform:zoomScale];
        }
    }
}

- (void)setMaxIterations:(NSInteger)maxIterations {
    NSInteger clamped;
    if (maxIterations < 1) {
        clamped = 1;
    } else if (maxIterations > 20000) {
        clamped = 20000;
    } else {
        clamped = maxIterations;
    }
    @synchronized (self) {
        if (clamped != _maxIterations) {
            _maxIterations = clamped;
            [self setMaxIterationsUniform:(GLint)_maxIterations];
        }
    }
}


- (void)setScreenSizeUniform:(NSSize)screenSize {
    glProgramUniform2d(_programID, _screenSizeUniformLoc, screenSize.width, screenSize.height);
}

- (void)setTranslationUniformX:(GLdouble)x Y:(GLdouble)y {
    glProgramUniform2d(_programID, _translateUniformLoc, BASE_TRANSLATION.x + x, y);
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

// Called externally or internally when the view may have resized
- (void)resize {
    NSSize screenSize = [self screenSizeInPixels];
    glViewport(0, 0, screenSize.width, screenSize.height);
    [self setScreenSizeUniform:screenSize];
    [self setNeedsDisplay:YES];
}

- (void)zoomToDragRect {
    // 1. Find the center of the rectangle in complex coordinates
    // 2. No zoom for boxes of < 2 pixels, just translate and return
    // 3. Figure out the new scale, by proportion of selected screen against overall screen
    // 4. Set scale
    
    
    // TODO: track all the fractal transformations built into the shader,
    // and do the complex space transformations outside of the shader.
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
    
    // Calculate new zoom translation by taking different between this point and fractal space translation
    // and adding it to the old zoom translation.
    NSPoint translation = NSMakePoint( _zoomX + (dragCenter.x - currentSpace.origin.x),
                                       _zoomY + (dragCenter.y - currentSpace.origin.y) );

    [self setZoomScale: newScale];
    [self setZoomX: translation.x Y: translation.y];
    [self redrawFractal];
}

- (NSPoint)convertScreenPointToFractalPoint:(NSPoint)screenPoint
{
    return mandelbrot_point_for_pixel(screenPoint, [self bounds].size, [self zoomedGraphTransformationsAsRect]);
}

- (NSRect)zoomAsRect
{
    return NSMakeRect(_zoomX, _zoomY, _zoomScale, _zoomScale);
}

- (NSRect)baseGraphTransformationsAsRect {
    return NSMakeRect(BASE_TRANSLATION.x, BASE_TRANSLATION.y, BASE_GRAPH_SIZE.x, BASE_GRAPH_SIZE.y);
}

// apply the current user zoom to the base translations
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
    NSLog(@"cleanUpOpenGL");
    if (_vertexShader) {
        glDetachShader(_programID, [_vertexShader shaderID]);
        [_vertexShader deleteShader];
        _vertexShader = nil;
    }
    if (_fragmentShader) {
        glDetachShader(_programID, [_fragmentShader shaderID]);
        [_fragmentShader deleteShader];
        _fragmentShader = nil;
    }
    if (_programID != 0) {
        glDeleteProgram(_programID);
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
    if (_textureID != 0) {
        glDeleteTextures(1, &_textureID);
        _textureID = 0;
    }
}

- (void)dealloc {
    NSLog(@"dealloc");
    [self cleanUpOpenGL];
}

@end
