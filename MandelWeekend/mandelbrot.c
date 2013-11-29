//
//  mandelbrot.c
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#include "mandelbrot.h"

int mandelbrot_escape_time(float x0, float y0, int max_iterations) {
    float   x = 0.0f,
            y = 0.0f,
            xtemp = 0.0f;
    int i = 0;
    while ( (x*x + y*y < 2*2) && i < max_iterations) {
        xtemp = x*x - y*y + x0;
        y = 2*x*y + y0;
        x = xtemp;
        i += 1;
    }
    return i;
}