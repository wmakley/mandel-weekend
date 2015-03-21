//
//  ColorPalette.m
//  MandelWeekend
//
//  Created by William Makley on 3/20/15.
//  Copyright (c) 2015 William Makley. All rights reserved.
//

#import "ColorPalette.h"

@interface ColorPalette (Private)
- (void)generateColorPalette;
@end

@implementation ColorPalette

- (id)init
{
    return [self initWithMaxIterations:1000];
}

- (id)initWithMaxIterations:(NSInteger)maxIterations
{
    self = [super init];
    if (self) {
        [self setMaxIterations:maxIterations];
    }
    return self;
}

- (void)generateColorPalette
{
    NSUInteger totalColors = self.maxIterations;
    NSUInteger byteLength = totalColors * sizeof(UInt32);
    if (!palette) {
        palette = [[NSMutableData alloc] initWithCapacity:byteLength];
    }
    else if (palette.length != byteLength) {
        [palette setLength:byteLength];
    }
    UInt32 *colors = [palette mutableBytes];
    for (UInt32 i = 0; i < totalColors; i += 1) {
        // alpha = 255
        UInt32 color = 0x000000FF;
        // red
        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 255.0) << 24);
        // green
        color = color | ((UInt32)((CGFloat)i / (CGFloat)totalColors * 100.0) << 16);
        // blue
        color = color | ((i % 256) << 8);
        colors[i] = color;
    }
    colors[totalColors - 1] = 0x000000FF; // black if point doesn't escape
}

- (UInt32)colorForEscapeTime:(NSInteger)escapeTime
{
    if (escapeTime > self.maxIterations) {
        escapeTime = self.maxIterations;
    }
    else if (escapeTime < 0) {
        escapeTime = 0;
    }
    
    if (!palette) {
        [self generateColorPalette];
    }
    
    UInt32 *colors = [palette mutableBytes];
    return colors[escapeTime - 1];
}

- (NSInteger)maxIterations
{
    return _maxIterations;
}

- (void)setMaxIterations:(NSInteger)maxIterations
{
    if (_maxIterations != maxIterations) {
        _maxIterations = maxIterations;
        [self generateColorPalette];
    }
}

@end