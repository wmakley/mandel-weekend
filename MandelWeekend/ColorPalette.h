//
//  ColorPalette.h
//  MandelWeekend
//
//  Created by William Makley on 3/20/15.
//  Copyright (c) 2015 William Makley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ColorPalette : NSObject
{
    NSMutableData *palette;
    NSInteger _maxIterations;
}

- (instancetype)initWithMaxIterations:(NSInteger)maxIterations;

- (NSInteger)maxIterations;
- (void)setMaxIterations:(NSInteger)maxIterations;

- (UInt32)colorForEscapeTime:(NSInteger)escapeTime;

@end