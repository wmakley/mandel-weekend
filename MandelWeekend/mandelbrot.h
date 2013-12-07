//
//  mandelbrot.h
//  MandelWeekend
//
//  Created by William Makley on 11/28/13.
//  Copyright (c) 2013 William Makley. All rights reserved.
//

#import <Foundation/Foundation.h>

NSInteger mandelbrot_escape_time(NSPoint point, NSInteger max_iterations);
NSRect zoom_in_on_rect(NSRect base, NSRect zoom);
NSPoint mandelbrot_point_for_pixel(NSPoint pixel, NSSize screenDimensions, NSRect mandelbrotSpace);
