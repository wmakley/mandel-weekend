#version 410

uniform sampler1D tex;
uniform dvec2 screenSize;
uniform dvec2 center;
uniform double scale;
uniform int iter;

out vec4 color;

void main() {
    // convert pixel to proportion of 1.0
    dvec2 pixel;
    pixel.x = gl_FragCoord.x / screenSize.x;
    pixel.y = gl_FragCoord.y / screenSize.y;
    
    // The mandelbrot set is about 2.6 wide and 2.3 tall on the complex plane,
    // and extends more into the negative x, so we build in some
    // scaling and translation of the user specified
    // scale and translate.
    dvec2 fractalScale, fractalTranslate;
    
    fractalScale.x = 2.6 * scale;
    fractalScale.y = 2.3 * scale;
    
    fractalTranslate.x = -0.75 + center.x;
    fractalTranslate.y = center.y;
    
//    CGFloat x_offset = mandelbrot_space.origin.x - (mandelbrot_space.size.width / 2);
//    CGFloat x = ((pixel.x / screen.width) * mandelbrot_space.size.width) + x_offset;
//
//    CGFloat y_offset = mandelbrot_space.origin.y - (mandelbrot_space.size.height / 2);
//    CGFloat y = pixel.y / screen.height * mandelbrot_space.size.height + y_offset;

    dvec2 z, c;
    c.x = pixel.x * fractalScale.x - (fractalScale.x / 2.0) + fractalTranslate.x;
    c.y = pixel.y * fractalScale.y - (fractalScale.y / 2.0) + fractalTranslate.y;

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
    float escapeTime = float(i) / float(iter);
    color = vec4(
                 1.0 - escapeTime, // max == 0
                 1.0 - escapeTime, // max == 0
                 0.5,
                 1.0
    );
}
