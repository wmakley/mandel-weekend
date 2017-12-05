//
//  GLMandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>
#import "GradientTexture.h"
#import "Shader.h"

@interface GLMandelbrotView : NSOpenGLView
{
    GradientTexture *_texture;
    NSRect _dragRect;
    
    NSPoint _fractalTranslation;
    
    NSPoint _baseTranslation;
    NSSize _baseGraphSize;
    
    GLuint _vertexArrayID;
    GLuint _vertexBuffer;
    GLuint _gradientTextureID;
    Shader *_vertexShader;
    Shader *_fragmentShader;
    GLuint _programID;
    
    GLint _screenSizeUniformLoc;
    GLint _translateUniformLoc;
    GLint _scaleUniformLoc;
    GLint _maxIterationsUniformLoc;
}

+ (NSInteger)defaultMaxIterations;
+ (NSSize)defaultGraphSize;
+ (NSPoint)defaultTranslation;

@property (nonatomic, assign) NSTimeInterval renderTime;

// GUI properties
@property (nonatomic, readonly) CGFloat zoomX;
- (void)setZoomX:(CGFloat)zoomX;

@property (nonatomic, readonly) CGFloat zoomY;
- (void)setZoomY:(CGFloat)zoomY;

// set both at the same time to avoid multiple redraws
- (void)setZoomX:(CGFloat)zoomX Y:(CGFloat)zoomY;

@property (nonatomic, readonly) CGFloat zoomScale;
- (void)setZoomScale:(CGFloat)zoomScale;

@property (nonatomic, readonly) NSInteger maxIterations;
- (void)setMaxIterations:(NSInteger)maxIterations;

@property (assign) BOOL isRendering;
@property (assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isLiveResizing;

// Call to re-render the fractal
- (void)redrawFractal;
// Call when the view has been resized to explicitly trigger a render
- (void)resize;

- (CGFloat)aspectRatio;

// Call before the application terminates to cleanup OpenGL resources
- (void)cleanUpOpenGL;

@end
