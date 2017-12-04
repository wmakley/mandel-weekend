//
//  GLMandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <OpenGL/gl3.h>
#import "GradientTexture.h"
#import "Shader.h"

@interface GLMandelbrotView : NSOpenGLView
{
    GradientTexture *_texture;
//    CGFloat zoomX, zoomY, zoomScale;
//    NSInteger maxIterations;
    NSRect _baseFractalSpace;
    NSRect _dragRect;
    
    GLuint _vertexArrayID;
    GLuint _vertexBuffer;
    GLuint _textureID;
    Shader *_vertexShader;
    Shader *_fragmentShader;
    GLuint _programID;
    
    GLint _screenSizeUniformLoc;
    GLint _centerUniformLoc;
    GLint _scaleUniformLoc;
    GLint _maxIterationsUniformLoc;
}

+ (NSInteger)defaultMaxIterations;

@property (assign) NSTimeInterval renderTime;
@property (assign) CGFloat zoomX;
@property (assign) CGFloat zoomY;
@property (assign) CGFloat zoomScale;
@property (readonly) NSInteger maxIterations;
@property (assign) BOOL isRendering;
@property (assign) BOOL isDragging;

// Call to re-render the fractal
- (void)redrawFractal;
// Call when the view has been resized to explicitly trigger a render
- (void)resize;

- (CGFloat)aspectRatio;
- (NSRect)zoom;

// Call before the application terminates to cleanup OpenGL resources
- (void)cleanUpOpenGL;

@end
