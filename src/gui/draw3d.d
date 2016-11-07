module gui.draw3d;

/* These loose functions are called by GUI elements, but they are mere
 * abstractions over Allegro drawing, not dependent on any GUI element.
 * They depend on global Geometry state, therefore they're in package gui.
 * We assume that a target bitmap or torbit has been chosen.
 */

import basics.alleg5;
import gui.geometry;

void draw3DFrame(float xs, float ys, float xls, float yls,
                 in Alcol top, in Alcol mid, in Alcol bot
) {
    alias al_draw_filled_rectangle rf;
    foreach (int i; 0 .. boundary3D(xls, yls)) {
        rf(xs      +i, ys      +i, xs    +1+i, ys+yls  -i, top); // left*
        rf(xs    +1+i, ys      +i, xs+xls-1-i, ys    +1+i, top); // top
        rf(xs+xls-1-i, ys    +1+i, xs+xls  -i, ys+yls  -i, bot); // right*
        rf(xs    +1+i, ys+yls-1-i, xs+xls-1-i, ys+yls  -i, bot); // bttom
        // *: I've drawn 1 pixel longer in y direction to cover the
        // corner, where same-colored horizontal and vertical stripes
        // meet, and draw that corner via this longer vertical stripe.

        // Draw single pixels in the bottom-left and top-right corners
        // where unlike-colored stripes meet.
        rf(xs      +i, ys+yls-1-i, xs  +1+i, ys+yls-i, mid);
        rf(xs+xls-1-i, ys      +i, xs+xls-i, ys  +1+i, mid);
    }
}

void draw3DButton(float xs, float ys, float xls, float yls,
                  in Alcol top, in Alcol mid, in Alcol bot
) {
    draw3DFrame(xs, ys, xls, yls, top, mid, bot);
    // draw the large interior
    immutable float th = boundary3D(xls, yls);
    al_draw_filled_rectangle(xs + th, ys + th,
       xs + xls - th, ys + yls - th, mid);
}

private int boundary3D(in float xls, in float yls)
{
    int ret = Geom.thicks;
    while (ret > 0 && (ret > xls/2f || ret > yls/2f))
        --ret;
    return ret;
}
