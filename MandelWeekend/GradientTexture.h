//
//  ColorPalette.h
//  MandelWeekend
//
//  Created by William Makley on 3/20/15.
//  Copyright (c) 2015 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>

@interface GradientTexture : NSObject
{
    NSMutableData *_texture;
    GLsizei _width;
}

- (instancetype)initWithWidth:(GLsizei)width;

- (GLsizei)width;
- (void)setWidth:(GLsizei)width;

- (const void *)bytes;
- (NSUInteger)sizeInBytes;

@end
