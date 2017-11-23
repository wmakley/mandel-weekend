//
//  GLMandelbrotView.h
//  MandelWeekend
//
//  Created by William Makley on 1/17/17.
//  Copyright © 2017 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

@interface GLMandelbrotView : NSOpenGLView
{
}

@property NSInteger maxIterations;

@end
