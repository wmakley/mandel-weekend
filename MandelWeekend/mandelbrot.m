//
//  mandelbrot.c
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import "mandelbrot.h"

NSInteger mandelbrot_escape_time(NSPoint point, NSInteger max_iterations) {
    CGFloat x = 0.0,
            y = 0.0,
            xtemp;
    NSInteger i = 0;
    while ( (x*x + y*y < 2*2) && i < max_iterations) {
        xtemp = x*x - y*y + point.x;
        y = 2*x*y + point.y;
        x = xtemp;
        i += 1;
    }
    return i;
}

NSRect zoom_in_on_rect(NSRect base, NSRect zoom) {
    return NSMakeRect(base.origin.x + zoom.origin.x,
                      base.origin.y + zoom.origin.y,
                      base.size.width * zoom.size.width,
                      base.size.height * zoom.size.height);
}

// Convert point "pixel" in screen of dimensions "screen" to coordinates
// in screen of dimensions mandelbrot_space.
//
// Imagine mandelbrot_space as being a graph super-imposed on the screen,
// where screen width is equivalent to mandelbrot width, and the mandelbrot
// origin in the center of the screen.
//
// Another way to think of it: mandelbrot_space is just the size of the graph
// to draw the fractical on, and its origin is how much to translate the
// fractal.
//
// Really we are peforming a translation and a scaling on the pixel defined by a rect,
// and my own intuitive train of thoughts on what to multiply by what, when
// this should really just be matrices or NSAffineTransformations or something.
NSPoint mandelbrot_point_for_pixel(NSPoint pixel, NSSize screen, NSRect mandelbrot_space) {    
    CGFloat x_offset = mandelbrot_space.origin.x - (mandelbrot_space.size.width / 2);
    CGFloat x = ((pixel.x / screen.width) * mandelbrot_space.size.width) + x_offset;
    
    CGFloat y_offset = mandelbrot_space.origin.y - (mandelbrot_space.size.height / 2);
    CGFloat y = pixel.y / screen.height * mandelbrot_space.size.height + y_offset;
    
    return NSMakePoint(x, y);
}
