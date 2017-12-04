#version 410

uniform sampler1D tex;
uniform vec2 screenSize;
uniform vec2 center;
uniform float scale;
uniform int iter;

out vec4 color;

void main() {
//    vec2 pixel = vec2(gl_FragCoord.x - 0.5,
//                      gl_FragCoord.y - 0.5);
    vec2 pixel = gl_FragCoord;
    
//    CGFloat x_offset = mandelbrot_space.origin.x - (mandelbrot_space.size.width / 2);
//    CGFloat x = ((pixel.x / screen.width) * mandelbrot_space.size.width) + x_offset;
//
//    CGFloat y_offset = mandelbrot_space.origin.y - (mandelbrot_space.size.height / 2);
//    CGFloat y = pixel.y / screen.height * mandelbrot_space.size.height + y_offset;
    
    vec2 z, c;
    c.x = (pixel.x / screenSize.x) * scale - center.x - 1;
    c.y = (pixel.y / screenSize.y) * scale - center.y - 1;

    int i;
    z = c;
    for (i=0; i<iter; i++) {
        float x = (z.x * z.x - z.y * z.y) + c.x;
        float y = (z.y * z.x + z.x * z.y) + c.y;

        if ((x * x + y * y) > 4.0) break;
        z.x = x;
        z.y = y;
    }

//    color = texture(tex, (i == iter ? 0.0 : float(i)) / float(iter));
    float escapeTime = float(i) / float(iter);
    color = vec4(
                 1.0f - escapeTime, // max == 0
                 1.0f - escapeTime, // max == 0
                 0.5f,
                 1.0f
    );
}
