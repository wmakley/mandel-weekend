//
//  GLMandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 11/23/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
@class ColorPalette;

@interface GLMandelbrotView : NSOpenGLView
{
    ColorPalette *_colorPalette;
//    CGFloat zoomX, zoomY, zoomScale;
//    NSInteger maxIterations;
    NSRect _baseFractalSpace;
    NSRect _dragRect;
}

@property (assign) NSTimeInterval renderTime;
@property (assign) CGFloat zoomX;
@property (assign) CGFloat zoomY;
@property (assign) CGFloat zoomScale;
@property (assign) NSInteger maxIterations;
@property (assign) BOOL isRendering;
@property (assign) BOOL isDragging;

- (CGFloat)aspectRatio;
- (NSRect)zoom;

@end
