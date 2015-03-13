module lix.matrix;

// This is used for the position of the exploder fuse.
// graphic.gralib.initialize() sets Matrix countdown upon loading all images.

struct XY {

    int x;
    int y;

    this(in int new_x, in int new_y)
    {
        x = new_x;
        y = new_y;
    }
}

alias XY[][] Matrix;

Matrix countdown;
