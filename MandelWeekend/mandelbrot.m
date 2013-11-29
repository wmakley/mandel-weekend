//
//  mandelbrot.c
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "mandelbrot.h"

NSInteger mandelbrot_escape_time(NSPoint point, NSInteger max_iterations) {
    float   x = 0.0f,
            y = 0.0f,
            xtemp = 0.0f;
    NSInteger i = 0;
    while ( (x*x + y*y < 2*2) && i < max_iterations) {
        xtemp = x*x - y*y + point.x;
        y = 2*x*y + point.y;
        x = xtemp;
        i += 1;
    }
    return i;
}

NSPoint mandelbrot_point_for_pixel(NSPoint pixel, NSSize dimensions) {
    CGFloat x = pixel.x / dimensions.width * 3.5f - 2.5f;
    CGFloat y = pixel.y / dimensions.height * -2.0f + 1.0f;
    return NSMakePoint(x, y);
}
