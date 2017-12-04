#version 410

uniform sampler1D tex;
uniform dvec2 screenSize;
uniform dvec2 graphSize;
uniform dvec2 translate;
uniform double scale;
uniform int iter;

out vec4 color;

void main() {
    // get pixel coordinates as a fraction of 1.0
    dvec2 pixel;
    pixel.x = gl_FragCoord.x / screenSize.x;
    pixel.y = gl_FragCoord.y / screenSize.y;
    
    // apply scaling factor to the original graph size
    dvec2 scaledGraphSize;
    scaledGraphSize.x = graphSize.x * scale;
    scaledGraphSize.y = graphSize.y * scale;

    dvec2 z, c;
    // convert our pixel to complex coordinates, given the current graph size and translation
    c.x = pixel.x * scaledGraphSize.x - (scaledGraphSize.x / 2.0) + translate.x;
    c.y = pixel.y * scaledGraphSize.y - (scaledGraphSize.y / 2.0) + translate.y;
    
    // old code for reference
    //    CGFloat x_offset = mandelbrot_space.origin.x - (mandelbrot_space.size.width / 2);
    //    CGFloat x = ((pixel.x / screen.width) * mandelbrot_space.size.width) + x_offset;
    //
    //    CGFloat y_offset = mandelbrot_space.origin.y - (mandelbrot_space.size.height / 2);
    //    CGFloat y = pixel.y / screen.height * mandelbrot_space.size.height + y_offset;

    // mandelbrot algorithm
    int i;
    z = c;
    for (i=0; i<iter; i++) {
        double x = (z.x * z.x - z.y * z.y) + c.x;
        double y = (z.y * z.x + z.x * z.y) + c.y;

        if ((x * x + y * y) > 4.0) break;
        z.x = x;
        z.y = y;
    }

//    color = texture(tex, (i == iter ? 0.0 : float(i)) / float(iter));
    
    // texture sampling not working yet, just generate a color
    float escapeTime = float(i) / float(iter);
    color = vec4(
                 1.0 - escapeTime, // max == 0
                 1.0 - escapeTime, // max == 0
                 0.5,
                 1.0
    );
}
