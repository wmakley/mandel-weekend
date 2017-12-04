//
//  ColorPalette.m
//  MandelWeekend
//
//  Created by William Makley on 3/20/15.
//  Copyright (c) 2015 William Makley. All rights reserved.
//

#import "GradientTexture.h"


static const GLsizei DEFAULT_WIDTH = 256;


@interface GradientTexture (Private)
- (void)generateTexture;
@end


@implementation GradientTexture

- (instancetype)init
{
    return [self initWithWidth:DEFAULT_WIDTH];
}

- (instancetype)initWithWidth:(GLsizei)width
{
    self = [super init];
    if (self) {
        [self setWidth:width];
    }
    return self;
}

- (void)generateTexture
{
    GLsizei width = [self width];
    GLfloat width_f = (GLfloat)width;
    NSUInteger byteLength = width * 3 * sizeof(GLfloat);
    if (!_texture) {
        _texture = [[NSMutableData alloc] initWithCapacity:byteLength];
    }
    else if (_texture.length != byteLength) {
        [_texture setLength:byteLength];
    }
    GLfloat *colors = [_texture mutableBytes];
    for (GLsizei i = 0; i < width; i += 1) {
        // Old integer-based algorithm:
        // alpha = 255
//        UInt32 color = 0x000000FF;
        // red
//        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 255.0) << 24);
        // green
//        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 100.0) << 16);
        // blue
//        color = color | ((i % 256) << 8);
        
        GLfloat red = (GLfloat)i / width_f;
        GLfloat green = (CGFloat)i / width_f / 2.5f;
        GLfloat blue = (GLfloat)(i % 256);
        
        NSUInteger pointerOffset = i * 3;
        colors[pointerOffset] = red;
        colors[pointerOffset + 1] = green;
        colors[pointerOffset + 2] = blue;
    }
}

- (void)setWidth:(GLsizei)width
{
    if (_width != width) {
        _width = width;
        [self generateTexture];
    }
}

- (GLsizei)width {
    return _width;
}

- (const void *)bytes {
    return [_texture bytes];
}

- (NSUInteger)sizeInBytes {
    return [_texture length];
}

@end
