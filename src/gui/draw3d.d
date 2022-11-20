module gui.draw3d;

/* These loose functions are called by GUI elements, but they are mere
 * abstractions over Allegro drawing, not dependent on any GUI element.
 * They depend on global Geometry state, therefore they're in package gui.
 * We assume that a target bitmap or torbit has been chosen.
 */

import basics.alleg5;
import graphic.color : Alcol3D;
import gui.geometry;

void draw3DFrame(
    in float xs, in float ys, in float xls, in float yls, in Alcol3D col
) {
    alias al_draw_filled_rectangle rf;
    foreach (int i; 0 .. boundary3D(xls, yls)) {
        rf(xs      +i, ys      +i, xs    +1+i, ys+yls  -i, col.d); // left*
        rf(xs    +1+i, ys      +i, xs+xls-1-i, ys    +1+i, col.d); // top
        rf(xs+xls-1-i, ys    +1+i, xs+xls  -i, ys+yls  -i, col.l); // right*
        rf(xs    +1+i, ys+yls-1-i, xs+xls-1-i, ys+yls  -i, col.l); // bottom
        // *: I've drawn 1 pixel longer in y direction to cover the
        // corner, where same-colored horizontal and vertical stripes
        // meet, and draw that corner via this longer vertical stripe.

        // Draw single pixels in the bottom-left and top-right corners
        // where unlike-colored stripes meet.
        rf(xs      +i, ys+yls-1-i, xs  +1+i, ys+yls-i, col.m);
        rf(xs+xls-1-i, ys      +i, xs+xls-i, ys  +1+i, col.m);
    }
}

void draw3DButton(
    in float xs, in float ys, in float xls, in float yls, in Alcol3D col
) {
    draw3DFrame(xs, ys, xls, yls, col.retro);
    // draw the large interior
    immutable float th = boundary3D(xls, yls);
    al_draw_filled_rectangle(xs + th, ys + th,
       xs + xls - th, ys + yls - th, col.m);
}

private int boundary3D(in float xls, in float yls)
{
    int ret = gui.thicks;
    while (ret > 0 && (ret > xls/2f || ret > yls/2f))
        --ret;
    return ret;
}
