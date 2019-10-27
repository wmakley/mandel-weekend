//
//  GLMandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
//#import "GradientTexture.h"
//#import "ShaderProgram.h"
//#import "Shader.h"

@interface MandelbrotView : MTKView
{
//    GradientTexture *_texture;
    NSRect _dragRect;
    
    NSPoint _fractalTranslation;
    
    NSPoint _baseTranslation;
    NSSize _baseGraphSize;
    
//    GLuint _vertexArrayID;
//    GLuint _vertexBuffer;
//    GLuint _gradientTextureID;
//    ShaderProgram *_fractalProgram;
//    GLuint _programID;
//
//    GLint _screenSizeUniformLoc;
//    GLint _translateUniformLoc;
//    GLint _scaleUniformLoc;
//    GLint _maxIterationsUniformLoc;
}

+ (NSInteger)defaultMaxIterations;
+ (NSSize)defaultGraphSize;
+ (NSPoint)defaultTranslation;

@property (assign) NSTimeInterval renderTime;

// GUI properties
@property (nonatomic) CGFloat zoomX;
@property (nonatomic) CGFloat zoomY;
// set both at the same time to avoid multiple redraws
- (void)setZoomX:(CGFloat)zoomX Y:(CGFloat)zoomY;

@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) NSInteger maxIterations;

@property (assign) BOOL isRendering;
@property (assign) BOOL isDragging;
@property (nonatomic, assign) BOOL isLiveResizing;

// Call to re-render the fractal
//- (void)redrawFractal;
// Call when the view has been resized to explicitly trigger a render
//- (void)resize;

- (CGFloat)aspectRatio;
- (NSInteger)maxIterationsDuringLiveResize;

// Call before the application terminates to cleanup OpenGL resources
//- (void)cleanUpOpenGL;

@end
