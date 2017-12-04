#version 410

uniform sampler1D tex;
uniform dvec2 screenSize;
uniform dvec2 graphSize;
uniform dvec2 translate;
uniform double scale;
uniform int iter;

out vec4 color;

void main() {
    // apply scaling factor to the original graph size
    dvec2 scaledGraphSize = dvec2(graphSize.x * scale,
                                  graphSize.y * scale);

    dvec2 z, c;
    // convert our pixel to complex coordinates, given the current graph size and translation
    c.x = (gl_FragCoord.x / screenSize.x) * scaledGraphSize.x - (scaledGraphSize.x / 2.0) + translate.x;
    c.y = (gl_FragCoord.y / screenSize.y) * scaledGraphSize.y - (scaledGraphSize.y / 2.0) + translate.y;

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
